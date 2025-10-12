import 'package:flutter/material.dart';
import 'package:frontend/features/strategie/presentation/add_reunion_screen.dart';
import 'package:frontend/features/strategie/presentation/add_training_session_screen.dart';
import 'package:frontend/features/strategie/presentation/reunions_screen.dart';
import 'package:frontend/features/strategie/presentation/training_screen.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:frontend/l10n/app_localizations.dart'; // New import

class StrategieScreen extends StatefulWidget {
  const StrategieScreen({super.key});

  @override
  State<StrategieScreen> createState() => _StrategieScreenState();
}

class _StrategieScreenState extends State<StrategieScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Key _trainingKey = UniqueKey();
  Key _reunionsKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // Changed length to 2
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _navigateAndRefresh() async {
    Widget? screenToPush;
    switch (_tabController.index) {
      case 0:
        screenToPush = const AddTrainingSessionScreen();
        break;
      case 1:
        screenToPush = const AddReunionScreen();
        break;
    }

    if (screenToPush != null) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => screenToPush!),
      );

      if (result == true) {
        setState(() {
          // Regenerate keys to force child widgets to rebuild and re-fetch data
          _trainingKey = UniqueKey();
          _reunionsKey = UniqueKey();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('StrategieScreen built'); // Debug print
    final authService = Provider.of<AuthService>(context);
    final appLocalizations = AppLocalizations.of(context)!;
    final userEmail = authService.currentUser?.email ?? appLocalizations.guest;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(appLocalizations.strategie),
            Text('${appLocalizations.loggedInAs} $userEmail', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: appLocalizations.training),
            Tab(text: appLocalizations.reunions),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          TrainingScreen(key: _trainingKey),
          ReunionsScreen(key: _reunionsKey),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateAndRefresh,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
