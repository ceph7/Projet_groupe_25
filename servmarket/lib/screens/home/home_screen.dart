import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/search_provider.dart';
import '../auth/auth_screen.dart';
import '../list/list_screen.dart';
import '../map/map_screen.dart';
import '../provider_home/provider_home_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        if (!auth.isAuthenticated) {
          return const AuthScreen();
        }

        // Redirection selon le rôle de l'utilisateur
        if (auth.user?.role == UserRole.provider) {
          return const ProviderHomeScreen();
        }

        // Interface pour les utilisateurs (clients)
        final screens = [
          const ListScreen(),
          const MapScreen(),
        ];

        return Scaffold(
          appBar: AppBar(
            title: const Text('ServMarket'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => auth.logout(),
                tooltip: 'Déconnexion',
              ),
            ],
          ),
          body: IndexedStack(
            index: _selectedIndex,
            children: screens,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.list_alt_rounded),
                label: 'Liste',
              ),
              NavigationDestination(
                icon: Icon(Icons.map_rounded),
                label: 'Carte',
              ),
            ],
          ),
        );
      },
    );
  }
}
