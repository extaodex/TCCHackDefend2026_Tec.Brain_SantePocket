class Symptome {
  final int? id;
  final int patientId;
  final String date;
  final String description;
  final String statutValidation; // 'EN_ATTENTE' ou 'VALIDE'

  Symptome({
    this.id,
    required this.patientId,
    required this.date,
    required this.description,
    this.statutValidation = 'EN_ATTENTE',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'date': date,
      'description': description,
      'statut_validation': statutValidation,
    };
  }

  factory Symptome.fromMap(Map<String, dynamic> map) {
    return Symptome(
      id: map['id'],
      patientId: map['patient_id'],
      date: map['date'] ?? '',
      description: map['description'] ?? '',
      statutValidation: map['statut_validation'] ?? 'EN_ATTENTE',
    );
  }
}
