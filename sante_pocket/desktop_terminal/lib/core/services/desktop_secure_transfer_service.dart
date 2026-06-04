import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ConnectionStatus { waiting, connected, error }

class TransferState {
  final ConnectionStatus status;
  final Map<String, dynamic>? patientRecord;
  TransferState({this.status = ConnectionStatus.waiting, this.patientRecord});
}

class DesktopSecureTransferService extends Notifier<TransferState> {
  @override
  TransferState build() => TransferState();

  void startListening() {
    state = TransferState(status: ConnectionStatus.connected);
    // Simulate connection for now
    Future.delayed(const Duration(seconds: 2), () {
      state = TransferState(
        status: ConnectionStatus.connected,
        patientRecord: {
          'nom': 'Doe',
          'prenom': 'John',
          'dob': '1990-01-01',
          'allergies': ['Pénicilline', 'Pollens'],
          'groupeSanguin': 'A+',
          'notes': 'Patient asthmatique léger.'
        },
      );
    });
  }
}

final secureTransferServiceProvider = NotifierProvider<DesktopSecureTransferService, TransferState>(() {
  return DesktopSecureTransferService();
});
