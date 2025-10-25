import 'package:emotion_resonance/features/api/api_server.dart';
import 'package:emotion_resonance/shared/utils/logger.dart';
import 'package:emotion_resonance/shared/utils/network_utils.dart';

/// Standalone server entry point
/// Run with: dart run bin/server.dart
Future<void> main(List<String> arguments) async {
  Logger.info('Starting Emotion Resonance API Server...', tag: 'MAIN');

  final port = arguments.isNotEmpty ? int.tryParse(arguments[0]) ?? 8080 : 8080;

  final server = ApiServer(port: port);
  await server.start();

  // Display network information
  print('');
  print('━' * 60);
  Logger.success('Server is ready!', tag: 'MAIN');
  print('━' * 60);

  await NetworkUtils.printNetworkInfo();

  final primaryIP = await NetworkUtils.getPrimaryIPAddress();
  if (primaryIP != null) {
    print('');
    print('📱 Mobile App Configuration:');
    print('   Use this URL in your mobile app settings:');
    print('   http://$primaryIP:$port');
    print('');
  }

  print('🌐 Web Dashboard:');
  print('   http://localhost:$port');
  print('');
  print('━' * 60);
  Logger.info('Press Ctrl+C to stop the server', tag: 'MAIN');
  print('━' * 60);
}
