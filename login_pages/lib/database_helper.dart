import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'app_database.db');
    return await openDatabase(
      path,
      version: 7,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create the Users table
    await db.execute('''
      CREATE TABLE Users (
          UUser_ID INTEGER PRIMARY KEY AUTOINCREMENT,
          UUsername TEXT NOT NULL,
          UEmail TEXT UNIQUE NOT NULL,
          UPassword TEXT NOT NULL,
          UType TEXT NOT NULL
      );
    ''');

    // Create the Tasks table
    await db.execute('''
    CREATE TABLE Tasks (
        TTask_ID INTEGER PRIMARY KEY AUTOINCREMENT,
        TDescription TEXT NOT NULL,
        TDueDate TEXT,
        TPriority INTEGER,
        TStatus TEXT,
        TUser_ID INTEGER,
        TType TEXT,
        TTags TEXT,
        TStartTime TEXT,
        TEndTime TEXT,
        FOREIGN KEY (TUser_ID) REFERENCES Users(UUser_ID)
    );
  ''');

    await db.execute('''
      CREATE TABLE Notifications (
          NID INTEGER PRIMARY KEY AUTOINCREMENT,
          NUser_ID INTEGER,
          NMessage TEXT,
          NType TEXT,  -- Type of notification (e.g., "completed", "pending", etc.)
          NStatus TEXT,  -- Status (e.g., "read", "unread")
          NDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (NUser_ID) REFERENCES Users(UUser_ID)
      );
    ''');

    // Create the Tags table
    await db.execute('''
    CREATE TABLE Tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        color INTEGER NOT NULL
    );
  ''');

    // Create the ParentStudent table
    await db.execute('''
    CREATE TABLE ParentStudent (
        Parent_ID INTEGER NOT NULL,
        Student_ID INTEGER NOT NULL,
        PRIMARY KEY (Parent_ID, Student_ID),
        FOREIGN KEY (Parent_ID) REFERENCES Users(UUser_ID),
        FOREIGN KEY (Student_ID) REFERENCES Users(UUser_ID)
    );
  ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {

    if (oldVersion < 7) {
      final tableInfo = await db.rawQuery('PRAGMA table_info(Tasks)');
      final columnExists = tableInfo.any((column) => column['name'] == 'TStartTime');

      if (!columnExists) {
        await db.execute('ALTER TABLE Tasks ADD COLUMN TStartTime TEXT');
      }
    }
    if (oldVersion < 7) {
      final tableInfo = await db.rawQuery('PRAGMA table_info(Tasks)');
      final columnExists = tableInfo.any((column) => column['name'] == 'TEndTime');

      if (!columnExists) {
        await db.execute('ALTER TABLE Tasks ADD COLUMN TEndTime TEXT');
      }
    }
    if (oldVersion < 7) {
      await db.execute('''
      CREATE TABLE IF NOT EXISTS ParentStudent (
          Parent_ID INTEGER NOT NULL,
          Student_ID INTEGER NOT NULL,
          PRIMARY KEY (Parent_ID, Student_ID),
          FOREIGN KEY (Parent_ID) REFERENCES Users(UUser_ID),
          FOREIGN KEY (Student_ID) REFERENCES Users(UUser_ID)
      );
    ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS Tags (
          TagID INTEGER PRIMARY KEY AUTOINCREMENT,
          TagName TEXT NOT NULL UNIQUE,
          TagColor INTEGER NOT NULL
        );
      ''');
      await db.execute('''
        ALTER TABLE Tasks ADD COLUMN TStartTime TEXT;
      ''');
      await db.execute('''
        ALTER TABLE Tasks ADD COLUMN TEndTime TEXT;
      ''');
      await db.execute('''
      CREATE TABLE IF NOT EXISTS Tags (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT UNIQUE NOT NULL,
          color INTEGER NOT NULL
      );
    ''');
      await db.execute('''
        CREATE TABLE Notifications (
            NID INTEGER PRIMARY KEY AUTOINCREMENT,
            NUser_ID INTEGER,
            NMessage TEXT,
            NType TEXT,  -- Type of notification
            NStatus TEXT,  -- Status (read/unread)
            NDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (NUser_ID) REFERENCES Users(UUser_ID)
        );
      ''');
    }
  }
  // -------------------------
  // User Methods
  // -------------------------

  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.insert('Users', user);
  }

  Future<Map<String, dynamic>?> getUser(String email, String password) async {
    final db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'Users',
      where: 'UEmail = ? AND UPassword = ?',
      whereArgs: [email, password],
    );
    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }


  Future<int> updateUserPassword(String email, String newPassword) async {
    final db = await database;
    return await db.update(
      'Users',
      {'UPassword': newPassword},
      where: 'UEmail = ?',
      whereArgs: [email],
    );
  }

  Future<int> deleteUser(int userId) async {
    final db = await database;
    await db.delete(
      'Tasks',
      where: 'TUser_ID = ?',
      whereArgs: [userId],
    );
    return await db.delete(
      'Users',
      where: 'UUser_ID = ?',
      whereArgs: [userId],
    );
  }

  // -------------------------
  // Task Methods
  // -------------------------

  Future<void> linkParentToStudent(int parentId, int studentId) async {
    final db = await database;
    await db.insert(
      'ParentStudent',
      {'Parent_ID': parentId, 'Student_ID': studentId},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }
  Future<List<Map<String, dynamic>>> getLinkedStudents(int parentId) async {
    final db = await database;
    final results = await db.rawQuery('''
    SELECT U.*
    FROM Users U
    JOIN ParentStudent PS ON U.UUser_ID = PS.Student_ID
    WHERE PS.Parent_ID = ?
  ''', [parentId]);
    return results;
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final results = await db.query(
      'Users',
      where: 'UEmail = ?',
      whereArgs: [email],
    );
    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  Future<void> unlinkParentFromStudent(int parentId, int studentId) async {
    final db = await database;
    await db.delete(
      'ParentStudent',
      where: 'Parent_ID = ? AND Student_ID = ?',
      whereArgs: [parentId, studentId],
    );
  }
  Future<List<Map<String, dynamic>>> getTasksForStudents(List<int> studentIds) async {
    if (studentIds.isEmpty) return [];
    final db = await database;
    final ids = studentIds.join(', ');
    return await db.rawQuery('SELECT * FROM Tasks WHERE TUser_ID IN ($ids)');
  }

  Future<int> insertTask(Map<String, dynamic> task) async {
    final db = await database;
    int taskId = await db.insert('Tasks', task);

    // Trigger notification based on task status
    if (task['TStatus'] == 'Completed') {
      await insertNotification({
        'NUser_ID': task['TUser_ID'],
        'NMessage': 'Task "${task['TDescription']}" has been completed.',
        'NType': 'completed',
        'NStatus': 'unread',
      });
    } else if (task['TStatus'] == 'Pending') {
      await insertNotification({
        'NUser_ID': task['TUser_ID'],
        'NMessage': 'Task "${task['TDescription']}" is pending.',
        'NType': 'pending',
        'NStatus': 'unread',
      });
    }

    return taskId;
  }

  Future<List<Map<String, dynamic>>> getUserTasks(int userId) async {
    final db = await database;
    return await db.query(
      'Tasks',
      where: 'TUser_ID = ?',
      whereArgs: [userId],
      orderBy: 'TTask_ID DESC',
    );
  }

  Future<int> getTaskCountByStatus(int userId, String status) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM Tasks WHERE TUser_ID = ? AND TStatus = ?',
      [userId, status],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  Future<int> updateTask(int taskId, Map<String, dynamic> updatedFields) async {
    final db = await database;
    return await db.update(
      'Tasks',
      updatedFields,
      where: 'TTask_ID = ?',
      whereArgs: [taskId],
    );
  }

  Future<int> deleteTask(int taskId) async {
    final db = await database;
    return await db.delete(
      'Tasks',
      where: 'TTask_ID = ?',
      whereArgs: [taskId],
    );
  }

  Future<List<Map<String, dynamic>>> getTasksByCategory(int userId, String tag, [String searchQuery = '']) async {
    final db = await database;
    final whereArgs = searchQuery.isEmpty
        ? [userId, tag]
        : [userId, tag, '%$searchQuery%'];
    final whereClause = searchQuery.isEmpty
        ? 'TUser_ID = ? AND TTags = ?'
        : 'TUser_ID = ? AND TTags = ? AND TDescription LIKE ?';

    return await db.query(
      'Tasks',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'TTask_ID DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getTasksByType(int userId, String type) async {
    final db = await database;
    return await db.query(
      'Tasks',
      where: 'TUser_ID = ? AND TType = ?',
      whereArgs: [userId, type],
      orderBy: 'TTask_ID DESC',
    );
  }

  Future<void> debugDatabase() async {
    final db = await database;
    final allTasks = await db.query('Tasks');
    for (var task in allTasks) {
      print(task);
    }
  }

  Future<int> markTaskAsDeleted(int taskId) async {
    final db = await database;
    return await db.update(
      'Tasks',
      {'TStatus': 'Deleted'},
      where: 'TTask_ID = ?',
      whereArgs: [taskId],
    );
  }

  // -------------------------
  // Tag Methods
  // -------------------------

  Future<List<Map<String, dynamic>>> getAllTags() async {
    final db = await database;
    final tags = await db.query('Tags');
    return tags.map((tag) {
      return {
        'name': tag['TagName'] as String, // Explicit casting
        'color': Color(tag['TagColor'] as int), // Explicit casting
      };
    }).toList();
  }

  Future<void> saveNewTag(String name, int color) async {
    final db = await database;
    await db.insert(
      'Tags',
      {'name': name, 'color': color},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }


  Future<int> addTagToTask(int taskId, String tag) async {
    final db = await database;

    final task = await db.query(
      'Tasks',
      where: 'TTask_ID = ?',
      whereArgs: [taskId],
      limit: 1,
    );

    if (task.isNotEmpty) {
      String currentTags = task.first['TTags'] as String? ?? '';
      List<String> tags = currentTags.split(',').map((t) => t.trim()).toList();
      if (!tags.contains(tag)) {
        tags.add(tag);
        String updatedTags = tags.join(', ');

        return await db.update(
          'Tasks',
          {'TTags': updatedTags},
          where: 'TTask_ID = ?',
          whereArgs: [taskId],
        );
      }
    }
    return 0;
  }
  Future<int> getUserCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM Users');
    return result.first['count'] as int;
  }
  Future<void> sendUserCountToServer() async {
    final dbHelper = DatabaseHelper();
    final userCount = await dbHelper.getUserCount();
    final url = Uri.parse('http://192.168.99.204:5000/save_data'); // Backend server URL

    try {
      final response = await http.post(
        url,
        body: {'userCount': userCount.toString()},
      );
      if (response.statusCode == 200) {
        print('User count sent successfully!');
      } else {
        print('Failed to send user count: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending user count: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getOverdueTasks(int userId) async {
    final db = await database;
    final today = DateTime.now().toIso8601String();
    return await db.query(
      'Tasks',
      where: 'TUser_ID = ? AND TDueDate < ? AND TStatus != ?',
      whereArgs: [userId, today, 'Completed'],
      orderBy: 'TDueDate ASC',
    );
  }
  Future<double> getCompletedTaskPercentage(int userId) async {
    final db = await database;
    final totalTasks = await db.rawQuery(
      'SELECT COUNT(*) as total FROM Tasks WHERE TUser_ID = ?',
      [userId],
    );
    final completedTasks = await db.rawQuery(
      'SELECT COUNT(*) as completed FROM Tasks WHERE TUser_ID = ? AND TStatus = ?',
      [userId, 'Completed'],
    );

    if ((totalTasks.first['total'] as int) == 0) return 0.0;
    return (completedTasks.first['completed'] as int) / (totalTasks.first['total'] as int) * 100;
  }
  Future<int> insertNotification(Map<String, dynamic> notification) async {
    final db = await database;
    return await db.insert('Notifications', notification);
  }

  // Get unread notifications for a specific user
  Future<List<Map<String, dynamic>>> getUnreadNotifications(int userId) async {
    final db = await database;
    return await db.query(
      'Notifications',
      where: 'NUser_ID = ? AND NStatus = ?',
      whereArgs: [userId, 'unread'],
      orderBy: 'NDate DESC',
    );
  }

  // Mark notification as read
  Future<int> markNotificationAsRead(int notificationId) async {
    final db = await database;
    return await db.update(
      'Notifications',
      {'NStatus': 'read'},
      where: 'NID = ?',
      whereArgs: [notificationId],
    );
  }
  Future<int> getNotificationsCount(int userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM Notifications WHERE NUser_ID = ? AND NStatus = ?',
      [userId, 'unread'],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
  Future<int> deleteNotification(int notificationId) async {
    final db = await database;
    return await db.delete(
      'Notifications',
      where: 'NID = ?',
      whereArgs: [notificationId],);}

}
