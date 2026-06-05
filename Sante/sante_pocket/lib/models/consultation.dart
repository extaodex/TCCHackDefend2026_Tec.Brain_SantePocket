class Consultation {
  final int? id;
  final int patientId;
  final int? medecinId;
  final String date;
  final String diagnostic;
  final String notes;
  final String statutValidation; // 'En attente', 'Validé'
  final String? signatureMedecin; // JSON

  Consultation({
    this.id,
    required this.patientId,
    this.medecinId,
    required this.date,
    required this.diagnostic,
    required this.notes,
    required this.statutValidation,
    this.signatureMedecin,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'medecin_id': medecinId,
      'date': date,
      'diagnostic': diagnostic,
      'notes': notes,
      'statut_validation': statutValidation,
      'signature_medecin': signatureMedecin,
    };
  }

  factory Consultation.fromMap(Map<String, dynamic> map) {
    return Consultation(
      id: map['id'],
      patientId: map['patient_id'],
      medecinId: map['medecin_id'],
      date: map['date'],
      diagnostic: map['diagnostic'],
      notes: map['notes'],
      statutValidation: map['statut_validation'],
      signatureMedecin: map['signature_medecin'],
    );
  }
}
