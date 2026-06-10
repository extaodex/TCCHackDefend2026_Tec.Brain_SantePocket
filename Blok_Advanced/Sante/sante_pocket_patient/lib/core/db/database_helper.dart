import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../security/security_service.dart';

class DatabaseHelper {
  static const _databaseName = "sante_pocket.db";
  static const _databaseVersion = 7;

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);

    // Récupération de la clé sécurisée (générée une seule fois au premier lancement)
    final encryptionKey = await SecurityService.getOrCreateDatabaseKey();

    return await openDatabase(
      path,
      password: encryptionKey,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Note: Pour une mise à jour réelle, il faudrait migrer les données.
    // Ici, on recrée les tables pour simplifier le développement.
    await db.execute("DROP TABLE IF EXISTS patients");
    await db.execute("DROP TABLE IF EXISTS consultations");
    await db.execute("DROP TABLE IF EXISTS ordonnances");
    await db.execute("DROP TABLE IF EXISTS examens_analyses");
    await db.execute("DROP TABLE IF EXISTS vaccinations");
    await db.execute("DROP TABLE IF EXISTS contacts_urgence");
    await db.execute("DROP TABLE IF EXISTS allergies");
    await db.execute("DROP TABLE IF EXISTS symptomes");
    await _onCreate(db, newVersion);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE patients (
        id INTEGER PRIMARY KEY,
        nom TEXT NOT NULL,
        prenom TEXT NOT NULL,
        date_naissance TEXT NOT NULL,
        groupe_sanguin TEXT NOT NULL,
        allergies TEXT NOT NULL,
        sexe TEXT,
        taille TEXT,
        poids TEXT,
        tension TEXT,
        nationalite TEXT,
        image_profil_path TEXT,
        antecedents TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE consultations (
        id INTEGER PRIMARY KEY,
        patient_id INTEGER,
        medecin_id INTEGER,
        date TEXT,
        diagnostic TEXT,
        notes TEXT,
        statut_validation TEXT DEFAULT 'EN_ATTENTE',
        signature_medecin TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE ordonnances (
        id INTEGER PRIMARY KEY,
        consultation_id INTEGER,
        medicaments TEXT,
        posologie TEXT,
        duree TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE examens_analyses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        resultat_pdf_path TEXT,
        commentaire TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE vaccinations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id INTEGER NOT NULL,
        vaccin TEXT NOT NULL,
        date TEXT NOT NULL,
        prochain_rappel TEXT,
        statut_validation TEXT DEFAULT 'EN_ATTENTE'
      )
    ''');

    await db.execute('''
      CREATE TABLE contacts_urgence (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id INTEGER NOT NULL,
        nom TEXT NOT NULL,
        relation TEXT NOT NULL,
        telephone TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE allergies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id INTEGER NOT NULL,
        libelle TEXT NOT NULL,
        severite TEXT NOT NULL DEFAULT 'Critique'
      )
    ''');

    await db.execute('''
      CREATE TABLE symptomes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        patient_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        description TEXT NOT NULL,
        statut_validation TEXT DEFAULT 'EN_ATTENTE'
      )
    ''');
  }

  Future<bool> hasPatient() async {
    final db = await database;
    final result = await db.query('patients', limit: 1);
    return result.isNotEmpty;
  }
}
