import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trip_draft.dart';

/// Guarda/lee el punto de control de la carrera en curso (una sola a la vez).
class TripDraftRepository {
  static const String _key = 'active_trip_draft';

  Future<void> save(TripDraft draft) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(draft.toJson()));
    } catch (_) {
      // Guardar el borrador es un extra: nunca debe romper la carrera.
    }
  }

  Future<TripDraft?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return null;
      return TripDraft.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Borrador dañado: se descarta.
      await clear();
      return null;
    }
  }

  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }
}
