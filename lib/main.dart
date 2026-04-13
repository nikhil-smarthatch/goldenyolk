import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/error_logger.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize error logging
  await ErrorLogger.instance.init();
  
  // Catch unhandled errors
  FlutterError.onError = (FlutterErrorDetails details) {
    ErrorLogger.instance.log(
      'Unhandled Flutter error',
      error: details.exception,
      stackTrace: details.stack,
    );
    FlutterError.presentError(details);
  };
  
  runApp(
    const ProviderScope(
      child: PoultryProApp(),
    ),
  );
}
