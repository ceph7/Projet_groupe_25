# ServiceFinder

![Flutter](https://img.shields.io/badge/Flutter-3.11+-blue.svg)
![Dart](https://img.shields.io/badge/Dart-2.17+-blue.svg)
![License](https://img.shields.io/badge/License-Educational-green.svg)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Linux-lightgrey.svg)

Application mobile Flutter permettant de trouver des prestataires de services à proximité grâce à la géolocalisation. Les utilisateurs peuvent rechercher des professionnels (plombiers, électriciens, menuisiers, etc.) dans leur secteur, consulter leurs fiches détaillées et les contacter directement par téléphone ou SMS.

## 🎯 Fonctionnalités principales

### Pour les utilisateurs
- **Recherche géolocalisée** : Trouve automatiquement les prestataires autour de votre position
- **Recherche manuelle** : Saisissez une ville ou une adresse pour rechercher dans une zone spécifique
- **Filtres avancés** : Filtrez par catégorie de service et ajustez le rayon de recherche (1-50 km)
- **Affichage double** : Consultez les résultats sous forme de liste ou sur carte interactive
- **Fiches détaillées** : Accédez aux informations complètes des prestataires (description, adresse, distance)
- **Contact direct** : Appelez ou envoyez un SMS en un clic

### Pour les prestataires
- **Création de fiche** : Créez votre profil professionnel avec photo, description et coordonnées
- **Gestion de visibilité** : Activez ou désactivez votre fiche selon votre disponibilité
- **Modification** : Mettez à jour vos informations à tout moment

### Messagerie temps réel
- **Conversations individuelles** : Échangez directement avec les prestataires
- **Synchronisation temps réel** : Les messages apparaissent instantanément
- **Indicateur de non lus** : Badge sur les conversations avec nouveaux messages
- **Interface intuitive** : Bulles de message, horodatage, états de chargement

### Caractéristiques techniques
- **Authentification sécurisée** : Inscription/connexion via Firebase Authentication
- **Géolocalisation précise** : Recherche par géohash + filtrage distance réelle (Haversine)
- **Interface responsive** : Optimisée pour téléphone et tablette
- **Carte interactive** : Affichage des prestataires sur carte avec flutter_map + OpenStreetMap
- **Mode démo** : Positions GPS simulées pour les démonstrations

## 🛠 Stack technique

### Frontend
- **Framework** : Flutter (Dart)
- **Gestion d'état** : Provider
- **UI** : Material Design avec Google Fonts

### Backend & Services
- **Authentification** : Firebase Authentication (Email/Password)
- **Base de données** : Cloud Firestore
- **Stockage** : Firebase Storage (photos des prestataires)
- **Géolocalisation** : Geolocator, Geocoding
- **Cartes** : flutter_map avec OpenStreetMap
- **Contact** : url_launcher (tel:, sms:)

### Dépendances principales
```yaml
firebase_core: ^4.14.0
cloud_firestore: ^6.9.0
firebase_auth: ^6.6.1
firebase_storage: ^13.5.0
provider: ^6.1.2
geolocator: ^14.0.3
geocoding: ^3.0.0
latlong2: ^0.9.1
flutter_map: ^7.0.2
url_launcher: ^6.3.1
image_picker: ^1.1.2
```

## 📚 Documentation

- [CHANGELOG.md](../CHANGELOG.md) - Historique des versions et changements
- [CONTRIBUTING.md](../CONTRIBUTING.md) - Guide pour contribuer au projet
- [FIRESTORE_ISSUES.md](../FIRESTORE_ISSUES.md) - Problèmes Firestore connus et solutions

## 📦 Installation

### Prérequis
- Flutter SDK (>= 3.11.0)
- Android Studio / Xcode
- Un compte Firebase

### Étapes d'installation

1. **Cloner le dépôt**
```bash
git clone <repository-url>
cd servmarket
```

2. **Installer les dépendances**
```bash
flutter pub get
```

3. **Configuration Firebase**
   - Créez un projet Firebase sur [console.firebase.google.com](https://console.firebase.google.com/)
   - Activez Firebase Authentication (Email/Password)
   - Activez Cloud Firestore (mode production)
   - Activez Firebase Storage
   - Ajoutez l'app Android et/ou iOS avec les bons bundle identifiers
   - Téléchargez les fichiers de configuration :
     - `google-services.json` → `android/app/`
     - `GoogleService-Info.plist` → `ios/Runner/`
   - **IMPORTANT** : Ces fichiers sont déjà dans `.gitignore`, ne les commitez jamais

4. **Déployer les règles de sécurité**
```bash
firebase deploy --only firestore:rules
```
   Les règles sont définies dans `firestore.rules`

5. **Lancer l'application**
```bash
# Android
flutter run

# iOS
flutter run -d ios

# Web (si supporté)
flutter run -d chrome
```

## 🏗 Architecture du projet

```
lib/
├── core/              # Thème, constantes, configuration
├── models/            # Modèles de données (UserProfile, ProviderProfile, etc.)
├── services/          # Services métier (auth, geolocation, firestore, contact)
├── repositories/      # Accès aux données (isole les requêtes Firestore)
├── providers/         # Gestion d'état (Provider pattern)
├── screens/           # Écrans de l'application
├── widgets/           # Composants réutilisables
└── main.dart          # Point d'entrée
```

### Principes d'architecture
- **Séparation des responsabilités** : Services isolés, repositories pour l'accès aux données
- **Pattern Provider** : Gestion d'état réactive et simple
- **Services métier** : Logique métier isolée dans des services dédiés
- **Modèles fortement typés** : Structures de données claires et validées

## 🔒 Sécurité

### Règles Firestore
Les règles de sécurité sont définies dans `firestore.rules` :
- **Lecture publique** : Seules les fiches publiées (`isPublished == true`) sont visibles publiquement
- **Écriture réservée** : Seul le propriétaire (`ownerId == request.auth.uid`) peut modifier sa fiche
- **Protection des utilisateurs** : Chaque utilisateur ne peut lire/écrire que son propre profil
- **Anti-transfert** : Le champ `ownerId` ne peut pas être modifié après création
- **Messagerie sécurisée** : RLS sur conversations et messages (seuls les participants peuvent lire/écrire)

### Protection des secrets
- Tous les fichiers sensibles sont dans `.gitignore`
- `.env.example` documente les variables d'environnement nécessaires
- Aucune clé API n'est hardcodée dans le code

## 📱 Mode démo

Pour les démonstrations, un mode démo permet d'utiliser des positions GPS simulées sans dépendre de la géolocalisation réelle de l'émulateur.

### Activer le mode démo
Dans `lib/services/geolocation_service.dart` :
```dart
static bool demoMode = true;
```

### Positions simulées
Les positions de test sont documentées dans `DEMO_LOCATIONS.md` :
- Paris centre (position utilisateur par défaut)
- 8 prestataires simulés dans un rayon de 5-15 km
- Instructions pour Android Emulator et iOS Simulator

## 👥 Équipe

**Groupe 25** - Projet universitaire ServiceFinder

## 📄 Licence

Ce projet est réalisé dans un cadre universitaire. Tous droits réservés.

## ⚠️ Limites connues

- **Dépendance à Firebase** : L'application nécessite une connexion internet et un projet Firebase actif
- **Géolocalisation** : Sur certains émulateurs, la géolocalisation peut être imprécise (utiliser le mode démo)
- **Cartes** : Utilise OpenStreetMap qui peut avoir des latences selon la connexion
- **iOS** : La configuration iOS nécessite un Mac avec Xcode

## 🧪 Tests

```bash
# Lancer tous les tests
flutter test

# Lancer les tests avec couverture de code
flutter test --coverage

# Lancer les tests sur un appareil spécifique
flutter test -d <device-id>
```

## 💻 Développement

```bash
# Analyser le code
flutter analyze

# Formater le code
dart format .

# Nettoyer les fichiers de build
flutter clean

# Obtenir les dépendances
flutter pub get

# Mettre à jour les dépendances
flutter pub upgrade
```

## 🤝 Comment contribuer

Nous encourageons les contributions ! Veuillez consulter le guide [CONTRIBUTING.md](../CONTRIBUTING.md) pour :
- Le processus de développement
- Les standards de code
- Le workflow Git
- Soumettre des Pull Requests
- Signaler des bugs

## 🚀 Pistes d'amélioration

- [x] Messagerie temps réel entre utilisateurs et prestataires (Firestore)
- [ ] Système de notation et avis
- [ ] Disponibilité en temps réel des prestataires
- [ ] Notifications push pour les nouvelles demandes
- [ ] Paiement intégré via l'application
- [ ] Historique des recherches
- [ ] Favoris de prestataires

## 📞 Support

Pour toute question ou problème :
- Ouvrez une issue sur le dépôt GitHub
- Consultez la documentation dans [CONTRIBUTING.md](../CONTRIBUTING.md)
- Vérifiez les problèmes connus dans [FIRESTORE_ISSUES.md](../FIRESTORE_ISSUES.md)

---

**ServiceFinder** - Projet universitaire Groupe 25 © 2026
