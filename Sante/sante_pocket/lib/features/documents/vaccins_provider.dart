import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/vaccination.dart';
import '../../core/db/vaccination_dao.dart';
import '../../core/services/notification_service.dart';

final vaccinationDaoProvider = Provider<VaccinationDao>((ref) => VaccinationDao());

class VaccinationsNotifier extends AsyncNotifier<List<Vaccination>> {
  static const int _patientId = 1;

  @override
  Future<List<Vaccination>> build() async {
    return await ref.read(vaccinationDaoProvider).getVaccinations(_patientId);
  }

  DateTime? _parseDate(String dateStr) {
    try {
      final parts = dateStr.trim().split('/');
      if (parts.length != 3) return null;
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      return DateTime(year, month, day, 9, 0); // 9h00
    } catch (_) {
      return null;
    }
  }

  Future<void> addVaccination(String vaccin, String date, String prochainRappel) async {
    final vacc = Vaccination(
      patientId: _patientId,
      vaccin: vaccin,
      date: date,
      prochainRappel: prochainRappel,
      statutValidation: 'EN_ATTENTE',
    );
    final insertedId = await ref.read(vaccinationDaoProvider).insertVaccination(vacc);

    if (prochainRappel.isNotEmpty) {
      final scheduledDate = _parseDate(prochainRappel);
      if (scheduledDate != null) {
        await NotificationService.scheduleVaccineNotification(
          id: insertedId,
          title: 'Rappel de Vaccin 💉',
          body: 'Votre rappel de vaccin pour "$vaccin" est prévu aujourd\'hui.',
          scheduledDate: scheduledDate,
        );
      }
    }

    ref.invalidateSelf();
  }

  Future<void> deleteVaccination(int id) async {
    await ref.read(vaccinationDaoProvider).deleteVaccination(id);
    await NotificationService.cancelNotification(id);
    ref.invalidateSelf();
  }
}

final vaccinationsProvider =
    AsyncNotifierProvider<VaccinationsNotifier, List<Vaccination>>(
  () => VaccinationsNotifier(),
);
