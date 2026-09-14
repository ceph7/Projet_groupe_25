import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/provider_profile.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/app_logo.dart';
import '../provider_form/provider_form_screen.dart';
import '../provider_detail/provider_detail_screen.dart';
import '../provider_requests/provider_requests_screen.dart';

class ProviderHomeScreen extends StatefulWidget {
  const ProviderHomeScreen({super.key});

  @override
  State<ProviderHomeScreen> createState() => _ProviderHomeScreenState();
}

class _ProviderHomeScreenState extends State<ProviderHomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        final screens = [
          const ProviderDashboardScreen(),
          const ProviderRequestsScreen(),
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
                icon: Icon(Icons.dashboard_rounded),
                label: 'Tableau de bord',
              ),
              NavigationDestination(
                icon: Icon(Icons.message_rounded),
                label: 'Demandes',
              ),
            ],
          ),
        );
      },
    );
  }
}

class ProviderDashboardScreen extends StatelessWidget {
  const ProviderDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        return FutureBuilder<List<ProviderProfile>>(
          future: FirestoreService.instance.getProvidersByOwner(auth.user!.uid),
          builder: (context, snapshot) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bienvenue, ${auth.user?.displayName ?? 'Prestataire'}',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          auth.user?.email ?? '',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(
                      snapshot.hasData && snapshot.data!.isNotEmpty
                          ? 'Gérer mon profil'
                          : 'Créer mon profil',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    subtitle: Text(
                      snapshot.hasData && snapshot.data!.isNotEmpty
                          ? 'Mettre à jour vos informations'
                          : 'Commencer par configurer votre profil',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_outward_rounded, color: AppTheme.primaryColor),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProviderFormScreen(
                            existingProfile: snapshot.hasData && snapshot.data!.isNotEmpty
                                ? snapshot.data!.first
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                if (snapshot.hasData && snapshot.data!.isNotEmpty)
                  Card(
                    child: ListTile(
                      leading: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppTheme.categorySage,
                          shape: BoxShape.circle,
                        ),
                      ),
                      title: Text(
                        'Voir mon profil public',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      subtitle: Text(
                        'Aperçu de ce que voient les clients',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_outward_rounded, color: AppTheme.primaryColor),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProviderDetailScreen(
                              provider: snapshot.data!.first,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
