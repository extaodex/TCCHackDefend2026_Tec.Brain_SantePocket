class Allergie {
  final int? id;
  final int patientId;
  final String libelle;
  final String severite; // 'Critique', 'Modérée', 'Légère'

  Allergie({
    this.id,
    required this.patientId,
    required this.libelle,
    this.severite = 'Critique',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'libelle': libelle,
      'severite': severite,
    };
  }

  factory Allergie.fromMap(Map<String, dynamic> map) {
    return Allergie(
      id: map['id'],
      patientId: map['patient_id'],
      libelle: map['libelle'],
      severite: map['severite'] ?? 'Critique',
    );
  }
}
