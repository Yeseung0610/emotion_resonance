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
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          '감정 잔향 전시 대시보드',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _refreshData,
              tooltip: 'Refresh',
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF00FF88).withValues(alpha: 0.2),
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 6,
                valueColor: AlwaysStoppedAnimation<Color>(
                  const Color(0xFF00FF88),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Loading...',
              style: TextStyle(
                color: const Color(0xFF00FF88),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.red.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 80,
                color: Colors.red[300],
              ),
              const SizedBox(height: 24),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _refreshData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00FF88),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_allDeviceData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.devices_rounded,
              size: 100,
              color: const Color(0xFF00FF88).withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No data available',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF00FF88),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Waiting for devices...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _allDeviceData.length,
      itemBuilder: (context, index) {
        final deviceId = _allDeviceData.keys.elementAt(index);
        final cornerTimes = _allDeviceData[deviceId]!;

        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1A1A1A),
                const Color(0xFF0D0D0D),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFF00FF88).withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00FF88).withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF00FF88),
                          Color(0xFF00CCFF),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.smartphone_rounded,
                          color: Colors.black,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          deviceId,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildCornerGrid(cornerTimes),
            ],
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
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.2,
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

    // Border color transitions from dim to bright neon based on intensity
    final borderColor = Color.lerp(
      const Color(0xFF00FF88).withValues(alpha: 0.3),
      const Color(0xFF00FF88),
      intensity,
    )!;

    // Glow effect increases with intensity
    final glowOpacity = 0.1 + (intensity * 0.3);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A1A),
            const Color(0xFF0F0F0F),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00FF88).withValues(alpha: glowOpacity),
            blurRadius: 15,
            spreadRadius: intensity > 0.5 ? 3 : 1,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00FF88),
              letterSpacing: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            '${seconds}s',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: const Color(0xFF00FF88).withValues(alpha: 0.5),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          if (intensity > 0)
            Container(
              margin: const EdgeInsets.only(top: 8),
              height: 4,
              width: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF00FF88),
                    const Color(0xFF00CCFF),
                  ],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }
}
