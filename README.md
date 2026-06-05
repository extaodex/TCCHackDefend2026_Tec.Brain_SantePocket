# 🏥 Santé Pocket

**Santé Pocket** est une solution de carnet de santé numérique sécurisée, conçue pour faciliter le partage d'informations critiques entre les patients et les médecins sans dépendance à une connexion internet.

L'écosystème se compose de deux applications distinctes partageant une identité visuelle commune :
*   **Version Patient (Mobile) • P** : Stockage sécurisé des données de santé personnelles.
*   **Version Médecin (Desktop) • D** : Terminal de réception, consultation et archivage des dossiers patients.

---

## ✨ Fonctionnalités Principales

### 📱 Version Patient (Mobile)
- **Profil Complet** : Identité, groupe sanguin, allergies et antécédents.
- **Documents Numériques** : Gestion des vaccins, ordonnances et résultats d'examens.
- **Suivi des Symptômes** : Journal d'évolution de l'état de santé.
- **Transfert P2P Sécurisé** : Envoi instantané du dossier par QR Code (Wi-Fi Local/Nearby).

### 💻 Version Médecin (Terminal PC)
- **Tableau de Bord Moderne** : Interface "Modern Medical" fluide avec statistiques journalières.
- **Réception Automatique** : Récupération et déchiffrement immédiat des données patient.
- **Archivage Sécurisé** : Stockage local chiffré via **SQLCipher** (Base de données SQLite).
- **Export Médical** : Génération de rapports **PDF** professionnels et impression en un clic.
- **Gestion d'Historique** : Recherche et consultation des anciens dossiers reçus.

---

## 🛡️ Sécurité & Confidentialité
La protection des données de santé est au cœur du projet :
- **Chiffrement AES-256** : Toutes les données transférées et stockées sont chiffrées.
- **Zéro Cloud** : Aucune donnée ne quitte le réseau local du cabinet médical.
- **SQLCipher** : Base de données locale protégée par mot de passe au niveau du fichier.

---

## 🚀 Installation & Utilisation

### Prérequis
- Flutter SDK (dernière version stable)
- Java 17+ (pour Android)
- C++ Build Tools (pour Windows Desktop)

### Structure du Projet
```text
Sante/
├── sante_pocket/          # Code source Application Mobile (Patient)
└── desktop_terminal/     # Code source Application PC (Médecin)
```

### Compilation
1. **Mobile** :
   ```bash
   cd Sante/sante_pocket
   flutter build apk --release
   ```
2. **PC** :
   ```bash
   cd Sante/desktop_terminal
   flutter build windows --release
   ```

---

## 🎨 Design System
L'interface utilise le thème **"Modern Medical"** :
- **Couleur Primaire** : Sarcelle Médicale (`#00695C`)
- **Fonds** : Blanc Cassé Doux (`#F8FAFC`)
- **Composants** : Coins arrondis (24px), ombres douces et animations fluides via `flutter_animate`.

---

## 📝 Licence
Ce projet est développé dans le cadre d'un système de santé numérique moderne.

---
*Développé avec ❤️ par Santé Pocket Team.*
