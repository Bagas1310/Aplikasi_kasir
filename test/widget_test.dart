import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mykasir/views/auth/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:mykasir/providers/auth_provider.dart';

void main() {
  testWidgets('Renders LoginScreen in initial state', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    expect(find.text('Pendaftaran Pemilik Usaha'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsNothing);
  });
}
