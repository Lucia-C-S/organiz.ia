import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/pantry_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/storage_provider.dart';
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => StorageProvider()),
        ChangeNotifierProvider(create: (_) => PantryProvider()..loadItems()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return MaterialApp(
            title: 'Organiz.IA Pantry',
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
            home: authProvider.isInitializing
                ? const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  )
                : (authProvider.isSignedIn ? const PantryHomePage() : const AuthScreen()),
          );
        },
      ),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _isSignUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  void _submit(AuthProvider authProvider) async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (_isSignUp && _displayNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a display name')),
      );
      return;
    }

    bool success;
    if (_isSignUp) {
      success = await authProvider.signUp(
        email: _emailController.text,
        password: _passwordController.text,
        displayName: _displayNameController.text,
      );
    } else {
      success = await authProvider.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
    }

    if (!mounted) return;

    if (!success && authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSignUp ? 'Sign Up' : 'Sign In'),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Text(
                  'Organiz.IA',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 40),
                if (_isSignUp)
                  TextField(
                    controller: _displayNameController,
                    decoration: const InputDecoration(
                      labelText: 'Display Name',
                      hintText: 'Enter your name',
                    ),
                  ),
                if (_isSignUp) const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: authProvider.isLoading
                      ? null
                      : () => _submit(authProvider),
                  child: authProvider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_isSignUp ? 'Sign Up' : 'Sign In'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isSignUp = !_isSignUp;
                      _emailController.clear();
                      _passwordController.clear();
                      _displayNameController.clear();
                      authProvider.clearError();
                    });
                  },
                  child: Text(
                    _isSignUp
                        ? 'Already have an account? Sign In'
                        : 'Don\'t have an account? Sign Up',
                  ),
                ),
              ],
            ),
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
