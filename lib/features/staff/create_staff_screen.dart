import 'package:flutter/material.dart';
import '../../models/staff.dart';
import '../../models/team.dart';
import '../../services/staff_service.dart';
import '../../services/team_service.dart';
import '../../services/auth_service.dart';
import 'package:provider/provider.dart';

class CreateStaffScreen extends StatefulWidget {
  final Staff? staff;
  const CreateStaffScreen({Key? key, this.staff}) : super(key: key);

  @override
  State<CreateStaffScreen> createState() => _CreateStaffScreenState();
}

class _CreateStaffScreenState extends State<CreateStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  late final StaffService _staffService;
  late final TeamService _teamService;

  StaffRole _selectedRole = StaffRole.assistantCoach;
  String? _selectedTeamId;
  List<Team> _teams = [];
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _staffService = StaffService(apiClient: authService.apiClient);
    _teamService = TeamService(apiClient: authService.apiClient);
    
    if (widget.staff != null) {
      _nameController.text = widget.staff!.name;
      _emailController.text = widget.staff!.email ?? '';
      _selectedRole = widget.staff!.role ?? StaffRole.assistantCoach;
      _selectedTeamId = widget.staff!.teamId;
    }
    
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = authService.token;

      if (token == null) return;

      final teams = await _teamService.getTeams();
      setState(() {
        _teams = teams;
        if (teams.isNotEmpty) {
          _selectedTeamId = teams.first.id;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading teams: $e')),
        );
      }
    }
  }

  Future<void> _createStaff() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTeamId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a team')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = authService.token;

      if (token == null) {
        throw Exception('No authentication token');
      }

      if (widget.staff == null) {
        // Create Mode
        final request = StaffCreateRequest(
          teamId: _selectedTeamId!,
          name: _nameController.text.trim(),
          role: _selectedRole,
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        await _staffService.createStaffWithAccount(request);
      } else {
        // Edit Mode
        final updatedStaff = Staff(
          id: widget.staff!.id,
          teamId: _selectedTeamId!,
          name: _nameController.text.trim(),
          role: _selectedRole,
          email: _emailController.text.trim(),
          userId: widget.staff!.userId,
        );
        await _staffService.updateStaff(widget.staff!.id, updatedStaff);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.staff == null ? 'Staff member created successfully' : 'Staff member updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.staff == null ? 'Add Staff Member' : 'Edit Staff Member'),
      ),
      body: _teams.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password Field (only for new accounts)
                    if (widget.staff == null) ...[
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                          ),
                        ),
                        obscureText: _obscurePassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Team Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedTeamId,
                      decoration: const InputDecoration(
                        labelText: 'Team',
                        prefixIcon: Icon(Icons.groups),
                        border: OutlineInputBorder(),
                      ),
                      items: _teams.map((team) {
                        return DropdownMenuItem(
                          value: team.id,
                          child: Text(team.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedTeamId = value);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Role Dropdown
                    DropdownButtonFormField<StaffRole>(
                      value: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Job Role',
                        prefixIcon: Icon(Icons.work),
                        border: OutlineInputBorder(),
                      ),
                      items: StaffRole.values.map((role) {
                        return DropdownMenuItem(
                          value: role,
                          child: Text(role.displayName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedRole = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    const SizedBox(height: 24),

                    // Create Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _createStaff,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              widget.staff == null ? 'Create Staff Account' : 'Save Changes',
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

}
