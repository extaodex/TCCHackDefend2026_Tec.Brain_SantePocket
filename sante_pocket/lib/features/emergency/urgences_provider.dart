import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/allergie.dart';
import '../../models/contact_urgence.dart';
import '../../models/patient.dart';
import '../../core/db/allergie_dao.dart';
import '../../core/db/contact_urgence_dao.dart';
import '../identity/patient_provider.dart';

// ──────────────────────────────────────────────
//  Providers DAOs
// ──────────────────────────────────────────────
final allergieDaoProvider = Provider<AllergieDao>((ref) => AllergieDao());
final contactUrgenceDaoProvider = Provider<ContactUrgenceDao>((ref) => ContactUrgenceDao());

// ──────────────────────────────────────────────
//  Provider Allergies
// ──────────────────────────────────────────────
class AllergiesNotifier extends AsyncNotifier<List<Allergie>> {
  static const int _patientId = 1;

  @override
  Future<List<Allergie>> build() async {
    return await ref.read(allergieDaoProvider).getAllergies(_patientId);
  }

  Future<void> addAllergie(String libelle, String severite) async {
    final allergie = Allergie(patientId: _patientId, libelle: libelle, severite: severite);
    await ref.read(allergieDaoProvider).insertAllergie(allergie);
    await _syncAllergiesToPatient();
    ref.invalidateSelf();
  }

  Future<void> deleteAllergie(int id) async {
    await ref.read(allergieDaoProvider).deleteAllergie(id);
    await _syncAllergiesToPatient();
    ref.invalidateSelf();
  }

  Future<void> _syncAllergiesToPatient() async {
    final list = await ref.read(allergieDaoProvider).getAllergies(_patientId);
    final allergiesStr = list.map((a) => a.libelle).join(', ');

    final patientDao = ref.read(patientDaoProvider);
    final patient = await patientDao.getPatient();
    if (patient != null) {
      final updatedPatient = Patient(
        id: patient.id,
        nom: patient.nom,
        prenom: patient.prenom,
        dateNaissance: patient.dateNaissance,
        groupeSanguin: patient.groupeSanguin,
        allergies: allergiesStr,
        sexe: patient.sexe,
        taille: patient.taille,
        poids: patient.poids,
        tension: patient.tension,
        nationalite: patient.nationalite,
        imageProfilPath: patient.imageProfilPath,
      );
      await patientDao.insertOrUpdatePatient(updatedPatient);
      // Invalidate to force reload from DB
      ref.invalidate(patientProvider);
    }
  }
}

final allergiesProvider = AsyncNotifierProvider<AllergiesNotifier, List<Allergie>>(
  () => AllergiesNotifier(),
);

// ──────────────────────────────────────────────
//  Provider Contacts d'urgence
// ──────────────────────────────────────────────
class ContactsUrgenceNotifier extends AsyncNotifier<List<ContactUrgence>> {
  static const int _patientId = 1;

  @override
  Future<List<ContactUrgence>> build() async {
    return await ref.read(contactUrgenceDaoProvider).getContacts(_patientId);
  }

  Future<void> addContact(String nom, String relation, String telephone) async {
    final contact = ContactUrgence(
      patientId: _patientId,
      nom: nom,
      relation: relation,
      telephone: telephone,
    );
    await ref.read(contactUrgenceDaoProvider).insertContact(contact);
    ref.invalidateSelf();
  }

  Future<void> deleteContact(int id) async {
    await ref.read(contactUrgenceDaoProvider).deleteContact(id);
    ref.invalidateSelf();
  }
}

final contactsUrgenceProvider = AsyncNotifierProvider<ContactsUrgenceNotifier, List<ContactUrgence>>(
  () => ContactsUrgenceNotifier(),
);
