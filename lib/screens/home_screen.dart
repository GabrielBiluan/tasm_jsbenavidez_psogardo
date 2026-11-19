import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/firebase_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/task_grid_item.dart';
import '../widgets/task_list_item.dart';
import '../widgets/task_quick_view_sheet.dart';
import 'task_detail_screen.dart';
import 'task_form_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const HomeScreen({super.key, required this.onLogout});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentBottomIndex = 0;
  String? _selectedCategoryFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _navigateToTaskForm({TaskModel? task}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => TaskFormScreen(taskToEdit: task),
      ),
    );
  }

  void _navigateToTaskDetail(TaskModel task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => TaskDetailScreen(task: task),
      ),
    );
  }

  List<TaskModel> _filterTasks(List<TaskModel> allTasks, int tabIndex) {
    var filtered = allTasks;

    // Filter by Category if selected via Drawer
    if (_selectedCategoryFilter != null) {
      filtered = filtered
          .where((t) => t.category.toLowerCase() == _selectedCategoryFilter!.toLowerCase())
          .toList();
    }

    // Filter by Status Tab
    if (tabIndex == 1) {
      // Pending
      return filtered.where((t) => !t.isCompleted).toList();
    } else if (tabIndex == 2) {
      // Completed
      return filtered.where((t) => t.isCompleted).toList();
    }
    return filtered; // All
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedCategoryFilter == null
              ? 'Task & Assignment Manager'
              : 'Category: $_selectedCategoryFilter',
        ),
        actions: [
          if (_selectedCategoryFilter != null)
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: 'Clear Category Filter',
              onPressed: () {
                setState(() {
                  _selectedCategoryFilter = null;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cleared category filter')),
                );
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list_alt), text: 'All Tasks'),
            Tab(icon: Icon(Icons.pending_actions), text: 'Pending'),
            Tab(icon: Icon(Icons.check_circle_outline), text: 'Completed'),
          ],
        ),
      ),
      drawer: AppDrawer(
        onSelectCategory: (cat) {
          setState(() {
            _selectedCategoryFilter = cat;
          });
          if (cat != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Filtering by category: $cat')),
            );
          }
        },
        onLogout: widget.onLogout,
      ),
      // --- REAL-TIME DATA DISPLAY USING STREAMBUILDER ---
      body: StreamBuilder<List<TaskModel>>(
        stream: FirebaseService().getTasksStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text('Error loading tasks: ${snapshot.error}'),
                ],
              ),
            );
          }

          final allTasks = snapshot.data ?? [];

          return TabBarView(
            controller: _tabController,
            children: [
              _buildTaskContent(allTasks, 0),
              _buildTaskContent(allTasks, 1),
              _buildTaskContent(allTasks, 2),
            ],
          );
        },
      ),
      // --- NAVIGATION: BOTTOM NAVIGATION BAR ---
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentBottomIndex,
        onTap: (index) {
          setState(() {
            _currentBottomIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.view_list),
            label: 'List View',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view),
            label: 'Grid Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            label: 'Summary',
          ),
        ],
      ),
      // --- BUTTONS: FLOATING ACTION BUTTON ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToTaskForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
    );
  }

  Widget _buildTaskContent(List<TaskModel> allTasks, int tabIndex) {
    final tasks = _filterTasks(allTasks, tabIndex);

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No tasks found.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Create your first task'),
              onPressed: () => _navigateToTaskForm(),
            ),
          ],
        ),
      );
    }

    if (_currentBottomIndex == 0) {
      // --- LISTS USING LISTVIEW ---
      return ListView.builder(
        itemCount: tasks.length,
        padding: const EdgeInsets.only(bottom: 80, top: 8),
        itemBuilder: (context, index) {
          final task = tasks[index];
          return TaskListItem(
            task: task,
            onTap: () => _navigateToTaskDetail(task),
            onLongPress: () => TaskQuickViewSheet.show(
              context,
              task: task,
              onEdit: () => _navigateToTaskForm(task: task),
              onViewDetails: () => _navigateToTaskDetail(task),
            ),
          );
        },
      );
    } else if (_currentBottomIndex == 1) {
      // --- LISTS USING GRIDVIEW ---
      return GridView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: tasks.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.78,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemBuilder: (context, index) {
          final task = tasks[index];
          return TaskGridItem(
            task: task,
            onTap: () => _navigateToTaskDetail(task),
            onLongPress: () => TaskQuickViewSheet.show(
              context,
              task: task,
              onEdit: () => _navigateToTaskForm(task: task),
              onViewDetails: () => _navigateToTaskDetail(task),
            ),
          );
        },
      );
    } else {
      // Analytics & Summary view
      final total = allTasks.length;
      final completed = allTasks.where((t) => t.isCompleted).length;
      final pending = total - completed;
      final urgentCount = allTasks.where((t) => t.isUrgent && !t.isCompleted).length;

      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Task Overview & Statistics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('Total', '$total', Colors.blue, Icons.assignment),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('Pending', '$pending', Colors.orange, Icons.pending),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('Completed', '$completed', Colors.green, Icons.check_circle),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('Urgent', '$urgentCount', Colors.red, Icons.warning),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add_task),
                    label: const Text('Add Task'),
                    onPressed: () => _navigateToTaskForm(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton.icon(
                    icon: const Icon(Icons.filter_list),
                    label: const Text('Reset Category Filter'),
                    onPressed: () {
                      setState(() {
                        _selectedCategoryFilter = null;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
