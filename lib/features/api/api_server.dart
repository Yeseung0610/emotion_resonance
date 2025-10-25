import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import '../../shared/models/stay_data.dart';
import '../../shared/utils/logger.dart';
import 'data_store.dart';

class ApiServer {
  final int port;
  final DataStore _dataStore = DataStore();
  HttpServer? _server;

  ApiServer({this.port = 8080});

  /// Start the API server
  Future<void> start() async {
    final router = Router();

    // POST /api/staytime - Receive stay time data from mobile
    router.post('/api/staytime', (Request request) async {
      try {
        final bodyString = await request.readAsString();
        final body = jsonDecode(bodyString) as Map<String, dynamic>;

        final stayData = StayData.fromJson(body);
        _dataStore.updateStayData(stayData);

        Logger.success(
          'Received data from ${stayData.deviceId}: ${stayData.cornerTimes}',
          tag: 'API',
        );

        return Response.ok(
          jsonEncode({'status': 'ok'}),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        Logger.error('Error processing POST request: $e', tag: 'API');
        return Response.internalServerError(
          body: jsonEncode({'error': e.toString()}),
          headers: {'Content-Type': 'application/json'},
        );
      }
    });

    // GET /api/staytime - Get all stay time data
    router.get('/api/staytime', (Request request) {
      try {
        final allData = _dataStore.getAllStayData();

        return Response.ok(
          jsonEncode(allData),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        Logger.error('Error processing GET request: $e', tag: 'API');
        return Response.internalServerError(
          body: jsonEncode({'error': e.toString()}),
          headers: {'Content-Type': 'application/json'},
        );
      }
    });

    // GET /api/staytime/:deviceId - Get stay time data for specific device
    router.get('/api/staytime/<deviceId>', (Request request, String deviceId) {
      try {
        final data = _dataStore.getStayData(deviceId);

        if (data == null) {
          return Response.notFound(
            jsonEncode({'error': 'Device not found'}),
            headers: {'Content-Type': 'application/json'},
          );
        }

        return Response.ok(
          jsonEncode(data),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        Logger.error('Error processing GET request: $e', tag: 'API');
        return Response.internalServerError(
          body: jsonEncode({'error': e.toString()}),
          headers: {'Content-Type': 'application/json'},
        );
      }
    });

    // Health check endpoint
    router.get('/health', (Request request) {
      return Response.ok(
        jsonEncode({'status': 'healthy', 'timestamp': DateTime.now().toIso8601String()}),
        headers: {'Content-Type': 'application/json'},
      );
    });

    // Create handler with CORS support
    final handler = Pipeline()
        .addMiddleware(corsHeaders())
        .addMiddleware(logRequests())
        .addHandler(router.call);

    // Start server
    _server = await shelf_io.serve(
      handler,
      InternetAddress.anyIPv4,
      port,
    );

    Logger.success('API Server running on http://${_server!.address.host}:${_server!.port}', tag: 'SERVER');
    Logger.info('Endpoints:', tag: 'SERVER');
    Logger.info('  POST /api/staytime', tag: 'SERVER');
    Logger.info('  GET  /api/staytime', tag: 'SERVER');
    Logger.info('  GET  /api/staytime/:deviceId', tag: 'SERVER');
    Logger.info('  GET  /health', tag: 'SERVER');
  }

  /// Stop the API server
  Future<void> stop() async {
    await _server?.close(force: true);
    Logger.info('API Server stopped', tag: 'SERVER');
  }
}
