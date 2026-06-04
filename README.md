# Santé Pocket

Santé Pocket est une application mobile de gestion de santé personnelle. Elle permet de stocker, consulter et synchroniser vos informations médicales en toute sécurité.

## Fonctionnalités Principales

- **Dashboard :** Vue d'ensemble de votre santé.
- **Identité :** Gestion de vos informations personnelles.
- **Urgences :** Accès rapide aux informations vitales et contacts d'urgence.
- **Documents Médicaux :** Gestion de vos ordonnances, comptes-rendus, etc.
- **Vaccinations :** Suivi de votre carnet de vaccination.
- **Symptômes :** Journal de suivi de vos symptômes.
- **Synchronisation :** Transfert sécurisé de vos données (P2P).

## Installation et Utilisation

### Prérequis
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installé.
- Un émulateur ou un appareil physique configuré.

### Lancement
1. Clonez ce dépôt : `git clone https://github.com/extaodex/Sante_Pocket.git`
2. Accédez au répertoire de l'application principale : `cd sante_pocket`
3. Installez les dépendances : `flutter pub get`
4. Lancez l'application : `flutter run`

## Architecture
L'application utilise :
- **Riverpod** pour la gestion d'état.
- **GoRouter** pour la navigation.
- **Localisation** (Français par défaut).
