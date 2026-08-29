import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/pantry_provider.dart';
import 'screens/home_screen.dart';
import 'screens/pantry_map_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/settings_screen.dart';

Future<void> main() async {
WidgetsFlutterBinding.ensureInitialized();

try {
   // On Android/iOS, Firebase will use the config from google-services.json / GoogleService-Info.plist.
   // The app also supports a fallback to generated FirebaseOptions if they are later added by FlutterFire.
   if (Firebase.apps.isEmpty) {
     await Firebase.initializeApp();
   }
} catch (error) {
   debugPrint('Firebase initialization failed: $error');
}

runApp(const PantryApp());
}

class PantryApp extends StatelessWidget {
  const PantryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PantryProvider()..loadItems(),
      child: Consumer<PantryProvider>(
        builder: (context, provider, child) {
          return MaterialApp(
            title: provider.profileName.isNotEmpty ? provider.profileName : 'Organiz.IA Pantry',
            theme: ThemeData(
              useMaterial3: true,

              colorScheme: ColorScheme.light(
                primary: const Color.fromARGB(209, 107, 90, 71),
                secondary: const Color.fromARGB(110, 23, 72, 35),
                surface: const Color.fromARGB(112, 245, 242, 236),
                ),
              scaffoldBackgroundColor: Color.fromARGB(210, 107, 90, 71),
              
                    textTheme: const TextTheme(

    // Large page titles
    headlineLarge: TextStyle(
      fontFamily: 'titulo',
      fontSize: 34,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),

    // Section titles
    titleMedium: TextStyle(
      fontFamily: 'subtitulo',
      fontSize: 24,
      color: Colors.white,
    ),

    // Regular body text
    bodyLarge: TextStyle(
      fontFamily: 'letra',
      fontSize: 18,
      color: Colors.white,
    ),

    bodyMedium: TextStyle(
      fontFamily: 'letra',
      fontSize: 16,
      color: Colors.white,
    ),

    labelLarge: TextStyle(
      fontFamily: 'subtitulo',
      fontSize: 16,
    ),
  ),
              
              cardTheme: CardThemeData(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            home: const PantryHomePage(),
          );
        },
      ),
    );
  }
}

class PantryHomePage extends StatefulWidget {
  const PantryHomePage({super.key});

  @override
  State<PantryHomePage> createState() => _PantryHomePageState();
}

class _PantryHomePageState extends State<PantryHomePage> {
  int _selectedIndex = 0;
 
  static const _pages = [
    HomeScreen(),
    PantryMapScreen(),
    CalendarScreen(),
    ScanScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.map), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.calendar_month), label: 'Calendar'),
          NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
