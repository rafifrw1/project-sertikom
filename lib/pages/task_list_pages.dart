import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class TaskListPages extends StatefulWidget {
  const TaskListPages({super.key});

  @override
  State<TaskListPages> createState() => _TaskListPagesState();
}

class _TaskListPagesState extends State<TaskListPages> {
  List<Map<String, dynamic>> _taskList = [];
  bool _isLoading = true;
  String _categoryFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllTasks();
    setState(() {
      _taskList = data;
      _isLoading = false;
    });
  }

  Future<void> _toggleDone(int id, bool currentStatus) async {
    await DatabaseHelper.instance.updateTaskStatus(id, !currentStatus);
    _loadTasks();
  }

  Future<void> _deleteTask(int id) async {
    await DatabaseHelper.instance.deleteTask(id);
    _loadTasks();
  }

  Future<void> _showEditTaskModal(Map<String, dynamic> task) async {
    final titleController = TextEditingController(text: task['title'] as String? ?? '');
    final descriptionController =
        TextEditingController(text: task['description'] as String? ?? '');
    DateTime selectedDate = DateTime.parse(task['due_date'] as String);
    final isImportant = task['category'] == 'important';
    final primaryColor = isImportant ? Colors.red[500]! : const Color(0xFF2E7D32);

    Future<void> pickDate(StateSetter setModalState) async {
      final picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(primary: primaryColor),
            ),
            child: child!,
          );
        },
      );
      if (picked != null) {
        setModalState(() => selectedDate = picked);
      }
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit Task',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      filled: true,
                      fillColor: const Color(0xFFF7F8FB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      filled: true,
                      fillColor: const Color(0xFFF7F8FB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => pickDate(setModalState),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F8FB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              color: primaryColor, size: 18),
                          const SizedBox(width: 10),
                          Text(
                            _formatDate(
                                selectedDate.toIso8601String().substring(0, 10)),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[700],
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final title = titleController.text.trim();
                            if (title.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Title cannot be empty'),
                                ),
                              );
                              return;
                            }
                            await DatabaseHelper.instance.updateTask(
                              task['id'] as int,
                              {
                                'title': title,
                                'description': descriptionController.text.trim(),
                                'due_date':
                                    selectedDate.toIso8601String().substring(0, 10),
                                'category': task['category'],
                                'is_done': task['is_done'],
                                'completed_date': task['completed_date'],
                              },
                            );
                            if (!mounted) return;
                            Navigator.pop(context);
                            _loadTasks();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showTaskActions(Map<String, dynamic> task) async {
    final isImportant = task['category'] == 'important';
    final primaryColor = isImportant ? Colors.red[500]! : const Color(0xFF2E7D32);

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Icon(Icons.edit_rounded, color: primaryColor),
                  title: const Text('Edit Task'),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditTaskModal(task);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_rounded, color: Colors.red),
                  title: const Text('Delete Task'),
                  onTap: () async {
                    Navigator.pop(context);
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Delete Task'),
                          content: const Text('Are you sure you want to delete this task?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        );
                      },
                    );
                    if (confirmed == true) {
                      await _deleteTask(task['id'] as int);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(String dateStr) {
    // dateStr format: yyyy-MM-dd
    final parts = dateStr.split('-');
    if (parts.length != 3) return dateStr;
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final day = parts[2];
    final month = months[int.parse(parts[1])];
    final year = parts[0];
    return '$day $month $year';
  }

  Widget _buildFilterChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: const Text('All'),
          selected: _categoryFilter == 'all',
          selectedColor: const Color(0xFFE91E63).withOpacity(0.15),
          labelStyle: TextStyle(
            color: _categoryFilter == 'all'
                ? const Color(0xFFE91E63)
                : Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
          onSelected: (_) => setState(() => _categoryFilter = 'all'),
        ),
        ChoiceChip(
          label: const Text('Important'),
          selected: _categoryFilter == 'important',
          selectedColor: Colors.red[500]!.withOpacity(0.15),
          labelStyle: TextStyle(
            color: _categoryFilter == 'important'
                ? Colors.red[600]
                : Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
          onSelected: (_) => setState(() => _categoryFilter = 'important'),
        ),
        ChoiceChip(
          label: const Text('Regular'),
          selected: _categoryFilter == 'regular',
          selectedColor: const Color(0xFF2E7D32).withOpacity(0.15),
          labelStyle: TextStyle(
            color: _categoryFilter == 'regular'
                ? const Color(0xFF2E7D32)
                : Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
          onSelected: (_) => setState(() => _categoryFilter = 'regular'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _categoryFilter == 'all'
        ? _taskList
        : _taskList
            .where((task) => task['category'] == _categoryFilter)
            .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Task List', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFE91E63),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE91E63)))
          : RefreshIndicator(
              onRefresh: _loadTasks,
              color: const Color(0xFFE91E63),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: filteredTasks.isEmpty ? 2 : filteredTasks.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildFilterChips();
                  }

                  if (filteredTasks.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(Icons.inbox_rounded,
                              size: 56, color: Colors.grey[300]),
                          const SizedBox(height: 10),
                          Text(
                            'No tasks for this category',
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  }

                  final task = filteredTasks[index - 1];
                  final isImportant = task['category'] == 'important';
                  final isDone = task['is_done'] == 1;
                  final primaryColor = isImportant
                      ? Colors.red[500]!
                      : const Color(0xFF2E7D32);

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: primaryColor.withOpacity(0.12)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: GestureDetector(
                        onTap: () => _toggleDone(task['id'], isDone),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isDone
                                  ? primaryColor
                                  : Colors.grey[300]!,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: isDone
                                ? primaryColor
                                : Colors.transparent,
                          ),
                          child: isDone
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 18,
                                )
                              : null,
                        ),
                      ),
                      title: Text(
                        task['title'],
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          decoration:
                              isDone ? TextDecoration.lineThrough : null,
                          color: isDone ? Colors.grey : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        '${_formatDate(task['due_date'])} · ${isImportant ? "Important" : "Regular"}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.more_horiz_rounded, color: primaryColor),
                        onPressed: () => _showTaskActions(task),
                      ),
                      onTap: () => _toggleDone(task['id'], isDone),
                    ),
                  );
                },
              ),
            ),
    );
  }
}