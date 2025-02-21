import 'package:flutter/material.dart';
import '../login_pages/lib/database_helper.dart';
import 'add_task_page.dart';

class DeletedTasks extends StatefulWidget {
  final Map<String, dynamic> user;
  const DeletedTasks({Key? key, required this.user}) : super(key: key);

  @override
  State<DeletedTasks> createState() => _DeletedTasksState();
}

class _DeletedTasksState extends State<DeletedTasks> {
  final dbHelper = DatabaseHelper();
  late Future<List<Map<String, dynamic>>> _deletedTasksFuture;

  @override
  void initState() {
    super.initState();
    _loadDeletedTasks();
  }

  void _loadDeletedTasks() {
    setState(() {
      _deletedTasksFuture = _fetchDeletedTasks();
    });
  }

  Future<List<Map<String, dynamic>>> _fetchDeletedTasks() async {
    int userId = widget.user['UUser_ID'];
    List<Map<String, dynamic>> allTasks = await dbHelper.getUserTasks(userId);
    return allTasks.where((task) => task['TStatus'] == 'Deleted').toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.blue[900]),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Deleted Tasks',
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
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _deletedTasksFuture,
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
                          'No Deleted Tasks',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        final dueDate = task['TDueDate'] ?? 'No Date';
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dueDate,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TaskCard(
                              task: task,
                              onRefresh: _loadDeletedTasks,
                              user: widget.user,
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
  final Map<String, dynamic> user;

  const TaskCard({
    Key? key,
    required this.task,
    required this.onRefresh,
    required this.user,
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
        color: Colors.red[50],
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[400],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$startTime - $endTime',
                style: TextStyle(fontSize: 14, color: Colors.red[400]),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  tag,
                  style: TextStyle(fontSize: 12, color: Colors.red[200]),
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
                      user: user,
                      existingTask: task,
                    ),
                  ),
                );
                onRefresh();
              } else if (value == 'Delete') {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Task Permanently'),
                    content: const Text('Are you sure you want to delete this task?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          final dbHelper = DatabaseHelper();
                          await dbHelper.deleteTask(task['TTask_ID']);
                          onRefresh();
                        },
                        child: const Text('Confirm'),
                      ),
                    ],
                  ),
                );
              }
            },
            itemBuilder: (context) => <PopupMenuEntry<String>>[
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
