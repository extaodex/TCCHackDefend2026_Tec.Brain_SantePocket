class ContactUrgence {
  final int? id;
  final int patientId;
  final String nom;
  final String relation;
  final String telephone;

  ContactUrgence({
    this.id,
    required this.patientId,
    required this.nom,
    required this.relation,
    required this.telephone,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'nom': nom,
      'relation': relation,
      'telephone': telephone,
    };
  }

  factory ContactUrgence.fromMap(Map<String, dynamic> map) {
    return ContactUrgence(
      id: map['id'],
      patientId: map['patient_id'],
      nom: map['nom'],
      relation: map['relation'],
      telephone: map['telephone'],
    );
  }
}
