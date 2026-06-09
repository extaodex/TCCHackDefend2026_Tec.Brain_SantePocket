Voici ce que je veux faire: 
> **Contexte**
> Je développe une application Flutter de transfert de fichiers médicaux en peer-to-peer sur réseau local WiFi. Deux versions de l'app existent : une pour Android (côté patient) et une pour Windows/Linux/macOS (côté médecin). Il n'y a aucun serveur externe, aucune connexion internet requise. Tout est local et chiffré.
>
> **Identification des utilisateurs**
> Au premier lancement de chaque app, on demande à l'utilisateur son nom (ex: `ABALO Koassi` côté patient, `Dr. Tcha` côté médecin). Ce nom est stocké localement via SharedPreferences. C'est ce nom qui est affiché et partagé sur le réseau, jamais une IP ou un UUID brut.
>
> **Règle absolue sur le QR code**
> Seul le PC génère des QR codes. Le mobile ne génère jamais de QR code. Seul le mobile scanne des QR codes. Le PC ne scanne jamais de QR code. Cette règle ne souffre d'aucune exception.
>
> **Règle absolue sur le hotspot**
> C'est toujours le mobile qui active le point d'accès WiFi. Jamais le PC. Le PC se connecte toujours au hotspot du mobile. Cette règle ne souffre d'aucune exception.
>
> **Flux 1 — Patient vers Médecin**
>
> Sur le mobile, le patient clique "Partager avec médecin". L'app affiche `"ABALO Koassi cherche un médecin"`. L'app active automatiquement le hotspot WiFi avec un SSID au format `MediShare_[UUID]_v1` et un mot de passe fort de 16 caractères généré aléatoirement. La connexion est chiffrée via AES-256. L'app lance une découverte mDNS pour trouver les PCs disponibles. Elle affiche une liste avec les noms des médecins trouvés (ex: `["Dr. Tcha", "Dr. Jean"]`). Le patient sélectionne un médecin. Le mobile se connecte au PC via TCP avec une connexion chiffrée. Il affiche `"Vous êtes bien connecté au Dr. Tcha"`. Les fichiers du dossier du patient s'envoient automatiquement sans aucun bouton supplémentaire.
>
> Sur le PC, le médecin clique "Recevoir un patient". L'app affiche `"Dr. Tcha attend un patient"`. Le PC écoute sur son port TCP 9876 sur `0.0.0.0`. Il scanne les hotspots WiFi disponibles. Quand il trouve un hotspot au format `MediShare_*_v1`, il s'y connecte automatiquement. Il établit une connexion TCP chiffrée avec le mobile. Il affiche `"Vous êtes bien connecté au patient ABALO Koassi"`. Il reçoit automatiquement les fichiers sans aucune intervention.
>
> **Flux 2 — Médecin vers Patient (retour)**
>
> Sur le mobile, le patient clique "Attendre le médecin". L'app affiche `"ABALO Koassi attend le médecin"`. Le mobile active immédiatement son hotspot avec le même format `MediShare_[UUID]_v1` et un mot de passe chiffré. Le mobile cherche le PC via mDNS pendant 15 secondes. Si le PC est trouvé dans ce délai, le mobile se connecte directement au PC via TCP chiffré, affiche `"Vous êtes bien connecté au Dr. Tcha"` et reçoit automatiquement les fichiers. Si le PC n'est pas trouvé après 15 secondes, le mobile affiche le message `"Médecin non trouvé"` et un bouton `"Scanner le code QR du médecin"`. Quand l'utilisateur clique ce bouton, la caméra s'ouvre. Le mobile scanne le QR code affiché sur le PC, extrait l'IP, le port, l'UUID et la clé de chiffrement, se connecte directement au PC via cette IP, établit la connexion chiffrée et reçoit automatiquement les fichiers.
>
> Sur le PC, le médecin clique "Retourner au patient". L'app affiche `"Dr. Tcha va retourner au patient"`. Le PC scanne les hotspots WiFi disponibles pour trouver `MediShare_*_v1` pendant 15 secondes. Si le hotspot est trouvé dans ce délai, il s'y connecte, établit une connexion TCP chiffrée avec le mobile, affiche `"Vous êtes bien connecté au patient ABALO Koassi"` et envoie automatiquement les fichiers. Si le hotspot n'est pas trouvé après 15 secondes, le PC génère un QR code contenant `IP_PC:PORT:UUID_PC:CLE_CHIFFREMENT` et l'affiche en grand à l'écran. Il se met en écoute passive sur son port TCP et attend que le mobile se connecte via le QR.
>
> **Protocole de transfert**
> Avant tout fichier, envoyer un en-tête de 4 octets contenant la taille du JSON qui suit, puis le JSON avec le nom du fichier, sa taille totale et son type MIME. Ensuite envoyer les chunks dans cet ordre exact : 4 octets CRC32 calculé sur les données brutes avant compression, 4 octets pour la taille des données compressées, puis les données compressées en zlib. La taille d'un chunk est 65536 octets. Quand tous les chunks sont reçus, envoyer `OK`. Si un CRC ne correspond pas, envoyer `ER` et redemander ce chunk. Ne jamais lire les données réseau sans boucler jusqu'à avoir exactement le nombre d'octets attendu. Toujours utiliser `Uint8List` pour les données binaires, jamais des `String`.
>
> **Sécurité**
> Chiffrer la connexion TCP avec AES-256. La clé de chiffrement est générée à chaque nouvelle session. Cette clé est transmise via le QR code en fallback. Sur le hotspot, le mot de passe est fort et aléatoire. Aucune donnée ne circule en clair à aucun moment.
>
> **Permissions Android obligatoires**
> `INTERNET`, `ACCESS_WIFI_STATE`, `CHANGE_WIFI_STATE`, `ACCESS_FINE_LOCATION`, `READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE`, `MANAGE_EXTERNAL_STORAGE` pour Android 11+, `CHANGE_WIFI_MULTICAST_STATE`. Les demander toutes au démarrage. Pour `MANAGE_EXTERNAL_STORAGE`, rediriger vers les paramètres système car elle ne peut pas être accordée via une dialog simple.
>
> **Permissions Windows**
> Attraper l'erreur de binding du socket TCP et afficher un message clair demandant d'autoriser l'app dans le pare-feu Windows.
>
> **Packages à utiliser**
> `dart:io` pour `ServerSocket`, `Socket`, `RawDatagramSocket`. `file_picker` pour sélectionner les fichiers. `path_provider` pour le dossier de destination. `network_info_plus` pour récupérer l'IP locale dynamiquement. `device_info_plus` pour les infos de l'appareil. `permission_handler` pour les permissions. `uuid` pour les identifiants uniques. `archive` pour zlib et CRC32. `qr_flutter` sur le PC uniquement pour générer les QR codes. `mobile_scanner` sur le mobile uniquement pour scanner les QR codes. `shared_preferences` pour stocker le nom de l'utilisateur. `nsd_dart` pour la découverte mDNS.
>
> **Structure obligatoire**
> Séparer strictement la logique réseau de l'UI. Les services réseau n'ont aucune dépendance sur Flutter UI. Les services exposent des `Stream` pour que l'UI écoute les appareils découverts et la progression des transferts. Tout le réseau tourne dans des `Isolate` séparés, jamais sur le thread principal.
>
> **Ce qu'il ne faut absolument pas faire**
> Ne pas utiliser `localhost` pour le ServerSocket, utiliser `0.0.0.0`. Ne pas charger un fichier entier en mémoire, utiliser des streams et chunks. Ne pas hardcoder une IP. Ne pas utiliser des `String` pour manipuler des données binaires. Ne pas faire tourner le réseau sur le thread principal. Ne pas ignorer les cas où `network_info_plus` retourne `null`. Ne pas utiliser HTTP, WebSocket, Firebase ou un serveur externe. Ne pas générer de QR code sur le mobile. Ne pas scanner de QR code sur le PC.
>
> **Commencer par**
> Implémenter et tester le `FileTransferService` avec deux IPs fixes. Quand le transfert fonctionne parfaitement, ajouter le `DiscoveryService` mDNS. En dernier, ajouter la logique hotspot et QR code.













 Voici une reflexion:

The user is asking me to implement a comprehensive P2P file transfer system for their medical application. This is a major architectural overhaul that requires careful planning. Let me analyze what needs to change:

The current implementation has basic UDP broadcast discovery and TCP file transfer
The new spec requires:
mDNS discovery (instead of UDP broadcast)
AES-256 encryption on all TCP connections
Hotspot management on mobile
QR code generation on PC / scanning on mobile
SharedPreferences for user names
Specific flow for Patient→Doctor and Doctor→Patient
Fallback QR code mechanism when mDNS fails after 15s
Since they want me to just implement without planning overhead, I need to assess what's already in place: the desktop side has basic P2P with UDP discovery, TCP file transfer with compression and checksums, a secure transfer service bridging to the UI, MSH parsing for medical files, and various UI components, but it's missing AES encryption, QR code generation, and mDNS support.
For the PC implementation, I need to swap out UDP discovery for mDNS, add AES-256 encryption on top of TCP, generate QR codes as a fallback, store the doctor name in preferences instead of hardcoding it, and build out the two main flows: receiving patient data via hotspot scanning and returning data either through hotspot or QR code. The tricky part is handling WiFi hotspot scanning and connection on desktop, which the spec mentions for mobile but I need to figure out what's feasible for PC. I need to prioritize the implementation work rather than continue planning. The key features to tackle are storing the doctor name in preferences, adding AES-256 encryption for the TCP transfers, generating QR codes as a fallback option, implementing mDNS discovery instead of UDP broadcast, building out the proper UI flows for patient interactions, and handling WiFi scanning on desktop—though that last part will be the most challenging. Since the user wants me to start implementing now rather than keep planning, I should focus on getting the core functionality working first. The spec requires nsd_dart for mDNS discovery, and I'll need to add AES-256 encryption, QR code generation, and persistent storage for the doctor name. My implementation plan focuses on three phases: first setting up the core infrastructure with encryption and mDNS, then enhancing the transfer protocol with encryption and retry logic, and finally building out the UI flows for patient reception and status tracking.

Let me reconsider the package compatibility—qr_flutter, shared_preferences, and encrypt all work on desktop, but nsd_dart is Android-only, so I'll use multicast_dns for desktop mDNS instead, though the current UDP broadcast approach is already functional for discovery.

For the implementation, I'm going to be practical: keep the UDP broadcast for discovery with multicast_dns as an optional enhancement, use Windows netsh commands via Process.run() for WiFi management, stick with encrypt for AES-256-CBC, qr_flutter for QR codes, and shared_preferences for storing the doctor name.

Now I need to plan out the actual file structure. I'll add the necessary packages to pubspec.yaml, create new service files for encryption, WiFi management, and user profile handling, plus a first-launch dialog for the name prompt, and update the discovery service to integrate these pieces.

The implementation is complex, so I'm going to work through this systematically, focusing on the core changes needed for the two flows: the secure transfer between doctor and patient devices, and the encrypted file handling throughout the system. Writing Windows WiFi commands...

The real issue is the password handoff - the mobile generates a strong random password for the hotspot, but the PC needs to know it somehow to connect. The QR code in Flux 2 has the encryption key but not the WiFi credentials, so there's a gap in how the PC actually authenticates to the network.

I think the solution is to derive the password deterministically from the UUID. Since the SSID already contains the UUID (MediShare_[UUID]_v1), both devices can use the same algorithm - like HMAC-SHA256 of the UUID with a shared app secret - to generate an identical password. The mobile creates the hotspot with this derived password, and the PC extracts the UUID from the SSID it sees, runs the same derivation, and connects automatically.

Now I need to stop overthinking and actually build this. Let me focus on the PC implementation since that's what the project needs, and I'll outline the full plan before diving into the code - I'll need to add dependencies for secure storage, encryption, and crypto operations, then implement the core modules for hotspot discovery, password derivation, and encrypted communication.

For the actual implementation, I'm creating services to handle the doctor's profile setup on first launch, AES-256 encryption for data protection, WiFi scanning and connection to MediShare hotspots, and an enhanced discovery service that includes the doctor's name. The file transfer service will get an encryption layer on top.

The two main flows are straightforward: receiving files means scanning for the hotspot, connecting, and listening for incoming data, while returning files means scanning first, connecting if found to send directly, or showing a QR code if the mobile device isn't nearby yet. I'll also need a first-launch dialog to capture the doctor's name and update the dashboard UI accordingly.

Given the scope here, I should probably break this into manageable pieces and start with the core services first. The rules are clear that I need to stop and request approval before executing a major architectural change like this, even though the user said "implémente." I'll create a concise plan and ask for feedback first. I also need to think through some technical decisions—like using Windows-specific netsh commands for the WiFi hotspot since that's the user's OS, and choosing an encryption library for the AES-256 implementation.

For service discovery, I'm realizing nsd_dart isn't actually a real package—the user might be thinking of nsd which is Android/iOS only. I'll need to use multicast_dns instead since it works cross-platform for mDNS discovery.

Actually, bonsoir is the better choice here since it supports Windows, macOS, Linux, and mobile platforms all at once. I could keep the UDP broadcast as a fallback for reliability, but bonsoir should handle the mDNS discovery cleanly.

Now I'm focusing on what the implementation plan needs to cover specifically for the PC side.

Adding the necessary dependencies and creating the core services: a user profile service to persist the doctor name and detect first launch, an encryption service for AES-256-CBC with session key generation, and a WiFi manager service that scans for the hotspot pattern, connects via Windows commands, and derives the password from the SSID UUID.

Now I'm updating the discovery service to broadcast the doctor name through mDNS, enhancing the file transfer service with AES encryption and chunk retry logic on CRC failures, adding encrypted read/write utilities to TCP operations, and rewriting the desktop secure transfer service to handle both receive and return flows with QR code fallback while managing the WiFi connection lifecycle.

I need to build out the dashboard view with two main action buttons, status messaging aligned with the spec, QR code display for fallback scenarios, and progress indicators. Then I'll create the onboarding flow for initial doctor name setup, update the main entry point to check for first launch and integrate the doctor name into the sidebar, and fix the build context synchronicity warnings in the consultation view.

I'm realizing the spec covers both the PC and mobile implementations, but since we've been focused on the desktop terminal application and that's what was explicitly requested for completion and deployment, I should concentrate on the PC side for now. The mobile implementation would be a separate coordinated effort.

Now I need to tackle a critical architectural question: how the PC discovers and connects to the mobile hotspot when the password is randomly generated. I'm weighing three approaches—using a deterministic algorithm to derive the password from the UUID, relying on an open hotspot with encrypted TCP communication instead, or requiring a QR code exchange first to share the credentials.

I'm settling on deriving the password deterministically from the UUID using PBKDF2 with a shared app salt. This lets both the mobile and PC independently generate the same password without needing to transmit it, which satisfies the requirement for automatic connection while maintaining security through the encryption layer.

Now I need to map out the implementation plan and figure out the Windows-specific WiFi profile setup, since connecting to a network programmatically requires creating a profile XML first before using the connection command. Simplifying the encryption strategy: each session gets a random 32-byte AES-256 key, with auto-connect deriving the key from UUID plus a shared secret via PBKDF2, while QR codes embed the key directly. Messages use AES-256-CBC with a random IV prepended to each block. For Windows WiFi scanning, I'm using netsh commands to list available networks and parse the output.

Now I'm mapping out the project structure with specific files that need modification or rewriting—the core P2P layer will handle encrypted device models, TCP utilities for encrypted communication, and discovery services using mDNS with UDP fallback. I'm mapping out the feature views and main entry point updates, then realizing that WiFi hotspot scanning and auto-connection will need careful platform-specific handling since it varies significantly across iOS and Android.

The QR code fallback is definitely the more reliable approach. I can use the bonsoir package for mDNS discovery since it has Windows support through the bonsoir_windows plugin, and I can bring back the encrypt package that was removed during the P2P refactoring.

Now I'm thinking through how to integrate AES encryption with the existing transfer protocol that uses metadata JSON length headers and CRC32 checksums.

Defining the encrypted protocol structure... Writing the wrapper classes...

I'll create EncryptedSocket and EncryptedReader that handle the encryption and decryption transparently, keeping the existing protocol intact underneath. Also need to verify that bonsoir is the right package for mDNS discovery across the platforms we're targeting. I need to be practical about what's actually feasible here. WiFi auto-connection on PC is too platform-specific and fragile, mDNS on Windows can be finicky with firewalls, and encrypting every TCP byte adds significant overhead. So I'll use netsh for WiFi management with clear error handling and the QR code as the reliable fallback, bonsoir for mDNS discovery with UDP broadcast as a backup, and implement proper AES-256-CBC encryption for the TCP stream.

Actually, I'm realizing that discovery might not even be critical on PC since once it connects to the mobile's hotspot, the mobile is typically the gateway—the PC can just connect directly to that IP. But the spec requires mDNS, so I'll implement it with bonsoir. Let me focus on creating a clear, concise plan before diving into implementation, though I'm noticing there's a potential issue with the sante_pocket dependency configuration that I should address. I'm laying out the implementation steps: adding dependencies, building the encryption and user profile services, updating discovery and file transfer with encryption, redesigning the transfer flow and dashboard UI, creating onboarding, and updating the entry point. I should focus on the desktop implementation first since that's where the current work is, then tackle mobile afterward. The user wants me to implement the full spec. I'll start with the PC implementation since that's been the focus, making sure it's mobile-compatible. The key flows are: initial doctor name prompt, then either scanning for incoming mobile connections via WiFi hotspot detection and mDNS discovery, or reconnecting to a previously paired patient.



Voici le plan d'implémentation:
Implémentation Complète — Terminal Médecin (PC)
Refonte complète du système P2P pour le terminal médecin : chiffrement AES-256, gestion WiFi hotspot, QR code, mDNS, identification par nom, et les deux flux de transfert.

User Review Required
IMPORTANT

Refonte majeure du Dashboard et du TransferService. Le flux de travail passe de "Activer le terminal → attendre" à deux actions distinctes : "Recevoir un patient" et "Retourner au patient", chacune avec sa propre séquence (WiFi scan → connexion → transfert ou QR fallback).

WARNING

WiFi auto-connexion sur Windows : Utilise netsh wlan en ligne de commande. Nécessite que le service WLAN AutoConfig soit actif. En cas d'échec, le QR code est toujours disponible en fallback. L'utilisateur doit autoriser l'app dans le pare-feu Windows.

IMPORTANT

Dérivation du mot de passe hotspot : Le SSID est MediShare_[UUID]_v1. Le mot de passe est dérivé de l'UUID via PBKDF2-SHA256 avec un sel partagé entre les deux apps. Ainsi, le PC peut calculer le mot de passe automatiquement en lisant le SSID.

Open Questions
IMPORTANT

Sel partagé PBKDF2 : Le sel utilisé pour dériver le mot de passe WiFi à partir de l'UUID sera "SantePocket2026_HotspotKey". Ce sel est codé en dur dans les deux apps. Acceptable ?
Clé AES de session : Pour la connexion auto (hotspot trouvé), la clé AES est dérivée du même UUID via PBKDF2 avec un sel différent ("SantePocket2026_AESKey"). Pour le QR fallback, la clé est transmise dans le QR. Acceptable ?
Architecture Protocolaire
Chiffrement AES-256-CBC sur TCP
Chaque message TCP est enveloppé :


[4 octets : taille du bloc chiffré (plaintext, non chiffré)]
[16 octets : IV aléatoire]
[N octets : AES-256-CBC ciphertext]
Le contenu déchiffré est le même protocole que l'actuel (metadata JSON + chunks CRC32/zlib).

Dérivation de clé depuis le SSID

SSID: "MediShare_<UUID>_v1"
WiFi Password: PBKDF2(UUID, salt="SantePocket2026_HotspotKey", iterations=10000, keyLen=16) → Base62
AES Session Key: PBKDF2(UUID, salt="SantePocket2026_AESKey", iterations=10000, keyLen=32)
QR Code (Fallback Flux 2)

IP_PC:PORT:UUID_PC:BASE64_AES_KEY
Exemple: "192.168.1.42:9876:550e8400-e29b-41d4:aGVsbG8gd29ybGQ="
Proposed Changes
Dépendances
[MODIFY] 
pubspec.yaml
Ajouter : shared_preferences, encrypt, qr_flutter, bonsoir, pointycastle
Conserver : tous les packages existants
Services Core — Sécurité & Identité
[NEW] lib/core/services/encryption_service.dart
generateSessionKey() → 32 bytes aléatoires
deriveKeyFromUuid(String uuid, String salt) → PBKDF2-SHA256, 32 bytes
deriveWifiPassword(String uuid) → PBKDF2, 16 chars Base62
encrypt(Uint8List data, Uint8List key) → IV (16 bytes) + ciphertext
decrypt(Uint8List encrypted, Uint8List key) → plaintext
Pure Dart, aucune dépendance Flutter
[NEW] lib/core/services/user_profile_service.dart
isFirstLaunch() → bool (SharedPreferences)
saveDoctorName(String name) → stockage
getDoctorName() → String? (retourne null si pas encore configuré)
getDoctorUuid() → UUID persistant généré au premier lancement
Remplace le nom hardcodé "Dr. Dupont" dans toute l'app
Services Core — Réseau
[NEW] lib/core/services/wifi_manager_service.dart
scanForMediShareHotspot() → scanne les réseaux WiFi via netsh wlan show networks
connectToHotspot(String ssid, String password) → crée un profil XML temporaire et connecte via netsh wlan connect
disconnectFromHotspot() → restaure la connexion WiFi précédente
extractUuidFromSsid(String ssid) → parse MediShare_[UUID]_v1
Expose un Stream<WifiScanStatus> avec les états : scanning, found, connecting, connected, notFound, error
Windows uniquement (Process.run)
[MODIFY] 
discovery_service.dart
Ajouter la registration/discovery mDNS via bonsoir comme mécanisme principal
Le nom du service mDNS est le nom du médecin (ex: Dr. Tcha)
Conserver le UDP broadcast comme fallback
Le type de service mDNS sera _medishare._tcp
[MODIFY] 
file_transfer_service.dart
Ajouter un paramètre Uint8List? encryptionKey à sendFile() et startServer()
Si la clé est fournie, encapsuler chaque écriture/lecture TCP dans la couche AES
Ajouter la logique de retry sur erreur CRC (renvoyer "ER" + re-demander le chunk)
[MODIFY] 
tcp_utils.dart
Ajouter writeEncrypted(Socket, Uint8List data, Uint8List key) → écrit IV+ciphertext avec header de taille
Ajouter readDecrypted(ExactReader, Uint8List key) → lit header+IV+ciphertext, déchiffre
Orchestration — Flux de Transfert
[REWRITE] 
desktop_secure_transfer_service.dart
Nouveau TransferState avec des statuts plus granulaires :

dart

enum FlowType { receiveFromPatient, returnToPatient }
enum FlowStatus {
  idle,
  scanningWifi,         // "Dr. Tcha cherche un patient..."
  connectingWifi,       // "Connexion au hotspot MediShare..."
  wifiConnected,        // "Connecté au réseau du patient"
  discoveringDevice,    // "Recherche du mobile..."
  deviceFound,          // "Patient ABALO Koassi trouvé"
  transferring,         // "Transfert en cours..."
  showingQrCode,        // QR affiché (fallback Flux 2)
  waitingForConnection, // Attente connexion via QR
  completed,            // "Transfert terminé !"
  error,                // Message d'erreur
}
Flux 1 — receiveFromPatient() :

État → scanningWifi ("Dr. Tcha attend un patient")
Lance WifiManagerService.scanForMediShareHotspot() pendant 15s
Si trouvé → connectingWifi → connexion au hotspot
wifiConnected → lance discovery mDNS pour trouver le mobile
deviceFound → affiche "Vous êtes bien connecté au patient ABALO Koassi"
transferring → réception auto des fichiers
completed → parse le .msh et ouvre ConsultationView
Flux 2 — returnToPatient(Map record) :

État → scanningWifi ("Dr. Tcha va retourner au patient")
Lance WifiManagerService.scanForMediShareHotspot() pendant 15s
Si trouvé → connexion + discovery + envoi du .msh → completed
Si PAS trouvé → showingQrCode → génère QR code avec IP:PORT:UUID:CLE
Lance le serveur TCP en écoute passive
Quand le mobile se connecte via QR → transferring → envoi → completed
Interface Utilisateur
[NEW] lib/features/onboarding/onboarding_view.dart
Écran plein page affiché au tout premier lancement
Champ "Votre nom complet" (ex: "Dr. Tcha")
Bouton "Commencer" qui sauvegarde le nom via UserProfileService
Design premium : icône médicale, gradient subtil, animation d'entrée
[REWRITE] 
dashboard_view.dart
En-tête : "Bonjour, Dr. Tcha" (depuis UserProfileService)
Grille de stats (inchangée)
Carte principale réécrite avec deux gros boutons :
🔽 "Recevoir un patient" — Lance le Flux 1
🔼 "Retourner au patient" — Lance le Flux 2 (grisé si aucun patient récent)
Zone de statut dynamique affichant les messages de progression
QR Code affiché en grand quand nécessaire (Flux 2 fallback)
Activités récentes (inchangée)
[MODIFY] 
settings_view.dart
Utiliser UserProfileService au lieu de DatabaseService pour le nom du médecin
Synchroniser les deux (SharedPreferences ↔ SQLCipher profile)
[MODIFY] 
main.dart
Vérifier UserProfileService.isFirstLaunch() → montrer OnboardingView si premier lancement
Utiliser le nom du médecin dans le profil sidebar (plus de "Dr. Dupont" hardcodé)
Supprimer l'import inutilisé de consultation_view.dart
Titre de la fenêtre Windows : "Santé Pocket — Dr. Tcha"
[MODIFY] 
consultation_view.dart
Corriger les warnings use_build_context_synchronously (lignes 254-255) en capturant le context du dialog avant l'await
Pas d'autres changements fonctionnels
Configuration de Build Windows
[MODIFY] 
Runner.rc
CompanyName → "Tec.Brain"
FileDescription → "Santé Pocket - Terminal Médecin"
ProductName → "Santé Pocket"
[MODIFY] 
main.cpp
Titre de la fenêtre : L"Santé Pocket - Terminal Médecin"
Verification Plan
Automated Tests
bash

flutter analyze --no-pub
Doit retourner 0 erreur, 0 warning, 0 info
Manual Verification
Premier lancement → OnboardingView s'affiche → saisir "Dr. Tcha" → Dashboard affiché
Dashboard → nom "Dr. Tcha" affiché partout (en-tête, sidebar)
Bouton "Recevoir un patient" → scan WiFi → statut "Recherche..."
Bouton "Retourner au patient" → scan WiFi → QR code affiché après timeout
QR code contient bien IP:PORT:UUID:KEY en texte



Voici une liste de tâches 
Terminal Médecin PC — Implémentation P2P Complète
Phase 1 : Dépendances & Services Core
 Mettre à jour pubspec.yaml (shared_preferences, encrypt, qr_flutter, crypto)
 Créer encryption_service.dart (AES-256, PBKDF2, key derivation)
 Créer user_profile_service.dart (SharedPreferences, doctor name, UUID)
 Créer wifi_manager_service.dart (netsh scan/connect, MediShare_*_v1)
Phase 2 : Couche P2P
 Mettre à jour models.dart (FlowType, FlowStatus, TransferState étendu)
 Mettre à jour tcp_utils.dart (encrypted read/write helpers)
 Mettre à jour discovery_service.dart (nom du médecin depuis UserProfile)
 Mettre à jour file_transfer_service.dart (chiffrement AES par chunk)
 Mettre à jour p2p_provider.dart (nouveaux providers)
Phase 3 : Orchestration
 Réécrire desktop_secure_transfer_service.dart (Flux 1 + Flux 2)
Phase 4 : Interface Utilisateur
 Créer onboarding_view.dart (premier lancement)
 Réécrire dashboard_view.dart (deux boutons de flux + statuts + QR)
 Mettre à jour main.dart (onboarding check, doctor name, fix import)
 Mettre à jour settings_view.dart (UserProfileService)
 Fix consultation_view.dart (use_build_context_synchronously)
Phase 5 : Build & Config Windows
 Mettre à jour Runner.rc (CompanyName, ProductName)
 Mettre à jour main.cpp (titre fenêtre)
Phase 6 : Test et correction
 Faire tous les test possible et n'avoir aucune erreur, avertissement ou suggestion.



