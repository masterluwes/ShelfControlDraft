import 'dart:convert';
import 'dart:io'; // Import dart:io for platform checks
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart'; // Import the logger package

class OpenFoodFactsService {
  static const String _baseUrl = 'https://world.openfoodfacts.org/api/v2/product/';
  final Logger _logger = Logger(); // Initialize logger

  // Function to fetch product data by barcode
  Future<Map<String, dynamic>?> fetchProductByBarcode(String barcode) async {
    final url = Uri.parse('$_baseUrl$barcode.json');

    // Determine the platform for the User-Agent
    String platform = 'Unknown';
    if (Platform.isAndroid) {
      platform = 'Android';
    } else if (Platform.isIOS) {
      platform = 'iOS';
    } else if (Platform.isFuchsia) {
      platform = 'Fuchsia';
    } else if (Platform.isLinux) {
      platform = 'Linux';
    } else if (Platform.isMacOS) {
      platform = 'macOS';
    } else if (Platform.isWindows) {
      platform = 'Windows';
    }

    try {
      final response = await http.get(
        url,
        headers: {
          // Set a custom User-Agent to identify our app
          'User-Agent': 'ShelfControl - $platform - Version 1.0',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 1 && data['product'] != null) {
          return data['product'];
        } else {
          _logger.i('Product not found for barcode: $barcode'); // Use logger.i for info
          return null;
        }
      } else {
        _logger.w('Failed to load product for barcode $barcode. Status code: ${response.statusCode}'); // Use logger.w for warnings
        return null;
      }
    } catch (e) {
      _logger.e('Error fetching product for barcode $barcode: $e'); // Use logger.e for errors
      return null;
    }
  }

  // You can add more functions here for other Open Food Facts API interactions if needed.
}
