class Vaccination {
  final int? id;
  final int patientId;
  final String vaccin;
  final String date;
  final String prochainRappel;
  final String statutValidation; // 'En attente', 'Validé'

  Vaccination({
    this.id,
    required this.patientId,
    required this.vaccin,
    required this.date,
    required this.prochainRappel,
    required this.statutValidation,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'vaccin': vaccin,
      'date': date,
      'prochain_rappel': prochainRappel,
      'statut_validation': statutValidation,
    };
  }

  factory Vaccination.fromMap(Map<String, dynamic> map) {
    return Vaccination(
      id: map['id'],
      patientId: map['patient_id'],
      vaccin: map['vaccin'],
      date: map['date'],
      prochainRappel: map['prochain_rappel'],
      statutValidation: map['statut_validation'],
    );
  }
}
