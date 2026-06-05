import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/symptome.dart';
import '../../core/db/symptome_dao.dart';

final symptomeDaoProvider = Provider<SymptomeDao>((ref) => SymptomeDao());

class SymptomesNotifier extends AsyncNotifier<List<Symptome>> {
  static const int _patientId = 1;

  @override
  Future<List<Symptome>> build() async {
    return await ref.read(symptomeDaoProvider).getSymptomes(_patientId);
  }

  Future<void> addSymptome(String description, String date) async {
    final symptome = Symptome(
      patientId: _patientId,
      date: date,
      description: description,
      statutValidation: 'EN_ATTENTE',
    );
    await ref.read(symptomeDaoProvider).insertSymptome(symptome);
    ref.invalidateSelf();
  }

  Future<void> deleteSymptome(int id) async {
    await ref.read(symptomeDaoProvider).deleteSymptome(id);
    ref.invalidateSelf();
  }
}

final symptomesProvider =
    AsyncNotifierProvider<SymptomesNotifier, List<Symptome>>(
  () => SymptomesNotifier(),
);
