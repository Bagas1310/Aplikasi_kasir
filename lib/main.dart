import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'views/auth/login_screen.dart';
import 'views/main_navigation_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyKasirApp());
}

class MyKasirApp extends StatelessWidget {
  const MyKasirApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkInit()),
      ],
      child: MaterialApp(
        title: 'POS Kasir Mobile',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF15803D),
            primary: const Color(0xFF15803D),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFF8FAFC),
          cardTheme: const CardThemeData(
            color: Colors.white,
            elevation: 0,
          ),
          appBarTheme: const AppBarTheme(
            elevation: 0,
            backgroundColor: Colors.white,
            scrolledUnderElevation: 1,
            surfaceTintColor: Colors.transparent,
          ),
        ),
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.isLoading) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (!auth.isAuthenticated) {
              return const LoginScreen();
            }
            return const MainNavigationScreen();
          },
        ),
      ),
    );
  }
}
