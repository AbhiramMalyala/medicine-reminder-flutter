import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../auth/login_page.dart';
import '../utils/notification_service.dart';

class PatientDashboard extends StatefulWidget {
  const PatientDashboard({super.key});

  @override
  State<PatientDashboard> createState() => _PatientDashboardState();
}

class _PatientDashboardState extends State<PatientDashboard>
    with SingleTickerProviderStateMixin {
  String patientId = "";
  Map<String, dynamic> schedule = {};
  bool isLoading = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _loadPatient();
  }

  Future<void> _loadPatient() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final snap = await FirebaseDatabase.instance
        .ref("users/$uid/linked_patient_id")
        .get();

    if (!snap.exists) {
      setState(() => isLoading = false);
      return;
    }

    patientId = snap.value.toString();

    FirebaseDatabase.instance
        .ref("patients/$patientId/schedule")
        .onValue
        .listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) {
        setState(() => isLoading = false);
        return;
      }

      final updated = Map<String, dynamic>.from(data);

      for (final time in updated.keys) {
        final dose = Map<String, dynamic>.from(updated[time]);
        if (dose['status'] == 'missed' && dose['notified'] == true) {
          NotificationService.showMissedDoseNotification(
            "Missed Medicine",
            "You missed your medicine at ${time.replaceAll("_", ":")}",
          );
        }
      }

      setState(() {
        schedule = updated;
        isLoading = false;
      });

      _animationController.forward();
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

  IconData statusIcon(String status) {
    switch (status) {
      case "taken":
        return Icons.check_circle;
      case "taken_late":
        return Icons.schedule;
      case "missed":
        return Icons.cancel;
      default:
        return Icons.access_time;
    }
  }

  String statusText(String status) {
    if (status == "taken_late") return "TAKEN (LATE)";
    return status.toUpperCase();
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (r) => false,
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade600, Colors.cyan.shade600],
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "My Medication",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          user?.email ?? "",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: Colors.white),
                  ),
                ],
              ),
            ),

            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: schedule.length,
                      itemBuilder: (context, index) {
                        final entries = schedule.entries.toList()
                          ..sort((a, b) => a.key.compareTo(b.key));
                        final entry = entries[index];
                        final dose =
                            Map<String, dynamic>.from(entry.value);
                        final status = dose['status'] ?? 'pending';
                        final color = statusColor(status);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.2),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(statusIcon(status),
                                        color: Colors.white),
                                    const SizedBox(height: 4),
                                    Text(
                                      entry.key.replaceAll("_", ":"),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),

                              /// 🔥 FIXED OVERFLOW SECTION
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Medicine Time",
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      entry.key.replaceAll("_", ":"),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.15),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        statusText(status),
                                        style: TextStyle(
                                          color: color,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    if (status == 'missed') ...[
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.warning_amber_rounded,
                                            size: 16,
                                            color: Colors.red,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              "Please take immediately",
                                              maxLines: 1,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.red,
                                                fontWeight:
                                                    FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
