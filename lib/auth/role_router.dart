// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';

// import '../dashboards/patient_dashboard.dart';
// import 'package:medicine_reminder/dashboards/caretaker_dashboard.dart';

// class RoleRouter extends StatefulWidget {
//   const RoleRouter({super.key});

//   @override
//   State<RoleRouter> createState() => _RoleRouterState();
// }

// class _RoleRouterState extends State<RoleRouter> {
//   @override
//   void initState() {
//     super.initState();
//     routeUser();
//   }

//   Future<void> routeUser() async {
//     final uid = FirebaseAuth.instance.currentUser!.uid;

//     final snapshot =
//         await FirebaseDatabase.instance.ref("users/$uid/role").get();

//     final role = snapshot.value.toString();

//     if (role == "patient") {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const PatientDashboard()),
//       );
//     } else {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const CaretakerDashboard()),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return const Scaffold(
//       body: Center(child: CircularProgressIndicator()),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../dashboards/patient_dashboard.dart';
import '../dashboards/caretaker_dashboard.dart';
import 'login_page.dart';

class RoleRouter extends StatefulWidget {
  const RoleRouter({super.key});

  @override
  State<RoleRouter> createState() => _RoleRouterState();
}

class _RoleRouterState extends State<RoleRouter> {
  @override
  void initState() {
    super.initState();
    _routeUser();
  }

  Future<void> _routeUser() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _goToLogin();
      return;
    }

    final uid = user.uid;

    final ref = FirebaseDatabase.instance.ref("users/$uid/role");

    final snapshot = await ref.get();

    if (!snapshot.exists) {
      // No role → logout (safety)
      await FirebaseAuth.instance.signOut();
      _goToLogin();
      return;
    }

    final role = snapshot.value.toString();

    if (!mounted) return;

    if (role == "patient") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const PatientDashboard(),
        ),
      );
    } else if (role == "caretaker") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const CaretakerDashboard(),
        ),
      );
    } else {
      // Unknown role → logout
      await FirebaseAuth.instance.signOut();
      _goToLogin();
    }
  }

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Simple loading screen
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
