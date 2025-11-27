import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/home/home_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'services/auth_service.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const TeamForgeApp());
}

class TeamForgeApp extends StatelessWidget {
  const TeamForgeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'TeamForge AI',
        theme: burntSiennaTheme(),
        routes: {
          '/login': (_) => const LoginScreen(),
          '/register': (_) => const RegisterScreen(),
          '/home': (_) => const HomeScreen(),
        },
        home: const RootPage(),
      ),
    );
  }
}

class RootPage extends StatelessWidget {
  const RootPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);

    return StreamBuilder(
      stream: auth.authState,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}

//
// 🔥 THEME (BURNT SIENNA PALETTE)
//
ThemeData burntSiennaTheme() {
  return ThemeData(
    useMaterial3: true,

    // Color scheme from Burnt Sienna palette
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFFE35336),        // Burnt Sienna
      onPrimary: Colors.white,
      secondary: Color(0xFFF4A460),      // Soft Orange
      onSecondary: Colors.white,
      tertiary: Color(0xFFA0522D),       // Deep Brown
      onTertiary: Colors.white,
      error: Color(0xFFE53935),
      onError: Colors.white,
      background: Color(0xFFF5F5DC),     // Light Cream
      onBackground: Colors.black87,
      surface: Color(0xFFF5F5DC),
      onSurface: Colors.black87,
    ),

    scaffoldBackgroundColor: const Color(0xFFF5F5DC),

    // Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE35336),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),

    // TextField Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(color: Color(0xFFA0522D)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE35336)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE35336), width: 2),
      ),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFE35336),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
  );
}
