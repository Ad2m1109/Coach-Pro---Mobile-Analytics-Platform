import 'package:flutter/material.dart';
import '../../models/staff.dart';
import '../../services/staff_service.dart';
import '../../services/auth_service.dart';
import 'package:provider/provider.dart';
import 'create_staff_screen.dart';

class StaffListScreen extends StatefulWidget {
  const StaffListScreen({Key? key}) : super(key: key);

  @override
  State<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends State<StaffListScreen> {
  late final StaffService _staffService;
  List<Staff> _staff = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _staffService = StaffService(apiClient: authService.apiClient);
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final staff = await _staffService.getAllStaff();
      setState(() {
        _staff = staff;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteStaff(String staffId) async {
    try {
      await _staffService.deleteStaff(staffId);
      _loadStaff(); // Reload list
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff member deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting staff: $e')),
        );
      }
    }
  }

  Widget _buildPermissionBadge(PermissionLevel level) {
    Color color;
    IconData icon;

    switch (level) {
      case PermissionLevel.fullAccess:
        color = Colors.green;
        icon = Icons.admin_panel_settings;
        break;
      case PermissionLevel.viewOnly:
        color = Colors.blue;
        icon = Icons.visibility;
        break;
      case PermissionLevel.notesOnly:
        color = Colors.orange;
        icon = Icons.edit_note;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            level.displayName,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final canManageAccounts = authService.canManageAccounts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Members'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStaff,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadStaff,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _staff.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.people_outline, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'No staff members yet',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          if (canManageAccounts) ...[
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const CreateStaffScreen(),
                                  ),
                                );
                                _loadStaff();
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Add Staff Member'),
                            ),
                          ],
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _staff.length,
                      itemBuilder: (context, index) {
                        final staff = _staff[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CreateStaffScreen(staff: staff),
                                ),
                              );
                              _loadStaff();
                            },
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor,
                              child: Text(
                                staff.name[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              staff.name,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                if (staff.role != null)
                                  Text(staff.role!.displayName),
                                if (staff.email != null)
                                  Text(
                                    staff.email!,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                const SizedBox(height: 8),
                                _buildPermissionBadge(staff.permissionLevel),
                              ],
                            ),
                            trailing: canManageAccounts
                                ? IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete Staff Member'),
                                          content: Text(
                                            'Are you sure you want to delete ${staff.name}?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                _deleteStaff(staff.id);
                                              },
                                              child: const Text(
                                                'Delete',
                                                style: TextStyle(color: Colors.red),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  )
                                : null,
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
      floatingActionButton: canManageAccounts
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateStaffScreen(),
                  ),
                );
                _loadStaff();
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Staff'),
            )
          : null,
    );
  }
}
