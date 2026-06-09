class Patient {
  final int id;
  final String nom;
  final String prenom;
  final String dateNaissance;
  final String groupeSanguin;
  final String allergies;
  final String sexe;
  final String taille;
  final String poids;
  final String tension;
  final String nationalite;
  final String imageProfilPath;
  final String antecedents;

  Patient({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.dateNaissance,
    required this.groupeSanguin,
    required this.allergies,
    this.sexe = '',
    this.taille = '',
    this.poids = '',
    this.tension = '',
    this.nationalite = '',
    this.imageProfilPath = '',
    this.antecedents = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'date_naissance': dateNaissance,
      'groupe_sanguin': groupeSanguin,
      'allergies': allergies,
      'sexe': sexe,
      'taille': taille,
      'poids': poids,
      'tension': tension,
      'nationalite': nationalite,
      'image_profil_path': imageProfilPath,
      'antecedents': antecedents,
    };
  }

  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'],
      nom: map['nom'],
      prenom: map['prenom'],
      dateNaissance: map['date_naissance'],
      groupeSanguin: map['groupe_sanguin'],
      allergies: map['allergies'],
      sexe: map['sexe'] ?? '',
      taille: map['taille'] ?? '',
      poids: map['poids'] ?? '',
      tension: map['tension'] ?? '',
      nationalite: map['nationalite'] ?? '',
      imageProfilPath: map['image_profil_path'] ?? '',
      antecedents: map['antecedents'] ?? '',
    );
  }
}
