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
  String _selectedPriorityFilter = 'All'; // All, Low, Medium, High
  String _selectedStatusFilter = 'All'; // All, Active, Completed

  final List<String> _categories = ['All', 'Work', 'Personal', 'Shopping', 'Health', 'Others'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Container(
              padding: const EdgeInsets.all(20.0),
              color: isDark ? const Color(0xFF1F2937) : Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Filters',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const Divider(),
                  const SizedBox(height: 12),
                  
                  // Priority Filter
                  const Text('Priority', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: ['All', 'Low', 'Medium', 'High'].map((prio) {
                      final selected = _selectedPriorityFilter == prio;
                      return ChoiceChip(
                        label: Text(prio),
                        selected: selected,
                        onSelected: (val) {
                          if (val) {
                            setModalState(() => _selectedPriorityFilter = prio);
                            setState(() {}); // Re-render main list
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Completion Status Filter
                  const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: ['All', 'Active', 'Completed'].map((status) {
                      final selected = _selectedStatusFilter == status;
                      return ChoiceChip(
                        label: Text(status),
                        selected: selected,
                        onSelected: (val) {
                          if (val) {
                            setModalState(() => _selectedStatusFilter = status);
                            setState(() {}); // Re-render main list
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Apply Filters'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openAddTaskSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TaskDetailSheet(),
    );
  }

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

    // Apply Search and Filters locally
    final filteredTasks = tasks.where((task) {
      // 1. Search Query Filter
      final query = _searchController.text.toLowerCase().trim();
      final matchesSearch = query.isEmpty ||
          task.title.toLowerCase().contains(query) ||
          task.description.toLowerCase().contains(query);

      // 2. Category Filter
      final matchesCategory = _selectedCategory == 'All' || task.category == _selectedCategory;

      // 3. Priority Filter
      final matchesPriority = _selectedPriorityFilter == 'All' || task.priority == _selectedPriorityFilter;

      // 4. Status Filter
      bool matchesStatus = true;
      if (_selectedStatusFilter == 'Active') {
        matchesStatus = !task.completed;
      } else if (_selectedStatusFilter == 'Completed') {
        matchesStatus = task.completed;
      }

      return matchesSearch && matchesCategory && matchesPriority && matchesStatus;
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Search and Filter Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
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
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.filter_list_rounded),
                    onPressed: _openFilterDialog,
                  ),
                ],
              ),
            ),

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
                        color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
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

            // Task List View or Empty State
            Expanded(
              child: taskProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredTasks.isEmpty
                      ? _buildEmptyState(context)
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
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

  Widget _buildEmptyState(BuildContext context) {
    final hasActiveFilters = _searchController.text.isNotEmpty ||
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
              hasActiveFilters ? Icons.search_off_rounded : Icons.checklist_rounded,
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

  Widget _buildTaskCard(BuildContext context, TaskModel task) {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Check if task is overdue
    final isOverdue = !task.completed && task.dueDate.isBefore(DateTime.now());

    // Color code priority badge
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
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openEditTaskSheet(task),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom checkbox toggle
              Transform.scale(
                scale: 1.1,
                child: Checkbox(
                  value: task.completed,
                  activeColor: AppTheme.secondaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  onChanged: (_) {
                    taskProvider.toggleTaskComplete(task);
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Text info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration: task.completed ? TextDecoration.lineThrough : null,
                        color: task.completed
                            ? Colors.grey
                            : (isDark ? Colors.white : const Color(0xFF1F2937)),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Description (if present)
                    if (task.description.isNotEmpty) ...[
                      Text(
                        task.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: task.completed ? Colors.grey[600] : Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Meta Wrap (pills & due dates)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Category tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            task.category,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),

                        // Priority Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: priorityColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: priorityColor.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            task.priority,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: priorityColor,
                            ),
                          ),
                        ),

                        // Due Date Icon and Text
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: isOverdue
                                  ? Colors.redAccent
                                  : (task.completed ? Colors.grey : Colors.grey[500]),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('d MMM, h:mm a').format(task.dueDate),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                                color: isOverdue
                                    ? Colors.redAccent
                                    : (task.completed ? Colors.grey : Colors.grey[600]),
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
