import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../shared/utils/logger.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _serverUrlController = TextEditingController();
  final _deviceIdController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    final serverUrl = await SettingsService.getServerUrl();
    final deviceId = await SettingsService.getDeviceId();

    _serverUrlController.text = serverUrl;
    _deviceIdController.text = deviceId;

    setState(() => _isLoading = false);
  }

  Future<void> _saveSettings() async {
    final serverUrl = _serverUrlController.text.trim();
    final deviceId = _deviceIdController.text.trim();

    if (serverUrl.isEmpty) {
      _showError('Server URL cannot be empty');
      return;
    }

    if (deviceId.isEmpty) {
      _showError('Device ID cannot be empty');
      return;
    }

    // Validate URL format
    if (!serverUrl.startsWith('http://') && !serverUrl.startsWith('https://')) {
      _showError('Server URL must start with http:// or https://');
      return;
    }

    await SettingsService.setServerUrl(serverUrl);
    await SettingsService.setDeviceId(deviceId);

    Logger.success('Settings saved: $serverUrl, $deviceId', tag: 'SETTINGS');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _resetSettings() async {
    await SettingsService.resetSettings();
    await _loadSettings();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings reset to default'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _deviceIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetSettings,
            tooltip: 'Reset to defaults',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Server URL section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.dns, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(
                                'Server Configuration',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _serverUrlController,
                            decoration: const InputDecoration(
                              labelText: 'Server URL',
                              hintText: 'http://192.168.0.10:8080',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.link),
                              helperText: 'Enter the API server URL',
                            ),
                            keyboardType: TextInputType.url,
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.info_outline,
                                        size: 16, color: Colors.blue[700]),
                                    const SizedBox(width: 8),
                                    Text(
                                      'How to find your server URL:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  '1. Start the server with: dart run bin/server.dart',
                                  style: TextStyle(fontSize: 12),
                                ),
                                const Text(
                                  '2. Look for "Mobile App Configuration"',
                                  style: TextStyle(fontSize: 12),
                                ),
                                const Text(
                                  '3. Copy the URL shown there',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Device ID section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.phone_android,
                                  color: Colors.green),
                              const SizedBox(width: 8),
                              Text(
                                'Device Configuration',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _deviceIdController,
                            decoration: const InputDecoration(
                              labelText: 'Device ID',
                              hintText: 'mobile_01',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.badge),
                              helperText: 'Unique identifier for this device',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveSettings,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Settings'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
