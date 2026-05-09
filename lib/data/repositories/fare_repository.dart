import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fare_config.dart';

class FareRepository {
  static const String _key = 'fare_config';

  Future<FareConfig> getConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);

    if (jsonString == null) return const FareConfig();

    try {
      return FareConfig.fromJson(jsonDecode(jsonString));
    } catch (e) {
      return const FareConfig();
    }
  }

  Future<void> saveConfig(FareConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(config.toJson()));
  }
}
