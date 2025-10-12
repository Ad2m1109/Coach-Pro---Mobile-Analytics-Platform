import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/team_service.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/models/team.dart';
import 'package:frontend/services/api_client.dart';
import 'package:image_picker/image_picker.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late Future<Map<String, dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchData();
  }

  Future<Map<String, dynamic>> _fetchData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final teamService = Provider.of<TeamService>(context, listen: false);
    
    final user = authService.currentUser;
    if (user == null) {
      throw Exception("User not found");
    }
    
    final teams = await teamService.getTeams();
    final team = teams.isNotEmpty ? teams.first : null;

    return {'user': user, 'team': team};
  }

  Future<void> _pickAndUploadLogo(Team currentTeam) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      try {
        final teamService = Provider.of<TeamService>(context, listen: false);
        await teamService.uploadTeamLogo(currentTeam.id, image);
        // Refresh the data
        setState(() {
          _dataFuture = _fetchData();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logo updated successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload logo: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final apiClient = Provider.of<ApiClient>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No data found. Please ensure you are logged in.'));
          }

          final User user = snapshot.data!['user'];
          final Team? team = snapshot.data!['team'];

          ImageProvider? backgroundImage;
          final String? logoUrl = team?.logoUrl;
          if (logoUrl != null && logoUrl.isNotEmpty) {
            if (logoUrl.startsWith('http')) {
              backgroundImage = NetworkImage(logoUrl);
            } else {
              backgroundImage = NetworkImage('${apiClient.baseUrl.replaceAll('/api', '')}$logoUrl');
            }
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 80,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        backgroundImage: backgroundImage,
                        child: backgroundImage == null
                            ? Text(
                                team?.name.isNotEmpty == true ? team!.name[0] : '?',
                                style: const TextStyle(fontSize: 60, color: Colors.white),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: Theme.of(context).cardColor,
                          child: IconButton(
                            icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary, size: 20),
                            onPressed: () {
                              if (team != null) {
                                _pickAndUploadLogo(team);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Create a team first to add a logo.')),
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  color: Theme.of(context).cardColor,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.group, color: Colors.white70),
                        title: Text('Team Name', style: Theme.of(context).textTheme.bodyLarge),
                        subtitle: Text(team?.name ?? 'No team found', style: Theme.of(context).textTheme.bodyMedium),
                      ),
                      const Divider(indent: 16, endIndent: 16),
                      ListTile(
                        leading: const Icon(Icons.email, color: Colors.white70),
                        title: Text('Email', style: Theme.of(context).textTheme.bodyLarge),
                        subtitle: Text(user.email, style: Theme.of(context).textTheme.bodyMedium),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Account Settings',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(height: 16),
                Card(
                  color: Theme.of(context).cardColor,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.lock, color: Colors.white70),
                        title: Text('Change Password', style: Theme.of(context).textTheme.bodyLarge),
                        trailing: Icon(Icons.arrow_forward_ios, color: Theme.of(context).colorScheme.secondary),
                        onTap: () {
                          // TODO: Navigate to change password screen
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
