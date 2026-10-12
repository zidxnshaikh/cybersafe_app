import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'providers/threat_provider.dart';
import 'screens/emergency_guide_screen.dart';
import 'screens/history_screen.dart';
import 'screens/password_auditor_screen.dart';
import 'screens/scam_simulator_screen.dart';
import 'screens/threat_scanner_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThreatProvider(),
      child: const CyberSafeApp(),
    ),
  );
}

class CyberSafeApp extends StatelessWidget {
  const CyberSafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF10B981);
    return MaterialApp(
      title: 'CyberSafe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF090D16),
        colorScheme: const ColorScheme.dark(
          primary: accent,
          secondary: Color(0xFF06B6D4),
          surface: Color(0xFF111827),
          error: Color(0xFFEF4444),
          onPrimary: Colors.black,
        ),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          ThemeData.dark().textTheme,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1A2234),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const CyberSafeHomeScreen(),
    );
  }
}

class CyberSafeHomeScreen extends StatefulWidget {
  const CyberSafeHomeScreen({super.key});

  @override
  State<CyberSafeHomeScreen> createState() => _CyberSafeHomeScreenState();
}

class _CyberSafeHomeScreenState extends State<CyberSafeHomeScreen> {
  int _currentIndex = 0;

  static const _screens = [
    ThreatScannerScreen(),
    PasswordAuditorScreen(),
    ScamSimulatorScreen(),
    EmergencyGuideScreen(),
    HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF090D16),
        centerTitle: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  const Icon(Icons.shield, color: Color(0xFF10B981), size: 20),
            ),
            const SizedBox(width: 12),
            const Text('CyberSafe',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.phone_in_talk,
                          color: Colors.redAccent, size: 14),
                      SizedBox(width: 6),
                      Text('1930 Helpline',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          )),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: const Color(0xFF111827),
        indicatorColor: const Color(0xFF10B981).withValues(alpha: 0.2),
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.search), label: 'Scanner'),
          NavigationDestination(
              icon: Icon(Icons.lock_outline), label: 'Password'),
          NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline), label: 'Practice'),
          NavigationDestination(
              icon: Icon(Icons.sos_outlined), label: 'Emergency'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
        ],
      ),
    );
  }
}
