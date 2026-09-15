import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/search_provider.dart';
import '../../widgets/app_logo.dart';
import '../auth/auth_screen.dart';
import '../client_requests/client_requests_screen.dart';
import '../list/list_screen.dart';
import '../map/map_screen.dart';
import '../messaging/conversations_screen.dart';
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
          const ClientRequestsScreen(),
          const ConversationsScreen(),
        ];

        return Scaffold(
          appBar: AppBar(
            title: const AppLogo(size: 24),
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
              NavigationDestination(
                icon: Icon(Icons.inbox_rounded),
                label: 'Mes demandes',
              ),
              NavigationDestination(
                icon: Icon(Icons.message_rounded),
                label: 'Messages',
              ),
            ],
          ),
        );
      },
    );
  }
}
