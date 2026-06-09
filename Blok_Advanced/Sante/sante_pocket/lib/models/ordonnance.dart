class Ordonnance {
  final int? id;
  final int consultationId;
  final String medicaments; // JSON format
  final String posologie;
  final String duree;

  Ordonnance({
    this.id,
    required this.consultationId,
    required this.medicaments,
    required this.posologie,
    required this.duree,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'consultation_id': consultationId,
      'medicaments': medicaments,
      'posologie': posologie,
      'duree': duree,
    };
  }

  factory Ordonnance.fromMap(Map<String, dynamic> map) {
    return Ordonnance(
      id: map['id'],
      consultationId: map['consultation_id'],
      medicaments: map['medicaments'],
      posologie: map['posologie'],
      duree: map['duree'],
    );
  }
}
