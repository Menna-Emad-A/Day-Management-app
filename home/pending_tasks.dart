import 'package:flutter/material.dart';
import '../login_pages/lib/database_helper.dart';
import 'add_task_page.dart';

class PendingTasks extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onTaskChanged;

  const PendingTasks({
    Key? key,
    required this.user,
    required this.onTaskChanged,
  }) : super(key: key);

  @override
  State<PendingTasks> createState() => _PendingTasksState();
}

class _PendingTasksState extends State<PendingTasks> {
  final dbHelper = DatabaseHelper();
  late Future<List<Map<String, dynamic>>> _pendingTasksFuture;

  @override
  void initState() {
    super.initState();
    _loadPendingTasks();
  }

  void _loadPendingTasks() {
    setState(() {
      _pendingTasksFuture = _fetchPendingTasks();
    });
  }

  Future<List<Map<String, dynamic>>> _fetchPendingTasks() async {
    int userId = widget.user['UUser_ID'];
    List<Map<String, dynamic>> allTasks = await dbHelper.getUserTasks(userId);
    // Filter tasks for status = "Pending"
    return allTasks.where((task) => task['TStatus'] == 'Pending').toList();
  }

  String getMonthYear(String dateString) {
    final parts = dateString.split(' ');
    if (parts.length >= 3) {
      return "${parts[1]} ${parts[2]}"; // e.g., "August 2024"
    }
    return "Unknown Date";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.blue[900]),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Pending Tasks',
          style: TextStyle(
            color: Colors.blue[900],
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  hintText: 'Search for tasks',
                  hintStyle: TextStyle(color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _pendingTasksFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else {
                    final tasks = snapshot.data ?? [];
                    if (tasks.isEmpty) {
                      return const Center(
                        child: Text(
                          'No Pending Tasks',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        final dueDate = task['TDueDate'] ?? '';
                        final monthYear = getMonthYear(dueDate);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              monthYear,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TaskCard(
                              task: task,
                              onRefresh: _loadPendingTasks,
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final Map<String, dynamic> task;
  final VoidCallback onRefresh;

  const TaskCard({
    Key? key,
    required this.task,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final description = task['TDescription'] ?? 'No Description';
    final startTime = task['TStartTime'] ?? 'No Start Time';
    final endTime = task['TEndTime'] ?? 'No End Time';
    final tag = task['TTags'] ?? 'No Tag';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                description,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$startTime - $endTime',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  tag,
                  style: TextStyle(fontSize: 12, color: Colors.purple[200]),
                ),
              ),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            onSelected: (value) async {
              if (value == 'Update') {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddTaskPage(
                      user: {'UUser_ID': task['TUser_ID']},
                      existingTask: task,
                    ),
                  ),
                );
                onRefresh();
              } else if (value == 'Delete') {
                final dbHelper = DatabaseHelper();
                await dbHelper.updateTask(
                  task['TTask_ID'],
                  {'TStatus': 'Deleted'}, // Soft delete by updating the status
                );
                onRefresh();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'Update',
                child: Row(
                  children: [
                    Icon(Icons.update, color: Colors.blue),
                    SizedBox(width: 10),
                    Text('Update'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'Delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Delete'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
