import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/job_list_screen.dart';
import 'screens/inspection_detail_screen.dart';

void main() {
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
          // et job from route arguments
          final job = ModalRoute.of(context)!.settings.arguments;
          return InspectionDetailScreen(job: job as dynamic);
        },
      },
    );
  }
}