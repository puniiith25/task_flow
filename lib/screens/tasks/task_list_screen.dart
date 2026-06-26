import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';
import 'task_detail_sheet.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _selectedPriorityFilter = 'All'; // Options: All, Low, Medium, High
  String _selectedStatusFilter = 'All'; // Options: All, Active, Completed

  final List<String> _categories = [
    'All',
    'Work',
    'Personal',
    'Shopping',
    'Health',
    'Others',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Opens the sheet to add a new task
  void _openAddTaskSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TaskDetailSheet(),
    );
  }

  // Opens the sheet to edit an existing task
  void _openEditTaskSheet(TaskModel task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskDetailSheet(task: task),
    );
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final tasks = taskProvider.tasks;

    // Apply Search queries and filter selections locally on the tasks list
    final filteredTasks = tasks.where((task) {
      // 1. Search Query Filter
      final query = _searchController.text.toLowerCase().trim();
      final matchesSearch =
          query.isEmpty ||
          task.title.toLowerCase().contains(query) ||
          task.description.toLowerCase().contains(query);

      // 2. Category Filter
      final matchesCategory =
          _selectedCategory == 'All' || task.category == _selectedCategory;

      // 3. Priority Filter
      final matchesPriority =
          _selectedPriorityFilter == 'All' ||
          task.priority == _selectedPriorityFilter;

      // 4. Status Filter (Active / Completed)
      bool matchesStatus = true;
      if (_selectedStatusFilter == 'Active') {
        matchesStatus = !task.completed;
      } else if (_selectedStatusFilter == 'Completed') {
        matchesStatus = task.completed;
      }

      return matchesSearch &&
          matchesCategory &&
          matchesPriority &&
          matchesStatus;
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Search Input Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search tasks...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
              ),
            ),

            // Inline Filters (Priority & Status) - Beginner friendly row of dropdown buttons
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 4.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _selectedPriorityFilter,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(),
                      ),
                      items: ['All', 'Low', 'Medium', 'High'].map((
                        String priority,
                      ) {
                        return DropdownMenuItem<String>(
                          value: priority,
                          child: Text(
                            priority,
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedPriorityFilter = val;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _selectedStatusFilter,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(),
                      ),
                      items: ['All', 'Active', 'Completed'].map((
                        String status,
                      ) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Text(
                            status,
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedStatusFilter = val;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Horizontal Scrollable Category Pills
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      selectedColor: AppTheme.primarySeedColor,
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _selectedCategory = cat;
                          });
                        }
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Task List View or Empty State representation
            Expanded(
              child: taskProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredTasks.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.builder(
                      padding: const EdgeInsets.only(
                        bottom: 80,
                        left: 8,
                        right: 8,
                      ),
                      itemCount: filteredTasks.length,
                      itemBuilder: (context, index) {
                        return _buildTaskCard(context, filteredTasks[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primarySeedColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: _openAddTaskSheet,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  // Displayed when no tasks match the filters
  Widget _buildEmptyState(BuildContext context) {
    final hasActiveFilters =
        _searchController.text.isNotEmpty ||
        _selectedCategory != 'All' ||
        _selectedPriorityFilter != 'All' ||
        _selectedStatusFilter != 'All';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasActiveFilters
                  ? Icons.search_off_rounded
                  : Icons.checklist_rounded,
              size: 72,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              hasActiveFilters ? 'No results found' : 'All clear!',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              hasActiveFilters
                  ? 'Try modifying your search text or clear active filters.'
                  : 'Add tasks to stay productive and organized.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
            if (hasActiveFilters) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _selectedCategory = 'All';
                    _selectedPriorityFilter = 'All';
                    _selectedStatusFilter = 'All';
                  });
                },
                child: const Text('Clear All Filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Reusable card to display information about a single task
  Widget _buildTaskCard(BuildContext context, TaskModel task) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Check if task is past due date and not completed
    final isOverdue = !task.completed && task.dueDate.isBefore(DateTime.now());

    // Assign color coding to priorities
    Color priorityColor;
    switch (task.priority) {
      case 'High':
        priorityColor = Colors.redAccent;
        break;
      case 'Medium':
        priorityColor = Colors.orange;
        break;
      default:
        priorityColor = AppTheme.secondaryColor;
    }

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openEditTaskSheet(task),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox selector
              Checkbox(
                value: task.completed,
                activeColor: AppTheme.secondaryColor,
                onChanged: (_) {
                  taskProvider.toggleTaskComplete(task);
                },
              ),
              const SizedBox(width: 8),

              // Title and details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        decoration: task.completed
                            ? TextDecoration.lineThrough
                            : null,
                        color: task.completed
                            ? Colors.grey
                            : (isDark ? Colors.white : const Color(0xFF1F2937)),
                      ),
                    ),
                    const SizedBox(height: 4),

                    if (task.description.isNotEmpty) ...[
                      Text(
                        task.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: task.completed
                              ? Colors.grey[600]
                              : Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Tags and schedule text
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Category Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF374151)
                                : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            task.category,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        // Priority Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: priorityColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: priorityColor.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            task.priority,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: priorityColor,
                            ),
                          ),
                        ),

                        // Due Date Info
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 13,
                              color: isOverdue
                                  ? Colors.redAccent
                                  : (task.completed
                                        ? Colors.grey
                                        : Colors.grey[500]),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('d MMM, h:mm a').format(task.dueDate),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isOverdue
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isOverdue
                                    ? Colors.redAccent
                                    : (task.completed
                                          ? Colors.grey
                                          : Colors.grey[600]),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
