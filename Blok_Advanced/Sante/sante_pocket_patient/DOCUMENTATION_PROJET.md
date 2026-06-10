# Documentation du Projet : Santé Pocket

Ce document récapitule l'ensemble des fonctionnalités implémentées, l'architecture technique et les mesures de sécurité mises en place pour l'écosystème **Santé Pocket** (Mobile & PC).

---

## 📱 Application Mobile (Patient)

**Santé Pocket** est un carnet de santé numérique sécurisé. L'application permet aux utilisateurs de centraliser leurs informations médicales et de les partager de manière sécurisée.

### 🚀 Fonctionnalités Implémentées
- **Identité & Onboarding :** Parcours de création de profil avec constantes physiques et photo.
- **Module Urgences :** Gestion des allergies critiques et import de contacts de secours avec fonction d'appel.
- **Documents :** Scanner de documents avec conversion PDF et stockage local.
- **Vaccinations :** Suivi des dates avec **rappels automatiques par notifications locales**.
- **Historique Médical :** Suivi des consultations, diagnostics et ordonnances.

### 🔒 Sécurité & Confidentialité
- **Chiffrement DB :** Base SQLite chiffrée avec une **clé unique UUID v4** générée par appareil.
- **Biométrie :** Verrouillage par Empreinte digitale ou FaceID (local_auth).
- **Local-first :** Aucune donnée de santé ne transite par un serveur cloud.

---

## 💻 Terminal Médecin (PC / Desktop)

Le terminal PC est l'outil professionnel permettant au médecin de réceptionner et d'analyser le dossier du patient instantanément.

### 🚀 Fonctionnalités du Terminal
- **Tableau de Bord :** Statistiques de la journée (patients reçus, alertes critiques).
- **Réception P2P :** Terminal d'écoute automatique qui détecte le mobile du patient sur le réseau local.
- **Dossier Clinique Consolidé :**
    - **Extraction Automatique :** Le terminal décompresse les archives `.msh` et extrait physiquement les PDFs et la photo de profil dans des dossiers locaux.
    - **Visualisation PDF :** Ouverture directe des examens joints via le lecteur par défaut du PC.
    - **Historique Complet :** Navigation par onglets dans les anciennes consultations et le carnet de vaccination du patient.
    - **Journal des Symptômes :** Affichage des dernières notes de santé déclarées par le patient.
- **Gestion des Rapports :** Édition de rapports médicaux sauvegardés dans la base de données locale du médecin.

---

## 📡 Échange de Données (Protocole P2P)

### Format d'Archive `.msh` (v1.1.0)
Archive ZIP sécurisée contenant :
- `dossier_clinique.json` : Données structurées (SQL export).
- `/documents/` : Tous les PDFs d'examens et ordonnances.
- `/profile/` : Photo de profil du patient.

### Transfert Réseau
- **Découverte :** UDP Broadcast sur le réseau WiFi local.
- **Transport TCP :** Flux binaire compressé (zlib) avec vérification d'intégrité par **CRC32**.
- **Robustesse Android :** Système de secours (Copy-Delete) pour garantir le transfert même entre partitions système différentes.

---

## 🛠 Structure du Projet (Mono-repo)
- `sante_pocket/` : Code source de l'application mobile (Patient).
- `desktop_terminal/` : Code source de l'application desktop (Médecin).
- **Partage de code :** Le terminal PC utilise l'application mobile comme dépendance pour garantir une compatibilité parfaite des modèles de données.

---
*Projet Santé Pocket - Version Finalisée 1.1.0*
