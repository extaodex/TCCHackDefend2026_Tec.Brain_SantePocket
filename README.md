🏥 Santé Pocket • Écosystème Médical P2P (Zéro Cloud)

Santé Pocket est une solution de carnet de santé numérique sécurisée et décentralisée, conçue pour faciliter le partage d'informations cliniques critiques entre patients et médecins sans aucune dépendance au Cloud ou à une connexion Internet.

L'écosystème se compose de deux applications natives interconnectées en réseau local pair-à-pair (P2P), garantissant la souveraineté absolue des données de santé.

📝 Contexte et Impact au Togo

Au Togo, près de 80% des patients égarent ou détériorent leurs dossiers médicaux en raison de la fragilité du format papier. De plus, il existe un cloisonnement informatique quasi total (0% de partage numérique sécurisé) entre les cliniques et centres de soins du pays. En situation d'urgence, l'absence d'historique médical accroît drastiquement le risque d'erreurs médicales (allergies non détectées, contre-indications).

Santé Pocket apporte une réponse immédiate et adaptée aux réalités d'infrastructure togolaises (zones blanches, coût d'internet mobile, coupures d'électricité) :

Zéro Cloud / Zéro Internet : Tout fonctionne de manière locale et autonome.

Souveraineté : Le patient est le seul propriétaire et porteur de son dossier médical chiffré sur son propre smartphone.

Partage Instantané : Transmission ultra-rapide des données cliniques au médecin lors de la consultation par liaison locale sécurisée.

👥 L'Équipe (Tec.Brain)

Filière : Génie Logiciel et Système d'Information (GLSI)

AKATA Odayétobi Exaucé — Chef de projet & Architecture Flutter (Dev 1)

HALOUBIYOU Beni Essowazouna — UI/UX Design & Version Mobile (Dev 2)

DJIGBANI Achille Moni — Sécurité & Chiffrement AES-256 (Dev 3)

ABALO Ganiatou Celia — Version Desktop & Base de données (Dev 4)

🚀 Fonctionnalités du Proof of Concept (PoC)

📱 1. Application Patient (Mobile Android)

Onboarding intuitif : Création du carnet de santé local sécurisé.

Identité Médicale : Profil de santé complet (groupe sanguin, allergies, alertes vitales, antécédents).

Portefeuille de Documents : Stockage local numérisé des ordonnances, vaccins et résultats d'analyses.

Journal Clinique : Auto-suivi et historique quotidien des symptômes.

Partage P2P : Génération d'un QR Code sécurisé pour initier le transfert avec le médecin.

💻 2. Terminal Médecin (Desktop Windows PC)

Dashboard Praticien : Suivi des consultations, statistiques cliniques locales et file d'attente.

Réception P2P : Scanneur de QR Code intégré pour recevoir instantanément le profil du patient sans contact.

Vue "Snapshot" d'urgence : Affichage immédiat des points de vigilance vitaux (allergies majeures, pathologies).

Édition de Rapports : Saisie rapide de notes cliniques et export instantané des prescriptions au format PDF prêt à l'impression.

Purge de Confidentialité : Suppression définitive des données du patient du terminal médical dès la clôture de la session de consultation.

🛡️ Sécurité & Architecture "Zéro Cloud"

La protection des données cliniques repose sur trois couches de sécurité strictes :

Chiffrement au repos (SQLCipher) : Les bases de données locales SQLite (sur Android et sur Windows) sont chiffrées intégralement à l'aide de l'algorithme AES-256. Vos données sont inaccessibles même en cas de vol de l'appareil.

Chiffrement en transit (AES-256-GCM) : Les fichiers et flux partagés en local entre le patient et le médecin sont encapsulés dans un tunnel éphémère chiffré par une clé dérivée via PBKDF2.

Périmètre Local : Aucune clé privée et aucune donnée médicale ne transite sur un serveur tiers ou sur Internet.

🛠️ Structure & Compilation

Arborescence du dépôt GitHub

TCCHackDefend2026_Tec.Brain_SantePocket/
├── sante_pocket_patient/   # Application Mobile (Cible : Android)
└── sante_pocket_doctor/    # Application Desktop (Cible : Windows PC)


Prérequis de développement

Flutter SDK : Version stable 3.x

Dart SDK : Version stable 3.x

Java JDK : Version 17+ (pour la version Android)

C++ Build Tools : Visual Studio avec support C++ (pour la version Windows Desktop)

Guide d'Installation et Lancement

Clonage du projet

git clone [https://github.com/extaodex/TCCHackDefend2026_Tec.Brain_SantePocket.git](https://github.com/extaodex/TCCHackDefend2026_Tec.Brain_SantePocket.git)
cd TCCHackDefend2026_Tec.Brain_SantePocket


Récupération des dépendances
Installez les packages nécessaires dans chaque sous-projet :

# Pour l'application Patient
cd sante_pocket_patient
flutter pub get
cd ..

# Pour l'application Médecin
cd sante_pocket_doctor
flutter pub get
cd ..


Lancement en mode Débug

Lancer l'application Mobile Patient (Android) :

cd sante_pocket_patient
flutter run


Lancer le Terminal Médecin (Windows Desktop) :

cd sante_pocket_doctor
flutter run -d windows


Compilation pour la Production (Release)

Générer l'APK Android (Patient) :

cd sante_pocket_patient
flutter build apk --release


Générer l'exécutable Windows (Médecin) :

cd sante_pocket_doctor
flutter build windows --release


🔑 Identifiants de Test & Compte Démo

L'application étant 100% autonome et décentralisée ("Zéro Cloud"), elle n'utilise pas de serveur d'authentification externe :

Côté Patient : Lancez l'application mobile, puis cliquez directement sur "Créer un compte" pour générer instantanément votre coffre-fort de santé local chiffré.

Côté Médecin : L'accès au tableau de bord s'effectue localement dès l'ouverture de l'application desktop pour simuler de manière fluide la réception et le traitement des fiches patients.

📝 Licence & Propriété

Développé exclusivement par l'équipe Tec.Brain dans le cadre du Hackathon TCC Hack & Defend 2026. Ce projet respecte scrupuleusement la souveraineté numérique nationale et la confidentialité absolue des données médicales.
