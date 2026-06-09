# 🏥 Santé Pocket - Le carnet de santé numérique sécurisé

**Track :** Hackathon  
**Problématique :** Perte, fragilité et défaut de partage sécurisé des données médicales au Togo (Alternative décentralisée "Zéro Cloud").

---

## 📝 Description du Projet
Au Togo, près de 80% des patients perdent leurs dossiers médicaux en raison de la fragilité du format papier. **Santé Pocket** résout ce problème en proposant une solution de carnet de santé numérique décentralisée et ultra-sécurisée. L'application permet un partage instantané des antécédents médicaux entre le patient (sur mobile Android) et le médecin (sur terminal Windows Desktop) via un réseau Pair-à-Pair (P2P) local, sans nécessiter aucune connexion Internet (**Zéro Cloud**).

---

## 👥 L'Équipe (TecBrain)
* **AKATA Odayétobi Exaucé** : Chef de projet & Architecture Flutter
* **HALOUBIYOU Beni Essowazouna** : UI/UX Design & Version Mobile
* **DJIGBANI Achille Moni** : Sécurité & Chiffrement AES-256
* **ABALO Ganiatou Celia** : Version Desktop & Base de données

---

## 🔒 Sécurité du PoC (Proof of Concept)
* **Chiffrement local :** Base de données locale chiffrée avec **SQLCipher**.
* **Chiffrement des flux :** Algorithme **AES-256-GCM** avec dérivation de clé **PBKDF2** pour les transferts de fichiers.
* **Souveraineté :** Le patient reste le seul détenteur et maître de sa clé de déchiffrement.

---

## 💻 Prérequis du Système
* **Framework :** Flutter (Version stable 3.x ou supérieure)
* **Langage :** Dart
* **Cibles :** Android (SDK 21+) / Windows (10/11)
* **Outils requis :** Android Studio ou VS Code, Flutter SDK installé.

---

## 🚀 Installation et Lancement

### 1. Cloner le projet
```bash
git clone [https://github.com/extaodex/TCCHackDefend2026_TecBrain.git](https://github.com/extaodex/TCCHackDefend2026_TecBrain.git)
cd TCCHackDefend2026_TecBrain