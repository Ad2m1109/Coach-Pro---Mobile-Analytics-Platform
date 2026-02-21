import 'package:flutter/material.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/models/team.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/team_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class AccountAndTeamScreen extends StatefulWidget {
  const AccountAndTeamScreen({super.key});

  @override
  State<AccountAndTeamScreen> createState() => _AccountAndTeamScreenState();
}

class _AccountAndTeamScreenState extends State<AccountAndTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  late Future<Team?> _teamFuture;
  Team? _currentTeam;

  final TextEditingController _teamNameController = TextEditingController();
  final TextEditingController _primaryColorController = TextEditingController();
  final TextEditingController _secondaryColorController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTeam();
  }

  void _loadTeam() {
    final teamService = Provider.of<TeamService>(context, listen: false);
    _teamFuture = teamService.getTeams().then((teams) {
      if (teams.isNotEmpty) {
        _currentTeam = teams.first;
        _populateControllers(_currentTeam!);
        return _currentTeam;
      }
      return null;
    });
    setState(() {});
  }

  void _populateControllers(Team team) {
    _teamNameController.text = team.name;
    _primaryColorController.text = team.primaryColor ?? '#0000FF';
    _secondaryColorController.text = team.secondaryColor ?? '#FFFFFF';
  }

  @override
  void dispose() {
    _teamNameController.dispose();
    _primaryColorController.dispose();
    _secondaryColorController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadLogo() async {
    final appLocalizations = AppLocalizations.of(context)!;
    if (_currentTeam == null) return;
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      try {
        final teamService = Provider.of<TeamService>(context, listen: false);
        await teamService.uploadTeamLogo(_currentTeam!.id, image);
        _loadTeam(); // Refresh data
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(appLocalizations.logoUpdatedSuccessfully)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${appLocalizations.failedToUploadLogo(e.toString())}')),
        );
      }
    }
  }

  Future<void> _triggerSaveChanges() async {
    final appLocalizations = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate() || _currentTeam == null) return;

    final teamService = Provider.of<TeamService>(context, listen: false);
    final updatedTeamData = Team(
      id: _currentTeam!.id,
      name: _teamNameController.text,
      primaryColor: _primaryColorController.text,
      secondaryColor: _secondaryColorController.text,
      logoUrl: _currentTeam!.logoUrl,
    );

    try {
      final savedTeam = await teamService.updateTeam(_currentTeam!.id, updatedTeamData);
      setState(() {
        _currentTeam = savedTeam;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appLocalizations.changesSavedAutomatically), duration: const Duration(seconds: 2)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${appLocalizations.failedToSaveChanges(e.toString())}')),
      );
    }
  }

  Future<void> _showColorPickerDialog(BuildContext context, {required bool isPrimary}) async {
    final appLocalizations = AppLocalizations.of(context)!;
    final controller = isPrimary ? _primaryColorController : _secondaryColorController;
    Color initialColor;
    try {
      initialColor = Color(int.parse(controller.text.substring(1), radix: 16) + 0xFF000000);
    } catch (e) {
      initialColor = isPrimary ? Colors.blue : Colors.white;
    }

    int tempR = initialColor.red;
    int tempG = initialColor.green;
    int tempB = initialColor.blue;

    final Color? selectedColor = await showDialog<Color>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(appLocalizations.selectAColor),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(tempR, tempG, tempB, 1.0),
                        border: Border.all(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildRGBSlider('R', tempR, (value) => setState(() => tempR = value)),
                    _buildRGBSlider('G', tempG, (value) => setState(() => tempG = value)),
                    _buildRGBSlider('B', tempB, (value) => setState(() => tempB = value)),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(appLocalizations.cancel),
                ),
                TextButton(
                  onPressed: () {
                    final finalColor = Color.fromRGBO(tempR, tempG, tempB, 1.0);
                    Navigator.of(context).pop(finalColor);
                  },
                  child: Text(appLocalizations.select),
                ),
              ],
            );
          },
        );
      },
    );

    if (selectedColor != null) {
      setState(() {
        final hexColor = '#${selectedColor.value.toRadixString(16).substring(2).toUpperCase()}';
        controller.text = hexColor;
      });
      _triggerSaveChanges();
    }
  }

  Widget _buildRGBSlider(String label, int value, ValueChanged<int> onChanged) {
    return Row(
      children: [
        Text(label, style: TextStyle(color: label == 'R' ? Colors.red : (label == 'G' ? Colors.green : Colors.blue))),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: 255,
            divisions: 255,
            label: value.toString(),
            onChanged: (val) => onChanged(val.round()),
          ),
        ),
        Text(value.toString(), style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildColorSelector({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required bool isPrimary,
    required bool canEdit,
  }) {
    final appLocalizations = AppLocalizations.of(context)!;
    Color currentColor;
    try {
      currentColor = Color(int.parse(controller.text.substring(1), radix: 16) + 0xFF000000);
    } catch (e) {
      currentColor = Colors.transparent;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text('$label: ', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(width: 8),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: currentColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(controller.text, style: Theme.of(context).textTheme.bodyLarge),
          ),
          TextButton(
            onPressed: canEdit ? () => _showColorPickerDialog(context, isPrimary: isPrimary) : null,
            child: Text(appLocalizations.change),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final apiClient = Provider.of<ApiClient>(context, listen: false);
    final authService = Provider.of<AuthService>(context);
    final canEditTeam = authService.canManageTeam;

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.teamAndAccount),
      ),
      body: FutureBuilder<Team?>(
        future: _teamFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('${appLocalizations.errorWithMessage(snapshot.error.toString())}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text(appLocalizations.noTeamFoundCreateOne));
          }

          final team = snapshot.data!;
          ImageProvider? backgroundImage;
          final String? logoUrl = team.logoUrl;
          if (logoUrl != null && logoUrl.isNotEmpty) {
            backgroundImage = NetworkImage('${apiClient.baseUrl.replaceAll('/api', '')}$logoUrl');
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 80,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        backgroundImage: backgroundImage,
                        child: backgroundImage == null
                            ? Text(
                                team.name.isNotEmpty ? team.name[0] : '?',
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
                            onPressed: canEditTeam ? _pickAndUploadLogo : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _teamNameController,
                    decoration: InputDecoration(labelText: appLocalizations.teamName),
                    validator: (value) => (value == null || value.isEmpty) ? appLocalizations.pleaseEnterTeamName : null,
                    readOnly: !canEditTeam,
                    onEditingComplete: canEditTeam ? _triggerSaveChanges : null,
                  ),
                  const SizedBox(height: 24),
                  _buildColorSelector(
                    context: context,
                    label: appLocalizations.primaryColor,
                    controller: _primaryColorController,
                    isPrimary: true,
                    canEdit: canEditTeam,
                  ),
                  _buildColorSelector(
                    context: context,
                    label: appLocalizations.secondaryColor,
                    controller: _secondaryColorController,
                    isPrimary: false,
                    canEdit: canEditTeam,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
