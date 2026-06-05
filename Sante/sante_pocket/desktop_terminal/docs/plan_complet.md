# Plan Complet : SantePocket - Terminal Médecin (Desktop)

## 1. Vue d'ensemble
Application Flutter Desktop (Windows/macOS) destinée aux médecins pour recevoir, consulter et archiver les données critiques des patients transférées via `NearbyConnections` depuis l'appli mobile.

## 2. Architecture des Modules
- **Module P2P (Connectivity):** Écoute passive pour détecter les patients. Gère la sécurité de la connexion.
- **Module Sécurité (Crypto):** Déchiffrement AES-GCM des paquets entrants.
- **Module Gestion Patient (Local Storage):** Stockage local des dossiers patients (SQLite sécurisé) pour consultation hors-ligne après transfert.
- **Module Interface Médicale (UI):** Dashboard de consultation rapide.

## 3. Fonctionnalités Détaillées
### A. Dashboard de Réception (Hub P2P)
- État du service (Prêt / En attente / Connecté).
- Liste des patients connectés en temps réel.
- Notification visuelle à la réception d'un nouveau transfert.

### B. Interface de Consultation
- **Vue "Snapshot" :** Affichage immédiat des données critiques reçues (Identity, Allergies, Groupe sanguin, Notes).
- **Formatage médical :** Mise en page optimisée pour la lecture sur écran PC (typographie, contraste élevé).
- **Historique :** Accès aux anciens transferts reçus pour le même patient.

### C. Gestion des Données
- **Archivage :** Possibilité de sauvegarder le dossier dans une base locale sécurisée.
- **Exportation :** Génération de rapports PDF lisibles par d'autres logiciels de gestion de cabinet.
- **Purge :** Option pour supprimer définitivement les données d'un patient après la consultation.

## 4. Workflows Utilisateur
1. **Démarrage :** Le médecin lance le Terminal -> Le service de réception s'active.
2. **Transfert :** Le patient s'approche, l'app mobile détecte le terminal -> Transfert chiffré.
3. **Réception :** Le terminal déchiffre -> Alerte sonore/visuelle -> Affiche la fiche patient.
4. **Validation :** Le médecin consulte -> Valide ou rejette le dossier.

## 5. Spécifications Techniques
- **Framework:** Flutter Desktop.
- **Storage:** `sqflite_sqlcipher` (même schéma que mobile).
- **Security:** `encrypt` (AES-256).
- **UI:** Material Design 3 (Compact, Desktop layout).

## 6. Prochaines Étapes
1. Création de l'UI de base (Layout Desktop : Sidebar + Dashboard).
2. Intégration du `DesktopSecureTransferService` dans le cycle de vie de l'app.
3. Implémentation du stockage sécurisé local.
4. Développement de la vue de consultation.
