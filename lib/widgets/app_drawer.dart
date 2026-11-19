import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class AppDrawer extends StatefulWidget {
  final Function(String?) onSelectCategory;
  final VoidCallback onLogout;

  const AppDrawer({
    super.key,
    required this.onSelectCategory,
    required this.onLogout,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    final userEmail = FirebaseService().userEmail;

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.tertiary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            accountName: const Text(
              'Task & Assignment Manager',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            accountEmail: Text(userEmail),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.onPrimary,
              child: Icon(
                Icons.assignment_ind,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.all_inbox),
            title: const Text('All Categories'),
            onTap: () {
              Navigator.pop(context);
              widget.onSelectCategory(null);
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Filter by Category',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.work, color: Colors.blue),
            title: const Text('Work'),
            onTap: () {
              Navigator.pop(context);
              widget.onSelectCategory('Work');
            },
          ),
          ListTile(
            leading: const Icon(Icons.school, color: Colors.orange),
            title: const Text('School'),
            onTap: () {
              Navigator.pop(context);
              widget.onSelectCategory('School');
            },
          ),
          ListTile(
            leading: const Icon(Icons.assignment, color: Colors.purple),
            title: const Text('Assignment'),
            onTap: () {
              Navigator.pop(context);
              widget.onSelectCategory('Assignment');
            },
          ),
          ListTile(
            leading: const Icon(Icons.person, color: Colors.green),
            title: const Text('Personal'),
            onTap: () {
              Navigator.pop(context);
              widget.onSelectCategory('Personal');
            },
          ),
          ListTile(
            leading: const Icon(Icons.folder_special, color: Colors.teal),
            title: const Text('Project'),
            onTap: () {
              Navigator.pop(context);
              widget.onSelectCategory('Project');
            },
          ),
          const Spacer(),
          const Divider(),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode),
            title: const Text('Dark Theme'),
            subtitle: const Text('Toggle app appearance'),
            value: _darkMode,
            onChanged: (val) {
              setState(() {
                _darkMode = val;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(val ? 'Dark mode enabled' : 'Light mode enabled'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Logout', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  _showLogoutConfirmationDialog(context);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out of Task Manager?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Close drawer
              widget.onLogout();
            },
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
