import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class PatientDetailDashboard extends StatefulWidget {
  final String patientId;
  const PatientDetailDashboard({super.key, required this.patientId});

  @override
  State<PatientDetailDashboard> createState() => _PatientDetailDashboardState();
}

class _PatientDetailDashboardState extends State<PatientDetailDashboard> {
  Map<String, dynamic> schedule = {};

  @override
  void initState() {
    super.initState();
    FirebaseDatabase.instance
        .ref("patients/${widget.patientId}/schedule")
        .onValue
        .listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return;
      setState(() => schedule = Map<String, dynamic>.from(data));
    });
  }

  Color statusColor(String status) {
    switch (status) {
      case "taken":
        return Colors.green;
      case "taken_late":
        return Colors.blue;
      case "missed":
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String statusText(String status) {
    if (status == "taken_late") return "TAKEN (LATE)";
    return status.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(widget.patientId.replaceAll("_", " ").toUpperCase()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: schedule.entries.map((e) {
          final dose = Map<String, dynamic>.from(e.value);
          final status = dose['status'] ?? 'pending';

          return Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: statusColor(status).withOpacity(0.15),
                child: Icon(Icons.medical_services, color: statusColor(status)),
              ),
              title: Text(
                e.key.replaceAll("_", ":"),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              trailing: Text(
                statusText(status),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: statusColor(status),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
