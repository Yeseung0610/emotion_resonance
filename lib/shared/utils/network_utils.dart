import 'dart:io';
import 'logger.dart';

class NetworkUtils {
  /// Get all network interfaces and their IP addresses
  static Future<List<String>> getLocalIPAddresses() async {
    final List<String> addresses = [];

    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          // Skip loopback addresses
          if (!addr.isLoopback) {
            addresses.add(addr.address);
          }
        }
      }
    } catch (e) {
      print('Error getting network interfaces: $e');
    }

    return addresses;
  }

  /// Get the primary network IP (usually the first non-loopback IPv4)
  static Future<String?> getPrimaryIPAddress() async {
    final addresses = await getLocalIPAddresses();
    return addresses.isNotEmpty ? addresses.first : null;
  }

  /// Print all available network addresses
  static Future<void> printNetworkInfo() async {
    final addresses = await getLocalIPAddresses();

    if (addresses.isEmpty) {
      Logger.info('No network interfaces found', tag: 'NETWORK');
      return;
    }

    Logger.info('Available network addresses:', tag: 'NETWORK');
    for (var addr in addresses) {
      Logger.info('  - $addr', tag: 'NETWORK');
    }
  }
}
