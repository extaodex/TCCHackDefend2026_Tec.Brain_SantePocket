# 🏥 Santé Pocket • Écosystème Médical P2P

Santé Pocket est une solution de carnet de santé numérique sécurisée et décentralisée, conçue pour faciliter le partage d'informations critiques entre patients et médecins, même dans les zones sans connexion internet (Offline-First/Zéro Cloud).

L'écosystème se compose de deux applications distinctes partageant une identité visuelle commune propulsée par le moteur de Tec.Brain, garantissant une confidentialité totale des données médicales.

🚀 État du Projet : v1.0 (Core Features Complete)
L'ensemble des fonctionnalités critiques pour le flux patient-médecin sont désormais implémentées et opérationnelles.

---

## 👥 L'Équipe (TecBrain)
* **AKATA Odayétobi Exaucé** : Chef de projet & Architecture Flutter
* **HALOUBIYOU Beni Essowazouna** : UI/UX Design & Version Mobile
* **DJIGBANI Achille Moni** : Sécurité & Chiffrement AES-256
* **ABALO Ganiatou Celia** : Version Desktop & Base de données

---

## 🛠 Fonctionnalités Implémentées

### 📱 Application Mobile (Patient)
- **Identité & Onboarding :** Gestion du profil, constantes physiques et photo.
- **Urgence :** Allergies critiques, contacts de secours.
- **Documents :** Scanner PDF local, gestion vaccinale, historique médical.

### 💻 Terminal Médecin (PC)
- **Tableau de Bord :** Statistiques temps réel, réception P2P automatique.
- **Gestion de Dossier :** Extraction automatique (.msh), visualisation PDF, édition de rapports, historique complet.

---

## 📡 Architecture Technique
- **Communication :** mDNS (découverte) + TCP (transport sécurisé).
- **Sécurité :** Chiffrement AES-256-GCM, PBKDF2 pour la dérivation de clés, SQLCipher pour les bases locales.
- **Protocole :** Format d'archive `.msh` sécurisé (JSON structuré + documents chiffrés).

---

## 📁 Soumission (Hackathon)
Retrouvez les documents officiels pour le jury dans le dossier `/submission` :
- [Dossier Technique PDF](/submission/TECHNIQUE.pdf)
- [Présentation Pitch PDF](/submission/PRESENTATION.pdf)

---

## 🚀 Installation et Build

### 1. Cloner le projet
```bash
git clone https://github.com/extaodex/TCCHackDefend2026_Tec.Brain_SantePocket.git
cd TCCHackDefend2026_Tec.Brain_SantePocket
```

### 2. Builds de production
**Mobile (Santé Pocket Patient) :**
```bash
cd sante_pocket_patient
flutter pub get
flutter build apk --release
```

**Terminal Médecin (PC) :**
```bash
cd sante_pocket_doctor
flutter pub get
flutter build windows --release
```
