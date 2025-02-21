import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:projectcode/home/user_home_page.dart';
import 'package:projectcode/home/user_profile_page.dart';

import '../login_pages/lib/database_helper.dart';
import 'add_task_page.dart';
import 'ai_page.dart';

class TimeManagementPage extends StatefulWidget {
  final Map<String, dynamic> user;
  final bool isParentView; // Flag to indicate if the parent is viewing the tasks

  const TimeManagementPage({
    Key? key,
    required this.user,
    this.isParentView = false, // Defaults to false for students
  }) : super(key: key);

  @override
  _TimeManagementPageState createState() => _TimeManagementPageState();
}

class _TimeManagementPageState extends State<TimeManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';
  final dbHelper = DatabaseHelper();
  late Future<List<Map<String, dynamic>>> _tasksFuture;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() {
    _tasksFuture = _fetchTasks();
  }

  Future<List<Map<String, dynamic>>> _fetchTasks() async {
    int userId = widget.user['UUser_ID'];
    return await dbHelper.getUserTasks(userId);
  }

  List<Map<String, dynamic>> _filterTasks(List<Map<String, dynamic>> tasks) {
    return tasks.where((task) {
      return task['TDescription']
          .toString()
          .toLowerCase()
          .contains(_searchText.toLowerCase()) ||
          task['TTags']
              .toString()
              .toLowerCase()
              .contains(_searchText.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80.0),
        child: Padding(
          padding: const EdgeInsets.only(top: 20.0),
          child: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                ),
                onChanged: (text) {
                  setState(() {
                    _searchText = text;
                  });
                },
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          const CalendarSection(),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _tasksFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text("Error: ${snapshot.error}"),
                  );
                } else {
                  final tasks = snapshot.data ?? [];
                  final filtered = _filterTasks(tasks);

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text(
                        "No tasks match your search.",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final task = filtered[index];
                      return TaskCard(
                        time: task['TStartTime'] ?? 'No Start Time',
                        task: task['TDescription'] ?? 'No Description',
                        location: task['TTags'] ?? 'No Location',
                        duration:
                        "${task['TStartTime'] ?? 'No Time'} - ${task['TEndTime'] ?? 'No Time'}",
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.isParentView
          ? null // Hide navigation bar for parent view
          : Container(
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
              icon: Icon(Icons.home, color: Colors.blue.shade900, size: 30),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (ctx) => UserHomePage(user: widget.user),
                ));
              },
            ),
            IconButton(
              icon: Icon(Icons.task, color: Colors.blue, size: 30),
              onPressed: () {},
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddTaskPage(user: widget.user),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add, color: Colors.blue.shade900, size: 30),
              ),
            ),
            IconButton(
              icon: Icon(Icons.bar_chart, color: Colors.blue.shade900, size: 30),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (ctx) => AiPage(user: widget.user),
                ));
              },
            ),
            IconButton(
              icon: Icon(Icons.apps, color: Colors.blue.shade900, size: 30),
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
}

class CalendarSection extends StatelessWidget {
  const CalendarSection({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayIndex = now.weekday - 1;
    final dayOfMonth = now.day;
    final month = DateFormat('MMMM').format(now);
    final year = now.year;

    final daysOfWeek = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Task',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              Text(
                '$month $year',
                style: const TextStyle(color: Colors.blue),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(daysOfWeek.length, (index) {
              final isToday = index == todayIndex;

              return Column(
                children: [
                  Text(
                    daysOfWeek[index],
                    style: TextStyle(
                      color: isToday ? Colors.blue : Colors.grey,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  isToday
                      ? Container(
                    padding: const EdgeInsets.all(6.0),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      dayOfMonth.toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  )
                      : Text(
                    (dayOfMonth + (index - todayIndex)).toString(),
                    style: const TextStyle(color: Colors.black),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 16.0),
          const Text(
            'Today',
            style: TextStyle(
                fontSize: 25, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          const Divider(),
        ],
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final String time;
  final String task;
  final String location;
  final String duration;

  const TaskCard({
    super.key,
    required this.time,
    required this.task,
    required this.location,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              time,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          location,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        Text(
                          duration,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16.0),
      ],
    );
  }
}
