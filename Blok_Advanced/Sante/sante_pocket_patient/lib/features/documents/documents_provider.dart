import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/examen_analyse.dart';
import '../../core/db/examen_dao.dart';

final examenDaoProvider = Provider<ExamenDao>((ref) => ExamenDao());

class DocumentsNotifier extends AsyncNotifier<List<ExamenAnalyse>> {
  static const int _patientId = 1;

  @override
  Future<List<ExamenAnalyse>> build() async {
    return await ref.read(examenDaoProvider).getExamens(_patientId);
  }

  Future<void> addDocument(String type, String pdfPath, String commentaire) async {
    final examen = ExamenAnalyse(
      patientId: _patientId,
      type: type,
      resultatPdfPath: pdfPath,
      commentaire: commentaire,
    );
    await ref.read(examenDaoProvider).insertExamen(examen);
    ref.invalidateSelf();
  }

  Future<void> deleteDocument(int id) async {
    await ref.read(examenDaoProvider).deleteExamen(id);
    ref.invalidateSelf();
  }
}

final documentsProvider =
    AsyncNotifierProvider<DocumentsNotifier, List<ExamenAnalyse>>(
  () => DocumentsNotifier(),
);
