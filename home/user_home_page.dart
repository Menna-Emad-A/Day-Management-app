import 'package:flutter/material.dart';
import 'package:projectcode/home/pending_tasks.dart';
import 'package:projectcode/home/time_managment_page.dart';
import '../login_pages/lib/database_helper.dart';
import 'add_task_page.dart';
import 'ai_page.dart';
import 'completed_task.dart';
import 'deleted_tasks.dart';
import 'ongoing_tasks.dart';
import 'user_profile_page.dart';

class UserHomePage extends StatefulWidget {
  final Map<String, dynamic> user;

  const UserHomePage({Key? key, required this.user}) : super(key: key);

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  final dbHelper = DatabaseHelper();

  late Future<Map<String, dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _dataFuture = _fetchData();
    });
  }

  Future<Map<String, dynamic>> _fetchData() async {
    int userId = widget.user['UUser_ID'];
    // Modify the query to exclude deleted tasks
    List<Map<String, dynamic>> tasks = await dbHelper.getUserTasks(userId);
    tasks = tasks.where((task) => task['TStatus'] != 'Deleted').toList();

    int completedCount = await dbHelper.getTaskCountByStatus(userId, 'Completed');
    int pendingCount = await dbHelper.getTaskCountByStatus(userId, 'Pending');
    int deletedCount = await dbHelper.getTaskCountByStatus(userId, 'Deleted');
    int ongoingCount = await dbHelper.getTaskCountByStatus(userId, 'On Going');

    return {
      'tasks': tasks,
      'completedCount': completedCount,
      'pendingCount': pendingCount,
      'deletedCount': deletedCount,
      'ongoingCount': ongoingCount,
    };
  }


  @override
  Widget build(BuildContext context) {
    String username = widget.user['UUsername'] ?? 'User';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Hi, $username",
          style: TextStyle(
            color: Colors.blue.shade800,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(Icons.notifications, color: Colors.grey),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final data = snapshot.data!;
            final tasks = data['tasks'] as List<Map<String, dynamic>>;
            int completedCount = data['completedCount'];
            int pendingCount = data['pendingCount'];
            int deletedCount = data['deletedCount'];
            int ongoingCount = data['ongoingCount'];

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Let's make this day productive",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "My Task",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CompletedTask(
                                    user: widget.user,
                                    onTaskChanged: _refreshData,
                                  ),
                                ),
                              ).then((value) => _refreshData());
                            },
                            child: _buildTaskCard(
                              title: "Completed",
                              count: completedCount,
                              color: const Color(0xFF81D4FA),
                              icon: Icons.done,
                              height: 180,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PendingTasks(
                                    user: widget.user,
                                    onTaskChanged: _refreshData,
                                  ),
                                ),
                              ).then((value) => _refreshData());
                            },
                            child: _buildTaskCard(
                              title: "Pending",
                              count: pendingCount,
                              color: const Color(0xFFCE93D8),
                              icon: Icons.watch_later,
                              height: 165,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Row for Deleted & On Going
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DeletedTasks(
                                    user: widget.user,
                                  ),
                                ),
                              ).then((value) => _refreshData());
                            },
                            child: _buildTaskCard(
                              title: "Deleted",
                              count: deletedCount,
                              color: const Color(0xFFF50057),
                              icon: Icons.cancel,
                              height: 165,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OngoingTasks(
                                    user: widget.user,
                                    onTaskChanged: _refreshData,
                                  ),
                                ),
                              ).then((value) => _refreshData());
                            },
                            child: _buildTaskCard(
                              title: "On Going",
                              count: ongoingCount,
                              color: const Color(0xFF81C784),
                              icon: Icons.track_changes,
                              height: 180,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Today Task",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                       TextButton(onPressed: (){
                         Navigator.push(context, MaterialPageRoute(builder: (context) => TimeManagementPage(user: widget.user)));
                       }, child: const Text("View All", style: TextStyle(color: Colors.blue),)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    tasks.isEmpty
                        ? const Center(
                      child: Text(
                        "No Tasks",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                        : ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        final description =
                            task['TDescription'] ?? 'No description';
                        final dueDate = task['TDueDate'] ?? '';
                        final tags = task['TTags'] ?? 'No tags';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              leading: const Icon(
                                Icons.linear_scale,
                                color: Colors.blue,
                              ),
                              title: Text(
                                description,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                "$dueDate\n$tags",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              trailing: PopupMenuButton(
                                itemBuilder: (context) {
                                  return [
                                    const PopupMenuItem(
                                      value: "update",
                                      child: Text("Update"),
                                    ),
                                    const PopupMenuItem(
                                      value: "delete",
                                      child: Text("Delete"),
                                    ),
                                  ];
                                },
                                onSelected: (value) async {
                                  if (value == "update") {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AddTaskPage(
                                          user: widget.user,
                                          existingTask: task,
                                        ),
                                      ),
                                    );
                                    _refreshData();
                                  } else if (value == "delete") {
                                    await dbHelper.updateTask(
                                      task['TTask_ID'],
                                      {'TStatus': 'Deleted'},
                                    );
                                    _refreshData();
                                  }
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.home, color: Colors.blue, size: 30),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.task, color: Colors.blue.shade900, size: 30),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (ctx) => TimeManagementPage(user: widget.user),
                ));
              },
            ),
            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddTaskPage(user: widget.user),
                  ),
                );
                _refreshData();
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.blue, size: 30),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.bar_chart,
                color: Colors.blue.shade900,
                size: 30,
              ),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (ctx) => AiPage(user: widget.user),
                ));
              },
            ),
            IconButton(
              icon: Icon(
                Icons.apps,
                color: Colors.blue.shade900,
                size: 30,
              ),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (ctx) => UserProfilePage(user: widget.user),
                ));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
    required double height,
  }) {
    return SizedBox(
      height: height,
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        color: color,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 55, color: Colors.white),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                "$count Task${count == 1 ? '' : 's'}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}