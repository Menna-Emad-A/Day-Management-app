import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:projectcode/home/time_managment_page.dart';
import 'package:projectcode/home/user_profile_page.dart';

// Import your DB helper to fetch tasks
import '../login_pages/lib/database_helper.dart';

// Import your other pages for navigation
import 'user_home_page.dart';
import 'pending_tasks.dart';
import 'completed_task.dart';
import 'ongoing_tasks.dart';
import 'deleted_tasks.dart';
import 'add_task_page.dart';

class AiPage extends StatefulWidget {
  final Map<String, dynamic> user;

  const AiPage({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<AiPage> createState() => _AiPageState();
}

// Model to hold each tag's counts
class TagCount {
  final String tag;
  final int completedCount;
  final int notCompletedCount;

  TagCount({
    required this.tag,
    required this.completedCount,
    required this.notCompletedCount,
  });
}

class _AiPageState extends State<AiPage> {
  final dbHelper = DatabaseHelper();
  late Future<List<TagCount>> _tagCountsFuture;

  // Replace with your secure API key handling
  final String _apiKey = '';

  @override
  void initState() {
    super.initState();
    _tagCountsFuture = _fetchTagCounts();
  }

  Future<List<TagCount>> _fetchTagCounts() async {
    int userId = widget.user['UUser_ID'];
    final allTasks = await dbHelper.getUserTasks(userId);

    if (allTasks.isEmpty) {
      return [];
    }

    final Map<String, Map<String, int>> tagMap = {};

    for (var task in allTasks) {
      String tag = task['TTags'] ?? 'NoTag';
      String status = task['TStatus'] ?? 'Pending';
      tagMap.putIfAbsent(tag, () => {'completed': 0, 'notCompleted': 0});

      if (status == 'Completed') {
        tagMap[tag]!['completed'] = tagMap[tag]!['completed']! + 1;
      } else {
        tagMap[tag]!['notCompleted'] = tagMap[tag]!['notCompleted']! + 1;
      }
    }

    final List<TagCount> listOfTagCounts = [];
    tagMap.forEach((key, value) {
      listOfTagCounts.add(
        TagCount(
          tag: key,
          completedCount: value['completed'] ?? 0,
          notCompletedCount: value['notCompleted'] ?? 0,
        ),
      );
    });

    return listOfTagCounts;
  }

  void _showTipSelectionDialog(List<TagCount> tagCounts) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Choose AI Model for Tip"),
        content: const Text("Do you want a tip from ChatGPT or the system AI model?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _getChatGptTip(tagCounts);
            },
            child: const Text("ChatGPT"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _getSystemAiTip(tagCounts);
            },
            child: const Text("System AI"),
          ),
        ],
      ),
    );
  }

  Future<String> _getChatGptTipFromApi(List<TagCount> tagCounts) async {
    final apiUrl = 'https://api.openai.com/v1/chat/completions';

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: json.encode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {'role': 'system', 'content': 'You are an assistant.'},
          {
            'role': 'user',
            'content': 'Provide a tip based on these task counts: $tagCounts'
          }
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('Error: ${response.body}');
    }
  }

  void _getChatGptTip(List<TagCount> tagCounts) async {
    try {
      String tip = await _getChatGptTipFromApi(tagCounts);
      _showDialog(tip);
    } catch (e) {
      _showDialog("Failed to get ChatGPT tip. Error: $e");
    }
  }

  void _getSystemAiTip(List<TagCount> tagCounts) {
    if (tagCounts.isEmpty) {
      _showDialog("No tasks done, create one first!");
      return;
    }

    tagCounts.sort((a, b) =>
        (b.completedCount + b.notCompletedCount).compareTo(a.completedCount + a.notCompletedCount));

    final mostTag = tagCounts.first;
    final leastTag = tagCounts.last;

    final random = Random();
    final openers = [
      "Interesting observation:",
      "Here's a suggestion:",
      "A quick tip for you:",
      "Here's something to consider:",
      "Take a look:",
    ];
    final transitions = [
      "maybe you should focus more on",
      "try to give more attention to",
      "you might want to catch up on",
      "consider balancing with",
      "see if you can add more tasks in",
    ];
    final endings = [
      "to even things out!",
      "for a healthier workflow!",
      "to keep it balanced!",
      "for better productivity!",
    ];

    String opener = openers[random.nextInt(openers.length)];
    String transition = transitions[random.nextInt(transitions.length)];
    String ending = endings[random.nextInt(endings.length)];

    String message =
        "$opener You have more '${mostTag.tag}' tasks than '${leastTag.tag}' tasks; $transition '${leastTag.tag}' $ending";

    _showDialog(message);
  }

  void _showDialog(String tip) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("AI Tip"),
        content: Text(tip),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }


  void _navigateToHome() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => UserHomePage(user: widget.user),
      ),
    );
  }

  void _navigateToPending() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => PendingTasks(user: widget.user, onTaskChanged: () {}),
      ),
    );
  }

  void _navigateToCompleted() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => CompletedTask(user: widget.user, onTaskChanged: () {}),
      ),
    );
  }

  void _navigateToOngoing() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => OngoingTasks(user: widget.user, onTaskChanged: () {}),
      ),
    );
  }

  void _navigateToDeleted() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => DeletedTasks(user: widget.user),
      ),
    );
  }

  void _navigateToAddTask() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => AddTaskPage(user: widget.user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Analytics',
          style: TextStyle(
            color: Colors.blue,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<List<TagCount>>(
        future: _tagCountsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}"),
            );
          } else {
            final tagCounts = snapshot.data ?? [];

            if (tagCounts.isEmpty) {
              return const Center(
                child: Text(
                  "No tasks done, create one first!",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              );
            }

            return Center(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SizedBox(
                      height: 250,
                      child: BarChartWidget(tagCounts: tagCounts),
                    ),
                  ),
                  const SizedBox(height: 30),
                  FloatingActionButton(
                    onPressed: () {
                      _showTipSelectionDialog(tagCounts);
                    },
                    backgroundColor: Colors.blue,
                    child: const Icon(Icons.lightbulb_outline, size: 30),
                  ),
                ],
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
              icon: Icon(Icons.home, color: Colors.blue.shade900, size: 30),
              onPressed: _navigateToHome,
            ),
            IconButton(
              icon: Icon(Icons.task, color: Colors.blue.shade900, size: 30),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => TimeManagementPage(user: widget.user),
                  ),
                );
              },
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => AddTaskPage(user: widget.user),
                  ),
                );
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
              icon: Icon(Icons.bar_chart, color: Colors.blue, size: 30),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.apps, color: Colors.blue.shade900, size: 30),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => UserProfilePage(user: widget.user),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class BarChartWidget extends StatelessWidget {
  final List<TagCount> tagCounts;

  const BarChartWidget({Key? key, required this.tagCounts}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final maxCompleted = tagCounts.isNotEmpty
        ? tagCounts.map((e) => e.completedCount).reduce(max)
        : 0;
    final maxNotCompleted = tagCounts.isNotEmpty
        ? tagCounts.map((e) => e.notCompletedCount).reduce(max)
        : 0;
    final maxY = max(maxCompleted, maxNotCompleted) + 2;

    if (tagCounts.isEmpty) {
      return const Center(
        child: Text(
          "No tasks done, create one first!",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY.toDouble(),
        barGroups: _createBarGroupsFromTagCounts(tagCounts),
        titlesData: FlTitlesData(
          leftTitles: SideTitles(
            showTitles: true,
            getTextStyles: (context, value) => const TextStyle(fontSize: 12),
            margin: 8,
            reservedSize: 30,
            getTitles: (double value) => value.toInt().toString(),
          ),
          bottomTitles: SideTitles(
            showTitles: true,
            getTextStyles: (context, value) => const TextStyle(fontSize: 12),
            getTitles: (double value) {
              int idx = value.toInt();
              if (idx >= 0 && idx < tagCounts.length) {
                return tagCounts[idx].tag;
              }
              return '';
            },
          ),
        ),
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueAccent,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.y.toInt()}',
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
      ),
    );
  }

  List<BarChartGroupData> _createBarGroupsFromTagCounts(List<TagCount> counts) {
    List<BarChartGroupData> groups = [];

    for (int i = 0; i < counts.length; i++) {
      final tc = counts[i];
      final completedY = tc.completedCount.toDouble();
      final notCompletedY = tc.notCompletedCount.toDouble();

      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(y: completedY, colors: [Colors.blue]),
            BarChartRodData(y: notCompletedY, colors: [Colors.purple]),
          ],
        ),
      );
    }
    return groups;
  }
}
