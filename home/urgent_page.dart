import 'package:flutter/material.dart';
import '../login_pages/lib/database_helper.dart';
import 'add_task_page.dart';

class UrgentPage extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onTaskChanged; // Callback to notify changes

  const UrgentPage({
    Key? key,
    required this.user,
    required this.onTaskChanged,
  }) : super(key: key);

  @override
  State<UrgentPage> createState() => _UrgentPageState();
}

class _UrgentPageState extends State<UrgentPage> {
  final dbHelper = DatabaseHelper();
  late Future<List<Map<String, dynamic>>> _urgentTasksFuture;

  @override
  void initState() {
    super.initState();
    _loadUrgentTasks();
  }

  void _loadUrgentTasks() {
    setState(() {
      _urgentTasksFuture = _fetchUrgentTasks();
    });
  }

  Future<List<Map<String, dynamic>>> _fetchUrgentTasks() async {
    int userId = widget.user['UUser_ID'];
    return await dbHelper.getTasksByCategory(userId, 'Urgent');
  }

  String getMonthYear(String dateString) {
    final parts = dateString.split(' ');
    if (parts.length >= 3) {
      return "${parts[1]} ${parts[2]}";
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
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Urgent Tasks',
          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
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
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _urgentTasksFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  } else {
                    final tasks = snapshot.data ?? [];
                    if (tasks.isEmpty) {
                      return const Center(
                        child: Text(
                          'No Urgent Tasks',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
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
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TaskCard(
                              task: task,
                              onRefresh: _loadUrgentTasks,
                              onTaskChanged: widget.onTaskChanged,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTaskPage(user: widget.user),
            ),
          ).then((_) {
            _loadUrgentTasks(); // Refresh urgent tasks
            widget.onTaskChanged(); // Notify home page
          });
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final Map<String, dynamic> task;
  final VoidCallback onRefresh;
  final VoidCallback onTaskChanged;

  const TaskCard({
    Key? key,
    required this.task,
    required this.onRefresh,
    required this.onTaskChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final description = task['TDescription'] ?? 'No Description';
    final dueDate = task['TDueDate'] ?? 'No Date';
    final startTime = task['TStartTime'] ?? 'No Start Time';
    final endTime = task['TEndTime'] ?? 'No End Time';
    final tag = task['TTags'] ?? 'No Tag';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.pink.shade50,
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
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.pink.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.pink,
                  ),
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
                onTaskChanged();
              } else if (value == 'Delete') {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Move to Trash'),
                    content: const Text('Are you sure you want to move this task to Trash?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          final dbHelper = DatabaseHelper();
                          await dbHelper.markTaskAsDeleted(task['TTask_ID']);
                          onRefresh(); // Refresh urgent tasks
                          onTaskChanged(); // Notify home page
                        },
                        child: const Text('Confirm'),
                      ),
                    ],
                  ),
                );
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
