import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/db/consultation_dao.dart';
import '../../models/consultation.dart';
import '../../models/ordonnance.dart';

final consultationDaoProvider = Provider((ref) => ConsultationDao());

class ConsultationsNotifier extends AsyncNotifier<List<Consultation>> {
  @override
  Future<List<Consultation>> build() async {
    return _loadConsultations();
  }

  Future<List<Consultation>> _loadConsultations() async {
    final dao = ref.read(consultationDaoProvider);
    return await dao.getAllConsultations();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _loadConsultations());
  }

  Future<Ordonnance?> getOrdonnance(int consultationId) async {
    final dao = ref.read(consultationDaoProvider);
    return await dao.getOrdonnanceByConsultationId(consultationId);
  }
}

final consultationsProvider = AsyncNotifierProvider<ConsultationsNotifier, List<Consultation>>(() {
  return ConsultationsNotifier();
});
