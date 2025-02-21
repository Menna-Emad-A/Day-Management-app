import 'package:flutter/material.dart';
import 'package:projectcode/home/time_managment_page.dart';
import '../login_pages/lib/database_helper.dart';

class ParentPage extends StatefulWidget {
  final Map<String, dynamic> user;

  const ParentPage({Key? key, required this.user}) : super(key: key);

  @override
  State<ParentPage> createState() => _ParentPageState();
}

class _ParentPageState extends State<ParentPage> {
  final dbHelper = DatabaseHelper();
  late Future<List<Map<String, dynamic>>> _linkedStudentsFuture;
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLinkedStudents();
  }

  void _loadLinkedStudents() {
    _linkedStudentsFuture = _fetchLinkedStudents();
  }

  Future<List<Map<String, dynamic>>> _fetchLinkedStudents() async {
    int parentId = widget.user['UUser_ID'];
    return await dbHelper.getLinkedStudents(parentId); // Ensure this method exists in DatabaseHelper
  }

  void _linkStudentAccount() async {
    String studentEmail = _emailController.text.trim();

    if (studentEmail.isEmpty) {
      _showErrorDialog('Please enter the student\'s email.');
      return;
    }

    try {
      // Fetch the student user by email
      final student = await dbHelper.getUserByEmail(studentEmail);

      if (student == null) {
        _showErrorDialog('No student found with this email.');
        return;
      }

      if (student['UType'] != 'Student') {
        _showErrorDialog('The email provided is not associated with a student account.');
        return;
      }

      // Link parent and student
      int parentId = widget.user['UUser_ID'];
      int studentId = student['UUser_ID'];
      await dbHelper.linkParentToStudent(parentId, studentId);

      // Reload the linked students list
      setState(() {
        _loadLinkedStudents();
      });

      _showSuccessDialog('Student account linked successfully.');
    } catch (e) {
      _showErrorDialog('An error occurred while linking the account.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error', style: TextStyle(color: Colors.red)),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Success', style: TextStyle(color: Colors.green)),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToStudentTasks(Map<String, dynamic> student) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TimeManagementPage(user: student, isParentView: true),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Linked Students'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Student Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _linkStudentAccount,
                  child: const Text('Link Account'),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _linkedStudentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text("Error: ${snapshot.error}"),
                  );
                } else {
                  final linkedStudents = snapshot.data ?? [];

                  if (linkedStudents.isEmpty) {
                    return const Center(
                      child: Text(
                        'No linked students found.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: linkedStudents.length,
                    itemBuilder: (context, index) {
                      final student = linkedStudents[index];
                      return ListTile(
                        leading: const Icon(Icons.person, color: Colors.blue),
                        title: Text(student['UUsername']),
                        subtitle: Text(student['UEmail']),
                        trailing: IconButton(
                          icon: const Icon(Icons.arrow_forward, color: Colors.blue),
                          onPressed: () => _navigateToStudentTasks(student),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
