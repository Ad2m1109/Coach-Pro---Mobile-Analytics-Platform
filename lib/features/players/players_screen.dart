import 'package:flutter/material.dart';
import 'package:frontend/features/players/presentation/add_player_screen.dart';
import 'package:frontend/features/players/presentation/player_profile_screen.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/models/player.dart';
import 'package:frontend/services/api_client.dart';
import 'package:frontend/services/player_service.dart';
import 'package:provider/provider.dart';

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
  PlayerSortOption _selectedSortOption = PlayerSortOption.name; // Default sort option
  List<Player> _allPlayers = []; // To hold all players fetched from API

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
        _allPlayers = players; // Store all players
        // Initial sort
        return _filterAndSortPlayers(players);
      });
    });
  }

  void _onSearchChanged() {
    setState(() {
      // This will trigger a rebuild, which will call _filterAndSortPlayers
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

    // Sort players
    filteredPlayers.sort((a, b) {
      switch (_selectedSortOption) {
        case PlayerSortOption.jerseyNumber:
          return (a.jerseyNumber ?? 999).compareTo(b.jerseyNumber ?? 999);
        case PlayerSortOption.marketValue:
          return (b.marketValue ?? 0.0).compareTo(a.marketValue ?? 0.0); // Descending
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

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.players),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: appLocalizations.search, // Shorter label
                      labelStyle: const TextStyle(color: Colors.black), // Label text color
                      prefixIcon: const Icon(Icons.search, size: 20, color: Colors.black), // Smaller icon, black color
                      border: const OutlineInputBorder(),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0), // Smaller padding
                    ),
                    style: const TextStyle(fontSize: 14.0, color: Colors.black),
                  ),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<PlayerSortOption>(
                    value: _selectedSortOption,
                    decoration: InputDecoration(
                      labelText: appLocalizations.sort,
                      labelStyle: const TextStyle(color: Colors.black),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
                    ),
                    style: const TextStyle(fontSize: 14.0, color: Colors.black),
                    dropdownColor: Theme.of(context).cardColor,
                    items: PlayerSortOption.values.map((option) {
                      return DropdownMenuItem<PlayerSortOption>(
                        value: option,
                        child: Text(_getSortOptionName(option, appLocalizations), style: const TextStyle(fontSize: 14.0, color: Colors.black)),
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

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Theme.of(context).cardColor,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    backgroundImage: backgroundImage,
                    child: backgroundImage == null
                        ? Text(player.name.isNotEmpty ? player.name[0] : '?',
                            style: const TextStyle(color: Colors.white))
                        : null,
                  ),
                  title: Text(player.name,
                      style: Theme.of(context).textTheme.titleLarge),
                  subtitle: Text(
                    '${player.position ?? appLocalizations.notAvailable} - #${player.jerseyNumber ?? appLocalizations.notAvailable}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  trailing: Icon(Icons.arrow_forward_ios,
                      color: Theme.of(context).colorScheme.secondary),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PlayerProfileScreen(player: player),
                      ),
                    );
                    if (result == true) {
                      _loadPlayers();
                    }
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateAndRefresh,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
