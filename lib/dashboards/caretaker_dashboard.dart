import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../auth/login_page.dart';
import '../utils/notification_service.dart';
import 'patient_detail_dashboard.dart';

class CaretakerDashboard extends StatefulWidget {
  const CaretakerDashboard({super.key});

  @override
  State<CaretakerDashboard> createState() => _CaretakerDashboardState();
}

class _CaretakerDashboardState extends State<CaretakerDashboard>
    with SingleTickerProviderStateMixin {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  List<String> patientIds = [];
  Map<String, Map<String, dynamic>> patientStats = {};
  Timer? timer;
  late AnimationController _animationController;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() => isLoading = true);

    final snap =
        await FirebaseDatabase.instance.ref("users/$uid/linked_patients").get();

    if (!snap.exists) {
      setState(() => isLoading = false);
      return;
    }

    patientIds = Map<String, dynamic>.from(snap.value as Map).keys.toList();

    // Load stats for each patient
    for (final pid in patientIds) {
      await _loadPatientStats(pid);
    }

    setState(() => isLoading = false);
    _animationController.forward();

    timer = Timer.periodic(const Duration(minutes: 1), (_) => _checkMissed());
  }

  Future<void> _loadPatientStats(String patientId) async {
    final snap = await FirebaseDatabase.instance
        .ref("patients/$patientId/schedule")
        .get();

    if (!snap.exists) return;

    final schedule = Map<String, dynamic>.from(snap.value as Map);
    int total = schedule.length;
    int taken = 0;
    int missed = 0;
    int pending = 0;

    for (final entry in schedule.values) {
      final dose = Map<String, dynamic>.from(entry);
      final status = dose['status'] ?? 'pending';

      if (status == 'taken' || status == 'taken_late') {
        taken++;
      } else if (status == 'missed') {
        missed++;
      } else {
        pending++;
      }
    }

    patientStats[patientId] = {
      'total': total,
      'taken': taken,
      'missed': missed,
      'pending': pending,
      'compliance': total > 0 ? (taken / total * 100).round() : 0,
    };
  }

  Future<void> _checkMissed() async {
    final now = DateTime.now();

    for (final pid in patientIds) {
      final snap =
          await FirebaseDatabase.instance.ref("patients/$pid/schedule").get();

      if (!snap.exists) continue;
      final schedule = Map<String, dynamic>.from(snap.value as Map);

      for (final time in schedule.keys) {
        final dose = Map<String, dynamic>.from(schedule[time]);
        final status = dose['status'] ?? 'pending';
        final timestamp = dose['timestamp'] ?? 0;

        if (status == 'taken' || status == 'taken_late' || timestamp != 0) {
          continue;
        }

        final parts = time.split("_");
        final scheduled = DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );

        if (now.isAfter(scheduled)) {
          await FirebaseDatabase.instance
              .ref("patients/$pid/schedule/$time")
              .update({
            "status": "missed",
            "notified": true,
          });

          NotificationService.showMissedDoseNotification(
            "Missed Medicine",
            "Patient ${pid.replaceAll("_", " ")} missed tablet at ${time.replaceAll("_", ":")}",
          );

          // Reload stats
          await _loadPatientStats(pid);
          setState(() {});
        }
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (r) => false,
        );
      }
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String patientId) {
    final stats = patientStats[patientId];
    if (stats == null) return Colors.grey;

    final missed = stats['missed'] as int;
    final compliance = stats['compliance'] as int;

    if (missed >= 2) return Colors.red;
    if (compliance >= 80) return Colors.green;
    return Colors.orange;
  }

  IconData _getStatusIcon(String patientId) {
    final stats = patientStats[patientId];
    if (stats == null) return Icons.info_outline;

    final missed = stats['missed'] as int;
    final compliance = stats['compliance'] as int;

    if (missed >= 2) return Icons.warning_amber_rounded;
    if (compliance >= 80) return Icons.check_circle_outline;
    return Icons.info_outline;
  }

  String _getStatusText(String patientId) {
    final stats = patientStats[patientId];
    if (stats == null) return "Loading...";

    final missed = stats['missed'] as int;
    final compliance = stats['compliance'] as int;

    if (missed >= 2) return "Critical";
    if (compliance >= 80) return "Good";
    return "Needs Attention";
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.indigo.shade50,
              Colors.purple.shade50,
              Colors.pink.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.indigo.shade600, Colors.purple.shade600],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.indigo.shade200,
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(
                                Icons.health_and_safety,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Caretaker Portal",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  user?.email ?? "Unknown",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout_rounded),
                          color: Colors.white,
                          iconSize: 28,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Stats Summary
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            "Total Patients",
                            patientIds.length.toString(),
                            Icons.people,
                            Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            "Critical",
                            patientStats.values
                                .where((s) => (s['missed'] as int) >= 2)
                                .length
                                .toString(),
                            Icons.warning_amber_rounded,
                            Colors.redAccent,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            "Compliant",
                            patientStats.values
                                .where((s) => (s['compliance'] as int) >= 80)
                                .length
                                .toString(),
                            Icons.check_circle,
                            Colors.greenAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Patient List
              Expanded(
                child: isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: Colors.indigo.shade600,
                              strokeWidth: 3,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Loading patients...",
                              style: TextStyle(
                                color: Colors.indigo.shade600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : patientIds.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: 80,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "No patients assigned",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadPatients,
                            color: Colors.indigo.shade600,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemCount: patientIds.length,
                              itemBuilder: (context, i) {
                                final pid = patientIds[i];
                                final stats = patientStats[pid];
                                final statusColor = _getStatusColor(pid);

                                return FadeTransition(
                                  opacity: Tween<double>(begin: 0.0, end: 1.0)
                                      .animate(
                                    CurvedAnimation(
                                      parent: _animationController,
                                      curve: Interval(
                                        i * 0.1,
                                        1.0,
                                        curve: Curves.easeOut,
                                      ),
                                    ),
                                  ),
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 0.3),
                                      end: Offset.zero,
                                    ).animate(
                                      CurvedAnimation(
                                        parent: _animationController,
                                        curve: Interval(
                                          i * 0.1,
                                          1.0,
                                          curve: Curves.easeOut,
                                        ),
                                      ),
                                    ),
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: statusColor.withOpacity(0.2),
                                            blurRadius: 15,
                                            offset: const Offset(0, 5),
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    PatientDetailDashboard(
                                                        patientId: pid),
                                              ),
                                            );
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(20),
                                            child: Column(
                                              children: [
                                                Row(
                                                  children: [
                                                    // Patient Avatar
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              16),
                                                      decoration: BoxDecoration(
                                                        gradient:
                                                            LinearGradient(
                                                          colors: [
                                                            statusColor,
                                                            statusColor
                                                                .withOpacity(
                                                                    0.7),
                                                          ],
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(18),
                                                      ),
                                                      child: Icon(
                                                        _getStatusIcon(pid),
                                                        color: Colors.white,
                                                        size: 32,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    // Patient Info
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            pid
                                                                .replaceAll(
                                                                    "_", " ")
                                                                .toUpperCase(),
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 18,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: Colors
                                                                  .black87,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              height: 4),
                                                          Wrap(
                                                            spacing: 8,
                                                            runSpacing: 4,
                                                            crossAxisAlignment:
                                                                WrapCrossAlignment
                                                                    .center,
                                                            children: [
                                                              Container(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .symmetric(
                                                                  horizontal: 8,
                                                                  vertical: 4,
                                                                ),
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: statusColor
                                                                      .withOpacity(
                                                                          0.2),
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              8),
                                                                ),
                                                                child: Text(
                                                                  _getStatusText(
                                                                      pid),
                                                                  style:
                                                                      TextStyle(
                                                                    color:
                                                                        statusColor,
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                  ),
                                                                ),
                                                              ),
                                                              if (stats != null)
                                                                Text(
                                                                  "${stats['compliance']}%",
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    color: Colors
                                                                        .grey
                                                                        .shade600,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                  ),
                                                                ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    Icon(
                                                      Icons
                                                          .arrow_forward_ios_rounded,
                                                      color:
                                                          Colors.grey.shade400,
                                                      size: 20,
                                                    ),
                                                  ],
                                                ),
                                                if (stats != null) ...[
                                                  const SizedBox(height: 16),
                                                  const Divider(),
                                                  const SizedBox(height: 12),
                                                  // Stats Row
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceAround,
                                                    children: [
                                                      _buildMiniStat(
                                                        "Taken",
                                                        stats['taken']
                                                            .toString(),
                                                        Colors.green,
                                                        Icons.check_circle,
                                                      ),
                                                      _buildMiniStat(
                                                        "Missed",
                                                        stats['missed']
                                                            .toString(),
                                                        Colors.red,
                                                        Icons.cancel,
                                                      ),
                                                      _buildMiniStat(
                                                        "Pending",
                                                        stats['pending']
                                                            .toString(),
                                                        Colors.orange,
                                                        Icons.schedule,
                                                      ),
                                                      _buildMiniStat(
                                                        "Total",
                                                        stats['total']
                                                            .toString(),
                                                        Colors.blue,
                                                        Icons.medication,
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(
      String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
