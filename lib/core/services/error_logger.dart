import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ErrorLogger {
  static final ErrorLogger _instance = ErrorLogger._internal();
  static ErrorLogger get instance => _instance;
  
  File? _logFile;
  
  ErrorLogger._internal();

  Future<void> init() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      _logFile = File('${directory.path}/error_logs.txt');
      
      // Create file if it doesn't exist
      if (!await _logFile!.exists()) {
        await _logFile!.create();
        await log('Error logging initialized', level: 'INFO');
      }
    } catch (e) {
      print('Failed to initialize error logger: $e');
    }
  }

  Future<void> log(String message, {String level = 'ERROR', Object? error, StackTrace? stackTrace}) async {
    try {
      if (_logFile == null) await init();
      
      final timestamp = DateTime.now().toIso8601String();
      final buffer = StringBuffer();
      
      buffer.writeln('[$timestamp] [$level] $message');
      
      if (error != null) {
        buffer.writeln('Error: $error');
      }
      
      if (stackTrace != null) {
        buffer.writeln('StackTrace: $stackTrace');
      }
      
      buffer.writeln('-' * 50);
      
      await _logFile!.writeAsString(
        buffer.toString(),
        mode: FileMode.append,
      );
      
      // Also print to console in debug mode
      print(buffer.toString());
    } catch (e) {
      print('Failed to write log: $e');
    }
  }

  Future<String> getLogs() async {
    try {
      if (_logFile == null) await init();
      if (await _logFile!.exists()) {
        return await _logFile!.readAsString();
      }
      return 'No logs available';
    } catch (e) {
      return 'Error reading logs: $e';
    }
  }

  Future<void> clearLogs() async {
    try {
      if (_logFile == null) await init();
      await _logFile!.writeAsString('');
      await log('Logs cleared', level: 'INFO');
    } catch (e) {
      print('Failed to clear logs: $e');
    }
  }

  Future<String> getLogFilePath() async {
    if (_logFile == null) await init();
    return _logFile!.path;
  }
}

// Global function for easy error logging
Future<void> logError(String message, {Object? error, StackTrace? stackTrace}) async {
  await ErrorLogger.instance.log(message, error: error, stackTrace: stackTrace);
}
