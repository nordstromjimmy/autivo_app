import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'revenue_cat_service.dart';

class RevenuecatConfig {
  static String? get revenueCatApiKey => dotenv.env['REVENUE_CAT_API_KEY'];

  static Future<void> initialize() async {
    if (revenueCatApiKey != null) {
      await RevenueCatService().initialize(revenueCatApiKey!);
    } else {
      print('⚠️ RevenueCat API key not found in .env file');
    }
  }
}
