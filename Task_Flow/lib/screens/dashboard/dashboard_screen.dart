import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../providers/task_provider.dart';
import '../../providers/notification_provider.dart';
import 'notification_center_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Read user tasks from TaskProvider
    final taskProvider = Provider.of<TaskProvider>(context);
    final tasks = taskProvider.tasks;
    
    // Calculate simple stats
    final total = tasks.length;
    final completed = tasks.where((t) => t.completed).length;
    final pending = total - completed;
    final percent = total == 0 ? 0.0 : (completed / total);

    // Group tasks by category for simple progress bars
    final categoryCounts = <String, int>{};
    for (var task in tasks) {
      categoryCounts[task.category] = (categoryCounts[task.category] ?? 0) + 1;
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            // Pull-to-refresh action (does nothing since data is offline/local)
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section with Date, Title, and Notification Bell Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEEE, d MMMM').format(DateTime.now()),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'My Progress',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    _buildBellIcon(context),
                  ],
                ),
                const SizedBox(height: 24),

                // Metrics cards (total, completed, pending, rate)
                _buildMetricsGrid(context, total, completed, pending, percent),
                const SizedBox(height: 24),

                // Simple Category Breakdown list (replacing complex fl_chart)
                _buildCategorySection(context, categoryCounts, total),
                const SizedBox(height: 24),

                // Quick Activity/Checklist status card
                _buildQuickOverviewCard(context, completed, total),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Simple grid of stats cards
  Widget _buildMetricsGrid(
    BuildContext context,
    int total,
    int completed,
    int pending,
    double percent,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 0.85,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Total Tasks Card
        _buildMetricCard(
          context,
          title: 'Total Tasks',
          value: '$total',
          subtitle: 'Active & finished',
          icon: Icons.list_alt_rounded,
          color: AppTheme.primarySeedColor,
        ),
        // Completed Tasks Card
        _buildMetricCard(
          context,
          title: 'Completed',
          value: '$completed',
          subtitle: '${(percent * 100).toInt()}% completion',
          icon: Icons.check_circle_outline_rounded,
          color: AppTheme.secondaryColor,
        ),
        // Pending Tasks Card
        _buildMetricCard(
          context,
          title: 'Pending',
          value: '$pending',
          subtitle: 'Requires attention',
          icon: Icons.pending_actions_rounded,
          color: Colors.orange,
        ),
        // Simple Circular Indicator Card for Completion Rate
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 64,
                  width: 64,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: percent,
                        strokeWidth: 6,
                        backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primarySeedColor),
                      ),
                      Center(
                        child: Text(
                          '${(percent * 100).toInt()}%',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Completion Rate',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Helper widget to construct standard metric cards
  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Clean and simple list representation of Categories (replacing PieChart)
  Widget _buildCategorySection(
    BuildContext context,
    Map<String, int> categoryCounts,
    int total,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Show empty prompt if there are no tasks
    if (total == 0) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
          ),
        ),
        child: const Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(
            child: Text(
              'Add tasks to see category breakdown.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }

    // Colors mapping list
    final colors = [
      AppTheme.primarySeedColor,
      AppTheme.secondaryColor,
      Colors.orange,
      Colors.pink,
      Colors.blue,
      Colors.purple,
    ];

    int colorIndex = 0;
    final List<Widget> categoryWidgets = [];

    categoryCounts.forEach((category, count) {
      final color = colors[colorIndex % colors.length];
      colorIndex++;
      final ratio = count / total;

      categoryWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category title and text metrics
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    category,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    '$count tasks (${(ratio * 100).toStringAsFixed(0)}%)',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Simple progress indicator showing ratio
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 8,
                  backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
      );
    });

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tasks by Category',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ...categoryWidgets,
          ],
        ),
      ),
    );
  }

  // Simple bottom checklist overview card
  Widget _buildQuickOverviewCard(BuildContext context, int completed, int total) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allDone = total > 0 && completed == total;

    return Card(
      elevation: 0,
      color: allDone
          ? AppTheme.secondaryColor.withValues(alpha: 0.1)
          : AppTheme.primarySeedColor.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: allDone
              ? AppTheme.secondaryColor.withValues(alpha: 0.2)
              : AppTheme.primarySeedColor.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Icon(
              allDone ? Icons.celebration_rounded : Icons.wb_sunny_rounded,
              color: allDone ? AppTheme.secondaryColor : AppTheme.primarySeedColor,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    allDone ? 'All Caught Up!' : 'Keep it up!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: allDone ? AppTheme.secondaryColor : AppTheme.primarySeedColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    allDone
                        ? 'You completed all your scheduled tasks!'
                        : 'You completed $completed out of $total tasks today.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // App Bar Notification Icon
  Widget _buildBellIcon(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notifProvider, child) {
        final count = notifProvider.unreadCount;
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, size: 28),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationCenterScreen(),
                  ),
                );
              },
            ),
            if (count > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
