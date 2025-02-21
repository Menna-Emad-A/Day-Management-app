import 'package:flutter/material.dart';
import 'package:projectcode/home/personal_page.dart';
import 'package:projectcode/home/private_page.dart';
import 'package:projectcode/home/time_managment_page.dart';
import 'package:projectcode/home/urgent_page.dart';
import 'package:projectcode/home/user_home_page.dart';
import '../login_pages/user_login_page.dart';
import '../login_pages/lib/database_helper.dart';
import 'Secret_Page.dart';
import 'add_task_page.dart';
import 'ai_page.dart';
import 'office_page.dart';
import 'user_settings_page.dart';

class UserProfilePage extends StatefulWidget {
  final Map<String, dynamic> user;

  const UserProfilePage({Key? key, required this.user}) : super(key: key);

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final dbHelper = DatabaseHelper();
  late Future<Map<String, int>> _taskCountsFuture;

  @override
  void initState() {
    super.initState();
    _refreshTaskCounts();
  }

  void _refreshTaskCounts() {
    setState(() {
      _taskCountsFuture = _fetchTaskCounts();
    });
  }

  Future<Map<String, int>> _fetchTaskCounts() async {
    int userId = widget.user['UUser_ID'];
    final allTasks = await dbHelper.getUserTasks(userId);

    final Map<String, int> categoryCounts = {
      'Personal': 0,
      'Private': 0,
      'Secret': 0,
      'Office': 0,
      'Urgent': 0,
    };

    for (var task in allTasks) {
      final category = task['TType'] ?? 'Personal'; // Adjusted to use TType
      if (categoryCounts.containsKey(category)) {
        categoryCounts[category] = categoryCounts[category]! + 1;
      }
    }

    return categoryCounts;
  }

  Widget buildCategoryTile(String title, int tasks, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$tasks Task${tasks > 1 ? 's' : ''}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PopupMenuButton(
                    itemBuilder: (context) {
                      return [
                        const PopupMenuItem(
                          value: "settings",
                          child: Text("Settings"),
                        ),
                        const PopupMenuItem(
                          value: "Logout",
                          child: Text("Logout"),
                        ),
                      ];
                    },
                    onSelected: (value) async {
                      if (value == "settings") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserSettingsPage(user: widget.user),
                          ),
                        );
                      } else if (value == "Logout") {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Icon(Icons.logout),
                              content: const Text(
                                'Are you sure you want to logout?',
                                style: TextStyle(fontSize: 16),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => user_login_page()),
                                          (route) => false,
                                    );
                                  },
                                  child: const Text('Logout'),
                                ),
                              ],
                            );
                          },
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                widget.user['UUsername'] ?? 'User',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                widget.user['UEmail'] ?? 'user@example.com',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: FutureBuilder<Map<String, int>>(
                  future: _taskCountsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    } else {
                      final taskCounts = snapshot.data ?? {};
                      return GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 25,
                        mainAxisSpacing: 8,
                        children: [
                          buildCategoryTile(
                            'Personal',
                            taskCounts['Personal'] ?? 0,
                            Icons.person,
                            Colors.pink,
                                () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PersonalTaskPage(user: widget.user, onTaskChanged: () {  },),
                                ),
                              ).then((_) => _refreshTaskCounts());
                            },
                          ),
                          buildCategoryTile(
                            'Private',
                            taskCounts['Private'] ?? 0,
                            Icons.privacy_tip,
                            Colors.green,
                                () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PrivatePage(user: widget.user, onTaskChanged: () {  },),
                                ),
                              ).then((_) => _refreshTaskCounts());
                            },
                          ),
                          buildCategoryTile(
                            'Secret',
                            taskCounts['Secret'] ?? 0,
                            Icons.lock,
                            Colors.purple,
                                () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      SecretPage(user: widget.user, onTaskChanged: () {  },),
                                ),
                              ).then((_) => _refreshTaskCounts());
                            },
                          ),
                          buildCategoryTile(
                            'Office',
                            taskCounts['Office'] ?? 0,
                            Icons.work,
                            Colors.blue,
                                () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      OfficePage(user: widget.user, onTaskChanged: _refreshTaskCounts),
                                ),
                              ).then((_) => _refreshTaskCounts());
                            },
                          ),
                          buildCategoryTile(
                            'Urgent',
                            taskCounts['Urgent'] ?? 0,
                            Icons.warning,
                            Colors.red,
                                () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      UrgentPage(user: widget.user, onTaskChanged: () {  },),
                                ),
                              ).then((_) => _refreshTaskCounts());
                            },
                          ),
                        ],
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
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
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (ctx) => UserHomePage(user: widget.user),
                ));
              },
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddTaskPage(user: widget.user),
                  ),
                ).then((_) => _refreshTaskCounts());
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
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
              icon: Icon(Icons.apps, color: Colors.blue, size: 30),
              onPressed: () {
                // Placeholder for additional features
              },
            ),
          ],
        ),
      ),
    );
  }
}
