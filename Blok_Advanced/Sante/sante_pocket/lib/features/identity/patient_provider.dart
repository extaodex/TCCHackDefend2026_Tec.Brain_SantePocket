import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/patient.dart';
import '../../models/allergie.dart';
import '../../core/db/patient_dao.dart';
import '../emergency/urgences_provider.dart';
import '../../core/services/user_profile_service.dart';

final patientDaoProvider = Provider<PatientDao>((ref) {
  return PatientDao();
});

class PatientNotifier extends AsyncNotifier<Patient?> {
  late final PatientDao _dao;

  @override
  Future<Patient?> build() async {
    _dao = ref.watch(patientDaoProvider);
    return _loadPatient();
  }

  Future<Patient?> _loadPatient() async {
    return await _dao.getPatient();
  }

  Future<void> savePatient(Patient patient) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _dao.insertOrUpdatePatient(patient);

      // Sauvegarder le nom pour la découverte P2P
      await UserProfileService.saveUserName('${patient.prenom} ${patient.nom}');
      await UserProfileService.setFirstLaunchComplete();

      // Sync allergies from profile string to the allergies table
      final allergieDao = ref.read(allergieDaoProvider);
      
      // Use the patient id from the object or default to 1 if it's a new patient
      final patientId = patient.id;
      final currentAllergies = await allergieDao.getAllergies(patientId);

      final inputAllergies = patient.allergies
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      // Delete existing allergies in DB that are not in the profile string
      for (final existing in currentAllergies) {
        final matchesInput = inputAllergies.any((name) => name.toLowerCase() == existing.libelle.toLowerCase());
        if (!matchesInput) {
          await allergieDao.deleteAllergie(existing.id!);
        }
      }

      // Add new ones
      for (final inputName in inputAllergies) {
        final exists = currentAllergies.any((existing) => existing.libelle.toLowerCase() == inputName.toLowerCase());
        if (!exists) {
          await allergieDao.insertAllergie(Allergie(
            patientId: patientId,
            libelle: inputName,
            severite: 'Critique',
          ));
        }
      }

      // Invalidate allergies provider to refresh UI
      ref.invalidate(allergiesProvider);

      return patient;
    });
  }
}

final patientProvider = AsyncNotifierProvider<PatientNotifier, Patient?>(() {
  return PatientNotifier();
});
