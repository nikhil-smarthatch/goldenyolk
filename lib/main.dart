import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Database seeding disabled - app starts with empty data
  
  runApp(
    const ProviderScope(
      child: PoultryProApp(),
    ),
  );
}
