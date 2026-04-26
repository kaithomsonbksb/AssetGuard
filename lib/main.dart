import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'screens/login_screen.dart';
import 'screens/job_list_screen.dart';
import 'screens/inspection_detail_screen.dart';

void main() {
  // Initialize database factory for FFI (required for Windows/Linux/macOS)
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  
  runApp(const AssetGuardApp());
}

class AssetGuardApp extends StatelessWidget {
  const AssetGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AssetGuard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/jobs': (context) => const JobListScreen(),
        '/inspection': (context) {
          // get job from route arguments
          final job = ModalRoute.of(context)!.settings.arguments;
          return InspectionDetailScreen(job: job as dynamic);
        },
      },
    );
  }
}