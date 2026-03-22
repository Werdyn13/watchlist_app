import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/home_page.dart';

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://wunzqgjbjpkiuitgtbxd.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind1bnpxZ2pianBraXVpdGd0YnhkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMwNDgwNDQsImV4cCI6MjA4ODYyNDA0NH0.bduqb7R2OHM7yuVgmBBLWnjuA-1MrgK8qTtjk64L_Bs',
  );

  runApp(const WatchlistApp());
}

class WatchlistApp extends StatelessWidget {
  const WatchlistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Watchlist',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),

        textTheme: GoogleFonts.poppinsTextTheme(
          ThemeData.dark().textTheme,
        ),

        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.redAccent,
          brightness: Brightness.dark,
        ),
      ),

      home: const HomePage(),
    );
  }
}