// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_database/firebase_database.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   await Firebase.initializeApp(
//     options: const FirebaseOptions(
//       apiKey: "AIzaSyCZXM9U8SEdUc2NL0MDit9_f_4D_T00XSA",
//       appId: "1:1048063220188:web:c02adf2fead81115d71719",
//       messagingSenderId: "1048063220188",
//       projectId: "medicine-reminder-3e937",
//       databaseURL:
//           "https://medicine-reminder-3e937-default-rtdb.asia-southeast1.firebasedatabase.app",
//     ),
//   );

//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const MaterialApp(
//       home: Dashboard(),
//     );
//   }
// }

// class Dashboard extends StatefulWidget {
//   const Dashboard({super.key});

//   @override
//   State<Dashboard> createState() => _DashboardState();
// }

// class _DashboardState extends State<Dashboard> {
//   bool isOnline = false;
//   int lastSeen = 0;

//   final DatabaseReference dbRef =
//       FirebaseDatabase.instance.ref("patients/patient_01");

//   Map<String, dynamic> schedule = {};

//   @override
//   void initState() {
//     super.initState();

//     dbRef.onValue.listen((event) {
//       final data = event.snapshot.value as Map<dynamic, dynamic>;

//       final sched = data['schedule'] as Map<dynamic, dynamic>;
//       final seen = data['last_seen'] ?? 0;

//       final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

//       setState(() {
//         schedule = Map<String, dynamic>.from(sched);
//         lastSeen = seen;
//         isOnline = (now - seen) <= 30;
//       });
//     });
//   }

//   String formatLastSeen(int epochSeconds) {
//     if (epochSeconds == 0) {
//       return "Never";
//     }

//     final dateTime = DateTime.fromMillisecondsSinceEpoch(epochSeconds * 1000);

//     return "${dateTime.day}-${dateTime.month}-${dateTime.year} "
//         "${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Medicine Schedule")),
//       body: Column(
//         children: [
//           // 👇 DEVICE STATUS CARD (TOP)
//           deviceStatusCard(),

//           // 👇 SCHEDULE LIST (BELOW)
//           Expanded(
//             child: schedule.isEmpty
//                 ? const Center(child: Text("No schedule found"))
//                 : ListView(
//                     padding: const EdgeInsets.all(16),
//                     children: schedule.entries.map((entry) {
//                       return Card(
//                         child: ListTile(
//                           leading: const Icon(Icons.medication),
//                           title: Text(
//                             entry.key.replaceAll("_", ":"),
//                             style: const TextStyle(fontSize: 18),
//                           ),
//                           trailing: Text(
//                             entry.value.toString().toUpperCase(),
//                             style: const TextStyle(
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                       );
//                     }).toList(),
//                   ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget deviceStatusCard() {
//     return Card(
//       margin: const EdgeInsets.all(16),
//       elevation: 3,
//       color: isOnline ? Colors.green[50] : Colors.red[50],
//       child: ListTile(
//         leading: Icon(
//           isOnline ? Icons.wifi : Icons.wifi_off,
//           color: isOnline ? Colors.green : Colors.red,
//           size: 28,
//         ),
//         title: Text(
//           isOnline ? "Device Online" : "Device Offline",
//           style: const TextStyle(
//             fontWeight: FontWeight.bold,
//             fontSize: 18,
//           ),
//         ),
//         subtitle: Text(
//           "Last seen: ${formatLastSeen(lastSeen)}",
//           style: const TextStyle(fontSize: 14),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'utils/notification_service.dart';
import 'auth/login_page.dart';
import 'auth/role_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCZXM9U8SEdUc2NL0MDit9_f_4D_T00XSA",
      appId: "1:1048063220188:web:c02adf2fead81115d71719",
      messagingSenderId: "1048063220188",
      projectId: "medicine-reminder-3e937",
      databaseURL:
          "https://medicine-reminder-3e937-default-rtdb.asia-southeast1.firebasedatabase.app",
    ),
  );
  await NotificationService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData) {
            return const RoleRouter();
          } else {
            return const LoginPage();
          }
        },
      ),
    );
  }
}
