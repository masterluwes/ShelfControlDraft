import 'dart:convert';
import 'dart:io'; // Import dart:io for platform checks
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart'; // Import the logger package
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences

class OpenFoodFactsService {
  static const String _baseUrl = 'https://world.openfoodfacts.org/api/v2/product/';
  final Logger _logger = Logger(); // Initialize logger
  // Removed in-memory cache, will use SharedPreferences for persistent cache
  // final Map<String, String?> _nutriScoreCache = {}; 

  static const String _nutriScoreCacheKey = 'nutriScoreCache';

  // Helper to load the entire cache from SharedPreferences
  Future<Map<String, String?>> _loadNutriScoreCache() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encodedData = prefs.getString(_nutriScoreCacheKey);
    if (encodedData == null) {
      return {};
    }
    final Map<String, dynamic> decodedData = json.decode(encodedData);
    return decodedData.map((key, value) => MapEntry(key, value as String?));
  }

  // Helper to save the entire cache to SharedPreferences
  Future<void> _saveNutriScoreCache(Map<String, String?> cache) async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = json.encode(cache);
    await prefs.setString(_nutriScoreCacheKey, encodedData);
  }

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

  // Function to search products with various filters
  Future<List<Map<String, dynamic>>> searchProducts({
    required String query,
    String? country,
    List<String>? brands,
    List<String>? nutriScoreGrades,
    List<String>? ecoscoreGrades,
    List<String>? categories,
    int page = 1,
    int pageSize = 20,
  }) async {
    final Map<String, dynamic> queryParams = {
      'search_terms': query,
      'search_simple': '1',
      'action': 'process',
      'json': '1',
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };

    if (country != null) queryParams['countries_tags'] = 'en:$country';
    if (brands != null && brands.isNotEmpty) queryParams['brands_tags'] = brands.map((b) => b.toLowerCase()).join(',');
    if (nutriScoreGrades != null && nutriScoreGrades.isNotEmpty) queryParams['nutriscore_grade'] = nutriScoreGrades.map((n) => n.toLowerCase()).join(',');
    if (ecoscoreGrades != null && ecoscoreGrades.isNotEmpty) queryParams['ecoscore_grade'] = ecoscoreGrades.map((e) => e.toLowerCase()).join(',');
    if (categories != null && categories.isNotEmpty) queryParams['categories_tags'] = categories.map((c) => c.toLowerCase()).join(',');

    final searchUrl = Uri.https('world.openfoodfacts.org', '/cgi/search.pl', queryParams);

    String platform = 'Unknown';
    if (Platform.isAndroid) {
      platform = 'Android';
    } else if (Platform.isIOS) {
      platform = 'iOS';
    } else if (Platform.isLinux) {
      platform = 'Linux';
    } else if (Platform.isMacOS) {
      platform = 'macOS';
    } else if (Platform.isWindows) {
      platform = 'Windows';
    }

    try {
      final response = await http.get(
        searchUrl,
        headers: {
          'User-Agent': 'ShelfControl - $platform - Version 1.0',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['products'] != null && data['products'].isNotEmpty) {
          return List<Map<String, dynamic>>.from(data['products']);
        } else {
          _logger.i('No products found for search query: $query');
          return [];
        }
      } else {
        _logger.w('Failed to search products for query $query. Status code: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      _logger.e('Error searching products for query $query: $e');
      return [];
    }
  }

  // Function to get Nutri-score and Ecoscore for a product by name, leveraging searchProducts
  Future<Map<String, String?>?> getNutriAndEcoScore(String productName, {String? brand, String? category}) async {
    final Map<String, String?> nutriScoreCache = await _loadNutriScoreCache();
    final String cacheKey = '${productName}_${brand ?? ''}_${category ?? ''}_nutri_eco';

    // Check cache first
    if (nutriScoreCache.containsKey(cacheKey)) {
      _logger.d('Nutri-score and Ecoscore for "$productName" (brand: ${brand ?? 'N/A'}, category: ${category ?? 'N/A'}) found in cache.');
      final cachedValue = nutriScoreCache[cacheKey];
      if (cachedValue != null) {
        final parts = cachedValue.split('|');
        return {'nutriScore': parts[0], 'ecoscore': parts.length > 1 ? parts[1] : null};
      }
      return null;
    }

    List<Map<String, dynamic>> products = [];

    // Prepare all search futures to run in parallel
    final List<Future<List<Map<String, dynamic>>>> allSearchFutures = [];

    // Attempt 1: Search with brand and category
    _logger.i('Attempt 1: Searching for "$productName" with brand: ${brand ?? 'N/A'}, category: ${category ?? 'N/A'}');
    allSearchFutures.add(searchProducts(
      query: productName,
      brands: brand != null ? [brand] : null,
      categories: category != null ? [category] : null,
      pageSize: 1,
    ));

    // Attempt 2: Search with brand only (if brand is available)
    if (brand != null) {
      _logger.i('Attempt 2: Searching with brand only for: $productName (brand: $brand)');
      allSearchFutures.add(searchProducts(
        query: productName,
        brands: [brand],
        pageSize: 1,
      ));
    }

    // Attempt 3: Search with category only (if category is available)
    if (category != null) {
      _logger.i('Attempt 3: Searching with category only for: $productName (category: $category)');
      allSearchFutures.add(searchProducts(
        query: productName,
        categories: [category],
        pageSize: 1,
      ));
    }

    // Attempt 4: Search with product name only
    _logger.i('Attempt 4: Searching with product name only for: $productName');
    allSearchFutures.add(searchProducts(
      query: productName,
      pageSize: 1,
    ));

    // Wait for all search futures to complete
    final List<List<Map<String, dynamic>>> results = await Future.wait(allSearchFutures);

    // Process results in order of preference
    for (final resultList in results) {
      if (resultList.isNotEmpty) {
        products = resultList;
        break; // Found a product, use this result
      }
    }

    if (products.isNotEmpty) {
      final product = products[0];
      final nutriScore = product['nutriscore_grade'] as String?;
      final ecoscore = product['ecoscore_grade'] as String?;

      final cacheValue = '${nutriScore ?? ''}|${ecoscore ?? ''}';
      nutriScoreCache[cacheKey] = cacheValue; // Cache the result
      await _saveNutriScoreCache(nutriScoreCache); // Save updated cache
      return {'nutriScore': nutriScore, 'ecoscore': ecoscore};
    } else {
      _logger.i('No product found for name: $productName (brand: ${brand ?? 'N/A'}, category: ${category ?? 'N/A'}) after all attempts.');
      nutriScoreCache[cacheKey] = '|'; // Cache null to avoid repeated searches
      await _saveNutriScoreCache(nutriScoreCache); // Save updated cache
      return null;
    }
  }

  // Helper function to clean product names for better API matching
  Map<String, String?> cleanProductName(String fullProductName) {
    String cleanedName = fullProductName;
    String? brand;

    // Remove net weight/volume information (e.g., "| 946ml", "234g", "234 g", "1.5L")
    cleanedName = cleanedName.replaceAll(RegExp(r'\|\s*\d+\.?\d*\s*(ml|g|kg|pcs|oz|fl oz|L)\b', caseSensitive: false), '');
    cleanedName = cleanedName.replaceAll(RegExp(r'\b\d+\.?\d*\s*(ml|g|kg|pcs|oz|fl oz|L)\b', caseSensitive: false), '');
    cleanedName = cleanedName.replaceAll(RegExp(r'\s*\[.*?\]\s*', caseSensitive: false), ''); // Remove content in brackets

    // Remove common packaging terms
    cleanedName = cleanedName.replaceAll(RegExp(r'\b(pack|box|can|bottle|jar|bag|pouch|sachet|tub|carton|roll)\b', caseSensitive: false), '');

    // Attempt to extract brand (simple heuristic: first word if common brand, or look for common brand names)
    final List<String> commonBrands = ['Knorr', 'Purefoods', 'SM Bonus', 'Magnolia', 'Nestlé', 'Alaska', 'CDO', 'Bounty Fresh', 'Coles', 'Sunkist'];
    String? extractedBrand;
    for (String b in commonBrands) {
      if (cleanedName.toLowerCase().contains(b.toLowerCase())) {
        extractedBrand = b;
        // If the brand is at the beginning, remove it from the cleaned name
        if (cleanedName.toLowerCase().startsWith(b.toLowerCase())) {
          cleanedName = cleanedName.substring(b.length).trim();
        }
        break;
      }
    }
    brand = extractedBrand; // Assign to the brand variable

    // Remove extra spaces and trim
    cleanedName = cleanedName.replaceAll(RegExp(r'\s+'), ' ').trim();

    return {'name': cleanedName, 'brand': brand};
  }
}
