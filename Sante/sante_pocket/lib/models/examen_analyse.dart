class ExamenAnalyse {
  final int? id;
  final int patientId;
  final String type;
  final String resultatPdfPath;
  final String commentaire;

  ExamenAnalyse({
    this.id,
    required this.patientId,
    required this.type,
    required this.resultatPdfPath,
    required this.commentaire,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'type': type,
      'resultat_pdf_path': resultatPdfPath,
      'commentaire': commentaire,
    };
  }

  factory ExamenAnalyse.fromMap(Map<String, dynamic> map) {
    return ExamenAnalyse(
      id: map['id'],
      patientId: map['patient_id'],
      type: map['type'],
      resultatPdfPath: map['resultat_pdf_path'],
      commentaire: map['commentaire'],
    );
  }
}
