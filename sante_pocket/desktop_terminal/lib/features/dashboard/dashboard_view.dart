import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desktop_terminal/core/services/desktop_secure_transfer_service.dart';
import 'package:desktop_terminal/features/consultation/consultation_view.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(secureTransferServiceProvider);
    final service = ref.read(secureTransferServiceProvider.notifier);

    // Effect to handle navigation when data is received
    ref.listen(secureTransferServiceProvider, (previous, next) {
      if (next.status == ConnectionStatus.connected) {
        final record = next.patientRecord;
        if (record != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ConsultationView(patientRecord: record),
            ),
          );
        }
      }
    });

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Status: ${state.status.name.toUpperCase()}',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),
          if (state.status == ConnectionStatus.waiting)
            ElevatedButton(
              onPressed: () => service.startListening(),
              child: const Text('Start Listening'),
            ),
        ],
      ),
    );
  }
}
