import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'providers/table_provider.dart';
import 'screens/home_screen.dart';
import 'services/memory_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize appropriate storage based on platform
  if (kIsWeb) {
    // Use in-memory storage for web
    await MemoryStorage.instance.initialize();
  } else {
    // Use SQLite for mobile/desktop
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TableProvider(),
      child: MaterialApp(
        title: 'Table Tally Local',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
