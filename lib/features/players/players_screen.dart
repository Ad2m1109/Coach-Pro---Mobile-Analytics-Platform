import 'package:flutter/material.dart';
import 'package:frontend/features/players/presentation/add_player_screen.dart';
import 'package:frontend/features/players/presentation/player_profile_screen.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/models/player.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/player_service.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:provider/provider.dart';

import 'package:frontend/widgets/custom_card.dart';
import 'package:frontend/core/design_system/app_spacing.dart';

enum PlayerSortOption { name, jerseyNumber, marketValue, position }

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  late Future<List<Player>> _playersFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  PlayerSortOption _selectedSortOption = PlayerSortOption.name;
  List<Player> _allPlayers = [];

  @override
  void initState() {
    super.initState();
    _loadPlayers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _loadPlayers() {
    final playerService = Provider.of<PlayerService>(context, listen: false);
    setState(() {
      _playersFuture = playerService.getPlayers().then((players) {
        _allPlayers = players;
        return _filterAndSortPlayers(players);
      });
    });
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  String _getSortOptionName(PlayerSortOption option, AppLocalizations localizations) {
    switch (option) {
      case PlayerSortOption.name:
        return localizations.name;
      case PlayerSortOption.jerseyNumber:
        return localizations.jerseyNumber;
      case PlayerSortOption.marketValue:
        return localizations.marketValue;
      case PlayerSortOption.position:
        return localizations.position;
    }
  }

  List<Player> _filterAndSortPlayers(List<Player> players) {
    List<Player> filteredPlayers = players.where((player) {
      return player.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    filteredPlayers.sort((a, b) {
      switch (_selectedSortOption) {
        case PlayerSortOption.jerseyNumber:
          return (a.jerseyNumber ?? 999).compareTo(b.jerseyNumber ?? 999);
        case PlayerSortOption.marketValue:
          return (b.marketValue ?? 0.0).compareTo(a.marketValue ?? 0.0);
        case PlayerSortOption.position:
          final positionOrder = {'FWD': 0, 'MID': 1, 'DEF': 2, 'GK': 3};
          final posA = positionOrder[a.position ?? ''] ?? 99;
          final posB = positionOrder[b.position ?? ''] ?? 99;
          return posA.compareTo(posB);
        case PlayerSortOption.name:
        default:
          return a.name.compareTo(b.name);
      }
    });
    return filteredPlayers;
  }

  void _navigateAndRefresh() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddPlayerScreen()),
    );

    if (result == true) {
      _loadPlayers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final apiClient = Provider.of<ApiClient>(context, listen: false);
    final authService = Provider.of<AuthService>(context);
    final canEdit = authService.canManagePlayers;

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.players),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s, vertical: AppSpacing.s),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: appLocalizations.search,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.s, horizontal: AppSpacing.s),
                    ),
                    style: const TextStyle(fontSize: 14.0),
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  flex: 4,
                  child: DropdownButtonFormField<PlayerSortOption>(
                    value: _selectedSortOption,
                    decoration: InputDecoration(
                      labelText: appLocalizations.sort,
                      contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.s, horizontal: AppSpacing.s),
                    ),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14.0),
                    dropdownColor: Theme.of(context).cardTheme.color,
                    items: PlayerSortOption.values.map((option) {
                      return DropdownMenuItem<PlayerSortOption>(
                        value: option,
                        child: Text(
                          _getSortOptionName(option, appLocalizations),
                          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                        ),
                      );
                    }).toList(),
                    onChanged: (PlayerSortOption? newValue) {
                      setState(() {
                        _selectedSortOption = newValue!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<Player>>(
        future: _playersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text(appLocalizations.noPlayersFound));
          }

          final filteredAndSortedPlayers = _filterAndSortPlayers(_allPlayers);
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
            itemCount: filteredAndSortedPlayers.length,
            itemBuilder: (context, index) {
              final player = filteredAndSortedPlayers[index];
              final String? imageUrl = player.imageUrl;
              ImageProvider? backgroundImage;

              if (imageUrl != null && imageUrl.isNotEmpty && !imageUrl.contains('cdn.example.com')) {
                if (imageUrl.startsWith('http')) {
                  backgroundImage = NetworkImage(imageUrl);
                } else {
                  backgroundImage = NetworkImage('${apiClient.baseUrl.replaceAll('/api', '')}$imageUrl');
                }
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.xs),
                child: CustomCard(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlayerProfileScreen(player: player),
                      ),
                    );
                    if (result == true) {
                      _loadPlayers();
                    }
                  },
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
                    leading: Hero(
                      tag: 'player_${player.id}',
                      child: CircleAvatar(
                        radius: 25,
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        backgroundImage: backgroundImage,
                        child: backgroundImage == null
                            ? Text(
                                player.name.isNotEmpty ? player.name[0] : '?',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              )
                            : null,
                      ),
                    ),
                    title: Text(
                      player.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              player.position ?? appLocalizations.notAvailable,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '#${player.jerseyNumber ?? appLocalizations.notAvailable}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: canEdit ? FloatingActionButton(
        onPressed: _navigateAndRefresh,
        child: const Icon(Icons.add),
      ) : null,
    );
  }
}
