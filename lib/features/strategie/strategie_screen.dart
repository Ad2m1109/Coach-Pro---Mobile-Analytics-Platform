import 'package:flutter/material.dart';
import 'package:frontend/features/strategie/presentation/add_reunion_screen.dart';
import 'package:frontend/features/strategie/presentation/add_training_session_screen.dart';
import 'package:frontend/features/strategie/presentation/reunions_screen.dart';
import 'package:frontend/features/strategie/presentation/training_screen.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:frontend/l10n/app_localizations.dart'; // New import

import 'package:frontend/core/design_system/app_spacing.dart';

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
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
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
          _trainingKey = UniqueKey();
          _reunionsKey = UniqueKey();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final appLocalizations = AppLocalizations.of(context)!;
    final userEmail = authService.currentUser?.email ?? appLocalizations.guest;
    final canAddTraining = authService.hasPermission('edit');
    final canAddReunions = authService.canManageReunions;
    final canShowFab = _tabController.index == 0 ? canAddTraining : canAddReunions;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(appLocalizations.strategie),
            Text(
              '${appLocalizations.loggedInAs} $userEmail',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
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
      floatingActionButton: canShowFab
          ? FloatingActionButton(
              onPressed: _navigateAndRefresh,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
