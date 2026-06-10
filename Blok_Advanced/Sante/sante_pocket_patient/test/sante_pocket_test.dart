import 'package:flutter_test/flutter_test.dart';
import 'package:sante_pocket/models/patient.dart';
import 'package:sante_pocket/models/vaccination.dart';
import 'package:sante_pocket/models/symptome.dart';
import 'package:sante_pocket/models/allergie.dart';
import 'package:sante_pocket/models/contact_urgence.dart';
import 'package:sante_pocket/models/consultation.dart';
import 'package:sante_pocket/models/ordonnance.dart';
import 'package:sante_pocket/models/examen_analyse.dart';
import 'package:sante_pocket/features/sync/sync_service.dart';

void main() {
  group('Sante Pocket Models & Serialization Tests', () {
    test('Patient Model Serialization/Deserialization with New Properties', () {
      final patient = Patient(
        id: 1,
        nom: 'Dupont',
        prenom: 'Jean',
        dateNaissance: '12/05/1984',
        groupeSanguin: 'O+',
        allergies: 'Pénicilline',
        sexe: 'Masculin',
        taille: '180 cm',
        poids: '75 kg',
        tension: '12/8',
        nationalite: 'Française',
        imageProfilPath: '/path/to/profile.png',
      );

      final map = patient.toMap();
      expect(map['id'], 1);
      expect(map['nom'], 'Dupont');
      expect(map['sexe'], 'Masculin');
      expect(map['groupe_sanguin'], 'O+');
      expect(map['nationalite'], 'Française');
      expect(map['image_profil_path'], '/path/to/profile.png');

      final fromMap = Patient.fromMap(map);
      expect(fromMap.id, 1);
      expect(fromMap.nom, 'Dupont');
      expect(fromMap.prenom, 'Jean');
      expect(fromMap.dateNaissance, '12/05/1984');
      expect(fromMap.groupeSanguin, 'O+');
      expect(fromMap.allergies, 'Pénicilline');
      expect(fromMap.sexe, 'Masculin');
      expect(fromMap.taille, '180 cm');
      expect(fromMap.poids, '75 kg');
      expect(fromMap.tension, '12/8');
      expect(fromMap.nationalite, 'Française');
      expect(fromMap.imageProfilPath, '/path/to/profile.png');
    });

    test('Patient Model Default Values', () {
      final patient = Patient(
        id: 2,
        nom: 'Martin',
        prenom: 'Sophie',
        dateNaissance: '25/12/1990',
        groupeSanguin: 'A-',
        allergies: 'Aucune',
      );

      expect(patient.sexe, '');
      expect(patient.taille, '');
      expect(patient.poids, '');
      expect(patient.tension, '');
      expect(patient.nationalite, '');
      expect(patient.imageProfilPath, '');

      final map = patient.toMap();
      final fromMap = Patient.fromMap(map);
      expect(fromMap.sexe, '');
      expect(fromMap.nationalite, '');
      expect(fromMap.imageProfilPath, '');
    });

    test('Vaccination Model Serialization/Deserialization', () {
      final vacc = Vaccination(
        id: 42,
        patientId: 1,
        vaccin: 'Tétanos',
        date: '01/01/2026',
        prochainRappel: '01/01/2036',
        statutValidation: 'VALIDE',
      );

      final map = vacc.toMap();
      expect(map['id'], 42);
      expect(map['vaccin'], 'Tétanos');
      expect(map['prochain_rappel'], '01/01/2036');
      expect(map['statut_validation'], 'VALIDE');

      final fromMap = Vaccination.fromMap(map);
      expect(fromMap.id, 42);
      expect(fromMap.vaccin, 'Tétanos');
      expect(fromMap.prochainRappel, '01/01/2036');
      expect(fromMap.statutValidation, 'VALIDE');
    });

    test('Symptome Model Default values & Serialization', () {
      final sym = Symptome(
        id: 10,
        patientId: 1,
        date: '03/06/2026',
        description: 'Maux de tête intenses',
        statutValidation: 'EN_ATTENTE',
      );

      final map = sym.toMap();
      expect(map['id'], 10);
      expect(map['description'], 'Maux de tête intenses');
      expect(map['statut_validation'], 'EN_ATTENTE');

      final fromMap = Symptome.fromMap(map);
      expect(fromMap.id, 10);
      expect(fromMap.patientId, 1);
      expect(fromMap.date, '03/06/2026');
      expect(fromMap.description, 'Maux de tête intenses');
      expect(fromMap.statutValidation, 'EN_ATTENTE');
    });

    test('Allergie Model Serialization', () {
      final allergie = Allergie(
        id: 5,
        patientId: 1,
        libelle: 'Lactose',
        severite: 'Modérée',
      );

      final map = allergie.toMap();
      expect(map['id'], 5);
      expect(map['libelle'], 'Lactose');
      expect(map['severite'], 'Modérée');

      final fromMap = Allergie.fromMap(map);
      expect(fromMap.id, 5);
      expect(fromMap.libelle, 'Lactose');
      expect(fromMap.severite, 'Modérée');
    });

    test('ContactUrgence Model Serialization', () {
      final contact = ContactUrgence(
        id: 2,
        patientId: 1,
        nom: 'Marie Dupont',
        relation: 'Épouse',
        telephone: '0612345678',
      );

      final map = contact.toMap();
      expect(map['id'], 2);
      expect(map['nom'], 'Marie Dupont');
      expect(map['relation'], 'Épouse');
      expect(map['telephone'], '0612345678');

      final fromMap = ContactUrgence.fromMap(map);
      expect(fromMap.id, 2);
      expect(fromMap.nom, 'Marie Dupont');
      expect(fromMap.relation, 'Épouse');
      expect(fromMap.telephone, '0612345678');
    });

    test('Consultation Model Serialization/Deserialization', () {
      final consult = Consultation(
        id: 3,
        patientId: 1,
        medecinId: 4,
        date: '02/06/2026',
        diagnostic: 'Angine blanche',
        notes: 'Prendre du paracétamol',
        statutValidation: 'Validé',
        signatureMedecin: '{"signature": "Dr. Smith"}',
      );

      final map = consult.toMap();
      expect(map['id'], 3);
      expect(map['patient_id'], 1);
      expect(map['medecin_id'], 4);
      expect(map['date'], '02/06/2026');
      expect(map['diagnostic'], 'Angine blanche');
      expect(map['notes'], 'Prendre du paracétamol');
      expect(map['statut_validation'], 'Validé');
      expect(map['signature_medecin'], '{"signature": "Dr. Smith"}');

      final fromMap = Consultation.fromMap(map);
      expect(fromMap.id, 3);
      expect(fromMap.patientId, 1);
      expect(fromMap.medecinId, 4);
      expect(fromMap.date, '02/06/2026');
      expect(fromMap.diagnostic, 'Angine blanche');
      expect(fromMap.notes, 'Prendre du paracétamol');
      expect(fromMap.statutValidation, 'Validé');
      expect(fromMap.signatureMedecin, '{"signature": "Dr. Smith"}');
    });

    test('Ordonnance Model Serialization/Deserialization', () {
      final ordonnance = Ordonnance(
        id: 7,
        consultationId: 3,
        medicaments: '[{"nom": "Amoxicilline"}]',
        posologie: '1g 3x/jour',
        duree: '6 jours',
      );

      final map = ordonnance.toMap();
      expect(map['id'], 7);
      expect(map['consultation_id'], 3);
      expect(map['medicaments'], '[{"nom": "Amoxicilline"}]');
      expect(map['posologie'], '1g 3x/jour');
      expect(map['duree'], '6 jours');

      final fromMap = Ordonnance.fromMap(map);
      expect(fromMap.id, 7);
      expect(fromMap.consultationId, 3);
      expect(fromMap.medicaments, '[{"nom": "Amoxicilline"}]');
      expect(fromMap.posologie, '1g 3x/jour');
      expect(fromMap.duree, '6 jours');
    });

    test('ExamenAnalyse Model Serialization/Deserialization', () {
      final examen = ExamenAnalyse(
        id: 9,
        patientId: 1,
        type: 'Prise de sang',
        resultatPdfPath: '/path/to/blood_test.pdf',
        commentaire: 'Tout est normal',
      );

      final map = examen.toMap();
      expect(map['id'], 9);
      expect(map['patient_id'], 1);
      expect(map['type'], 'Prise de sang');
      expect(map['resultat_pdf_path'], '/path/to/blood_test.pdf');
      expect(map['commentaire'], 'Tout est normal');

      final fromMap = ExamenAnalyse.fromMap(map);
      expect(fromMap.id, 9);
      expect(fromMap.patientId, 1);
      expect(fromMap.type, 'Prise de sang');
      expect(fromMap.resultatPdfPath, '/path/to/blood_test.pdf');
      expect(fromMap.commentaire, 'Tout est normal');
    });
  });

  group('SyncService & Utils Tests', () {
    test('Format File Size Helper', () {
      expect(SyncService.formatFileSize(500), '500 o');
      expect(SyncService.formatFileSize(1024), '1.0 Ko');
      expect(SyncService.formatFileSize(512 * 1024), '512.0 Ko');
      expect(SyncService.formatFileSize(1024 * 1024), '1.0 Mo');
      expect(SyncService.formatFileSize(2048 * 1024 * 1024), '2048.0 Mo');
    });
  });
}
