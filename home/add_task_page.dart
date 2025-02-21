import 'package:flutter/material.dart';
import '../login_pages/lib/database_helper.dart';

class AddTaskPage extends StatefulWidget {
  final Map<String, dynamic> user;
  final Map<String, dynamic>? existingTask;

  const AddTaskPage({
    Key? key,
    required this.user,
    this.existingTask,
  }) : super(key: key);

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  final TextEditingController _startController = TextEditingController();

  String _selectedTaskType = "Personal";
  List<String> _selectedTags = [];
  final List<String> _statuses = ['Pending', 'On Going', 'Completed', 'Deleted'];
  String _selectedStatus = 'Pending';

  @override
  void initState() {
    super.initState();
    if (widget.existingTask != null) {
      final task = widget.existingTask!;
      _titleController.text = task['TDescription'] ?? '';
      _dateController.text = task['TDueDate'] ?? '';
      _endController.text = task['TEndTime'] ?? '';
      _startController.text = task['TStartTime'] ?? '';

      _selectedStatus = task['TStatus'] ?? 'Pending';
      _selectedTaskType = task['TType'] ?? 'Personal';

      String tags = task['TTags'] ?? '';
      if (tags.isNotEmpty) {
        _selectedTags = tags.split(',').map((t) => t.trim()).toList();
      }
      _descController.text = "";
    }
  }

  Future<void> _saveTask() async {
    String title = _titleController.text.trim();
    String date = _dateController.text.trim();
    String startTime = _startController.text.trim();
    String endTime = _endController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a title for the task')),
      );
      return;
    }
    if (date.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a date')),
      );
      return;
    }
    if (startTime.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a start time')),
      );
      return;
    }
    if (endTime.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an end time')),
      );
      return;
    }

    // Validate that end time is not earlier than start time
    final start = _convertTimeOfDayToDateTime(startTime);
    final end = _convertTimeOfDayToDateTime(endTime);

    if (end.isBefore(start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time cannot be earlier than start time')),
      );
      return;
    }

    int userId = widget.user['UUser_ID'];
    String tagsString = _selectedTags.join(", ");

    final taskData = {
      'TDescription': title,
      'TDueDate': date,
      'TStartTime': startTime,
      'TEndTime': endTime,
      'TStatus': _selectedStatus,
      'TUser_ID': userId,
      'TType': _selectedTaskType,
      'TTags': tagsString,
    };

    final dbHelper = DatabaseHelper();

    try {
      if (widget.existingTask == null) {
        await dbHelper.insertTask(taskData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task created')),
        );
      } else {
        int taskId = widget.existingTask!['TTask_ID'];
        await dbHelper.updateTask(taskId, taskData);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task updated')),
        );
      }
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving task: $e')),
      );
    }
  }

// Helper function to convert time string to DateTime for comparison
  DateTime _convertTimeOfDayToDateTime(String time) {
    final timeParts = time.split(' ');
    final hourMinute = timeParts[0].split(':');
    final hour = int.parse(hourMinute[0]);
    final minute = int.parse(hourMinute[1]);
    final isPM = timeParts[1].toUpperCase() == 'PM';

    return DateTime(0, 1, 1, isPM ? hour % 12 + 12 : hour % 12, minute);
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.existingTask != null;

    return Scaffold(
      appBar: AppBar(
        leading: InkWell(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: Text(
          isEditing ? 'Update Task' : 'Add Task',
          style: TextStyle(
            fontSize: 20,
            color: Colors.blue[900],
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField('Title', 'Plan for a month',
                controller: _titleController),
            const SizedBox(height: 16),
            _buildDateField(context, 'Date', '4 August 2024', _dateController),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                    child: _buildTimeField('Start Time', '8:00 AM')),
                const SizedBox(width: 16),
                Expanded(child: _buildTimeField('End Time', '9:00 AM')),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField('Description', "Creating this month's work plan",
                controller: _descController),
            const SizedBox(height: 16),
            Text(
              'Type',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTaskType = 'Personal';
                    });
                  },
                  child: _buildTypeChip(
                    'Personal',
                    _selectedTaskType == 'Personal',
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTaskType = 'Private';
                    });
                  },
                  child: _buildTypeChip(
                    'Private',
                    _selectedTaskType == 'Private',
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTaskType = 'Secret';
                    });
                  },
                  child: _buildTypeChip(
                    'Secret',
                    _selectedTaskType == 'Secret',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Status',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value!;
                });
              },
              items: _statuses.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(status),
                );
              }).toList(),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Tags',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildTagChip('Office', Colors.purple[100]!),
                _buildTagChip('Home', Colors.orange[100]!),
                _buildTagChip('Urgent', Colors.red[100]!),
                _buildTagChip('Work', Colors.green[100]!),
              ],
            ),
            const SizedBox(height: 8),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveTask,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[900],
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                isEditing ? 'Update' : 'Create',
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      String label,
      String placeholder, {
        TextEditingController? controller,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:
          const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: placeholder,
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(
      BuildContext context,
      String label,
      String placeholder,
      TextEditingController controller,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: true,
          onTap: () async {
            final now = DateTime.now();
            final maxDate = now.add(const Duration(days: 365 * 2)); // 2 years max

            DateTime? selectedDate = await showDatePicker(
              context: context,
              initialDate: now,
              firstDate: now,
              lastDate: maxDate,
              selectableDayPredicate: (DateTime date) {
                // Allow only dates from today onwards
                return date.isAfter(now.subtract(const Duration(days: 1)));
              },
            );

            if (selectedDate != null) {
              setState(() {
                controller.text =
                "${selectedDate.day} ${_getMonthName(selectedDate.month)} ${selectedDate.year}";
              });
            }
          },
          decoration: InputDecoration(
            hintText: placeholder,
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            suffixIcon: Icon(Icons.calendar_today, color: Colors.grey),
          ),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  Widget _buildTimeField(String label, String placeholder) {
    // Get the correct controller based on the label
    final controller = label == 'Start Time' ? _startController : _endController;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,  // Add the controller here
          readOnly: true,
          decoration: InputDecoration(
            hintText: placeholder,
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            suffixIcon: Icon(Icons.access_time, color: Colors.grey),
          ),
          onTap: () async {
            TimeOfDay? selectedTime = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
              builder: (BuildContext context, Widget? child) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    alwaysUse24HourFormat: false,
                  ),
                  child: child!,
                );
              },
            );
            if (selectedTime != null) {
              setState(() {
                // Convert 24-hour format to 12-hour format
                final hour = selectedTime.hourOfPeriod;
                final minute = selectedTime.minute.toString().padLeft(2, '0');
                final period = selectedTime.period == DayPeriod.am ? 'AM' : 'PM';
                final formattedHour = hour == 0 ? 12 : hour;
                final time = '$formattedHour:$minute $period';
                controller.text = time;
              });
            }
          },
        ),
      ],
    );
  }
  Widget _buildTypeChip(String label, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? Colors.blue[900] : Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: selected ? Colors.white : Colors.black),
      ),
    );
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  Widget _buildTagChip(String label, Color color) {
    bool isSelected = _selectedTags.contains(label);
    return GestureDetector(
      onTap: () => _toggleTag(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.5) : color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label),
      ),
    );
  }
}
