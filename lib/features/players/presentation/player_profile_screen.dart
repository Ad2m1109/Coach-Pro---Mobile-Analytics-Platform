import 'package:flutter/material.dart';
import 'package:frontend/features/players/presentation/player_details_view.dart';
import 'package:frontend/features/players/presentation/player_statistics_view.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/models/player.dart';
import 'package:frontend/models/player_match_statistics.dart';
import 'package:frontend/services/player_match_statistics_service.dart';
import 'package:frontend/services/player_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class PlayerProfileScreen extends StatefulWidget {
  final Player player;

  const PlayerProfileScreen({super.key, required this.player});

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen> with SingleTickerProviderStateMixin {
  late Future<List<PlayerMatchStatistics>> _playerStatsHistoryFuture;
  late TabController _tabController;
  late Player _player;
  bool _profileWasUpdated = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _player = widget.player;
    _playerStatsHistoryFuture = Provider.of<PlayerMatchStatisticsService>(context, listen: false)
        .getPlayerMatchStatisticsByPlayerId(widget.player.id);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final appLocalizations = AppLocalizations.of(context)!;
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      try {
        final playerService = Provider.of<PlayerService>(context, listen: false);
        final savedPlayer = await playerService.uploadPlayerImage(_player.id, image);

        setState(() {
          _player = savedPlayer;
          _profileWasUpdated = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(appLocalizations.imageUpdatedSuccessfully)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${appLocalizations.failedToUploadImage(e.toString())}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_profileWasUpdated);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop(_profileWasUpdated);
            },
          ),
          title: Text(_player.name),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          bottom: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: appLocalizations.details),
              Tab(text: appLocalizations.statistics),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Details Tab
            PlayerDetailsView(player: _player, onEditImage: _pickAndUploadImage),

            // Statistics Tab
            FutureBuilder<List<PlayerMatchStatistics>>(
              future: _playerStatsHistoryFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text(appLocalizations.noMatchStatsFoundForPlayer));
                }
                return PlayerStatisticsView(statsHistory: snapshot.data!);
              },
            ),
          ],
        ),
      ),
    );
  }
}
