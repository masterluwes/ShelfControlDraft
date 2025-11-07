import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shelf_control/services/firestore_service.dart';
import 'package:shelf_control/models/waste_report_model.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ViewReportsPage extends StatelessWidget {
  const ViewReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final householdId = firestoreService.selectedHouseholdId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Waste Reports'),
      ),
      body: householdId == null
          ? const Center(child: Text('No household selected.'))
          : StreamBuilder<List<WasteReportModel>>(
              stream: firestoreService.getWasteReportsForHousehold(householdId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No reports found.'));
                }

                final reports = snapshot.data!;

                return ListView.builder(
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    final formattedDate = DateFormat('MMMM d, yyyy').format(report.generatedAt);

                    return ListTile(
                      title: Text('Report - $formattedDate'),
                      subtitle: Text(
                          '${report.totalWastedItems} items wasted, ₱${report.totalWasteCost.toStringAsFixed(2)} cost'),
                      trailing: const Icon(Icons.picture_as_pdf),
                      onTap: () async {
                        final url = await firestoreService.getReportPdfUrl(report.pdfStoragePath);
                        if (url != null) {
                          if (await canLaunchUrl(Uri.parse(url))) {
                            await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Could not open report.')),
                            );
                          }
                        }
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
