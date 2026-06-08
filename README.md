# 🏥 Santé Pocket • Écosystème Médical P2P

**Santé Pocket** est une solution de carnet de santé numérique sécurisée et décentralisée, conçue pour faciliter le partage d'informations critiques entre patients et médecins sans aucune dépendance au Cloud ou à une connexion internet.

L'écosystème se compose de deux applications distinctes partageant une identité visuelle commune propulsée par le moteur de **Tec.Brain**, garantissant une confidentialité totale grâce à un transfert de données en réseau local (P2P).

---

## 🚀 État du Projet : v1.0 (Core Features Complete)
L'ensemble des fonctionnalités critiques pour le flux patient-médecin sont désormais implémentées et opérationnelles.

### 📱 Santé Pocket (Version Patient • Mobile)
*   **Onboarding Fluide** : Parcours d'accueil pour configurer son profil.
*   **Identité Médicale** : Gestion complète de l'identité, groupe sanguin, allergies et antécédents.
*   **Portefeuille de Documents** : Centralisation des vaccins, ordonnances et résultats.
*   **Journal de Santé** : Suivi rigoureux des symptômes et de l'évolution de l'état.
*   **Synchronisation P2P** : Transfert instantané du dossier via **Nearby Connections** (Bluetooth/Wi-Fi Direct) avec sécurisation par QR Code.

### 💻 Terminal Médecin (Version Desktop • PC)
*   **Dashboard Dynamique** : Vue d'ensemble en temps réel des consultations du jour et statistiques globales.
*   **Réception Sécurisée** : Hub de connexion pour recevoir les dossiers patients sans contact physique.
*   **Consultation Optimisée** : Interface "Snapshot" pour une lecture immédiate des points critiques (Allergies, Alertes).
*   **Rapports Médicaux** : Édition de notes de consultation, archivage et sauvegarde locale.
*   **Export & Impression** : Génération de rapports **PDF** professionnels prêts pour l'impression.
*   **Gestion de Confidentialité** : Outils de purge définitive des données patients après consultation.

---

## 🛡️ Sécurité & Architecture "Zéro Cloud"
La protection des données de santé est régie par trois piliers :
1.  **Chiffrement de bout en bout** : Utilisation de l'algorithme **AES-256** pour le transit des données.
2.  **Stockage Local Chiffré** : Base de données **SQLCipher** (SQLite avec chiffrement au repos) sur les deux plateformes.
3.  **Local Only** : Aucune donnée ne quitte le périmètre physique du cabinet médical.

---

## 🎨 Design System : "Modern Medical"
Une identité visuelle unifiée développée pour la clarté et la réduction de la charge cognitive :
- **Identifiants Visuels** : **P** pour l'application Patient, **D** pour le Terminal Docteur.
- **Palette** : Sarcelle Médicale (`#00695C`) et Blanc Cassé (`#F8FAFC`).
- **Composants** : Design basé sur Material 3 avec des coins arrondis (24px) et des animations fluides via `flutter_animate`.

---

## 🛠️ Structure & Compilation

### Arborescence
```text
Sante/
├── sante_pocket/      # Application Mobile Flutter (Android/iOS)
└── desktop_terminal/  # Application Desktop Flutter (Windows/macOS)
```

### Prérequis
- Flutter SDK (dernière version stable)
- Java 17+ (pour Android)
- C++ Build Tools (pour Windows Desktop)

### Guide de démarrage
1.  **Dépendances** : Exécuter `flutter pub get` dans chaque répertoire.
2.  **Exécution** :
    - Mobile : `cd Sante/sante_pocket && flutter run`
    - Desktop : `cd Sante/desktop_terminal && flutter run -d windows`
3.  **Compilation** :
    - Mobile APK : `flutter build apk --release`
    - PC Windows : `flutter build windows --release`

---

## 📝 Licence
Ce projet est développé dans le cadre d'un système de santé numérique moderne.

---

## 🔗 Ressources & Support
- **Builds Prêts à l'emploi** : Voir dossier `Sante_Medecin_PC` pour l'exécutable Windows.
- **Documentation Étendue** : `Sante/desktop_terminal/docs/plan_complet.md`
- **Google Drive** : [Accéder aux ressources graphiques](https://drive.google.com/drive/folders/15yCsbDM8-1F5lBCqYGjGUD29nH64234T?usp=sharing)
- **Contact** : Développé avec ❤️ par **Tec.Brain**.

---
*Ce projet respecte les principes de souveraineté numérique et de protection des données sensibles.*
