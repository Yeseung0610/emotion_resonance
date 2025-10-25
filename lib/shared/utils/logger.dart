/// Simple logger utility
class Logger {
  static void log(String message, {String tag = 'APP'}) {
    final timestamp = DateTime.now().toIso8601String();
    print('[$timestamp] [$tag] $message');
  }

  static void error(String message, {String tag = 'ERROR'}) {
    final timestamp = DateTime.now().toIso8601String();
    print('[$timestamp] [$tag] ❌ $message');
  }

  static void success(String message, {String tag = 'SUCCESS'}) {
    final timestamp = DateTime.now().toIso8601String();
    print('[$timestamp] [$tag] ✅ $message');
  }

  static void info(String message, {String tag = 'INFO'}) {
    final timestamp = DateTime.now().toIso8601String();
    print('[$timestamp] [$tag] ℹ️ $message');
  }
}
