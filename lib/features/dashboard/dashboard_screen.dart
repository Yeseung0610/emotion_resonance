import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../shared/utils/logger.dart';

class DashboardScreen extends StatefulWidget {
  final String serverUrl;

  const DashboardScreen({
    super.key,
    this.serverUrl = 'http://localhost:8080',
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, Map<String, int>> _allDeviceData = {};
  Timer? _refreshTimer;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _refreshData();
    // Auto-refresh every 2 seconds
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _refreshData(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshData() async {
    try {
      final response = await http.get(
        Uri.parse('${widget.serverUrl}/api/staytime'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _allDeviceData = data.map(
            (key, value) => MapEntry(
              key,
              Map<String, int>.from(value as Map),
            ),
          );
          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = 'Server returned ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      Logger.error('Error fetching data: $e', tag: 'DASHBOARD');
      setState(() {
        _errorMessage = 'Failed to connect to server';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('감정 잔향 전시 대시보드'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refreshData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_allDeviceData.isEmpty) {
      return const Center(
        child: Text(
          'No data available\nWaiting for devices...',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _allDeviceData.length,
      itemBuilder: (context, index) {
        final deviceId = _allDeviceData.keys.elementAt(index);
        final cornerTimes = _allDeviceData[deviceId]!;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Device: $deviceId',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildCornerGrid(cornerTimes),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCornerGrid(Map<String, int> cornerTimes) {
    final topLeft = cornerTimes['top-left'] ?? 0;
    final topRight = cornerTimes['top-right'] ?? 0;
    final bottomLeft = cornerTimes['bottom-left'] ?? 0;
    final bottomRight = cornerTimes['bottom-right'] ?? 0;

    final maxTime = [topLeft, topRight, bottomLeft, bottomRight]
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        _buildCornerCard('Top Left', topLeft, maxTime),
        _buildCornerCard('Top Right', topRight, maxTime),
        _buildCornerCard('Bottom Left', bottomLeft, maxTime),
        _buildCornerCard('Bottom Right', bottomRight, maxTime),
      ],
    );
  }

  Widget _buildCornerCard(String label, int seconds, double maxTime) {
    final intensity = maxTime > 0 ? seconds / maxTime : 0.0;
    final color = Color.lerp(
      Colors.blue[100],
      Colors.blue[900],
      intensity,
    )!;

    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.blue[700]!,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: intensity > 0.5 ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '${seconds}s',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: intensity > 0.5 ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
