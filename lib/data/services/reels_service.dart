import 'dart:convert';
import 'package:elcontrasteapp/data/models/reel_model.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ReelsService {
  // Endpoint del backend auto-alojado (Astro + VPS)
  static const String _baseUrl = 'www.elcontraste.co';
  static const String _endpoint = '/api/v1/reels.json';
  // Endpoint para un reel individual (usado por el deep link elcontraste://reel/{id})
  // ⚠️ Pendiente de confirmar/crear en el backend: debe devolver el objeto
  // del reel directamente (mismos campos que cada item de "reels" en
  // reels.json), NO envuelto en {reels: [...]}.
  static const String _singleReelPath = '/api/v1/reels';

  /// Obtiene una página de reels del servidor.
  ///
  /// [limit]: cantidad de reels a traer (default 10).
  /// [cursor]: string de paginación (timestamp del último reel de la página anterior).
  ///          Si es null, trae la primera página.
  ///
  /// Retorna un record con:
  /// - reels: lista de Reel parseados
  /// - nextCursor: string para la próxima página, o null si no hay más reels
  Future<({List<Reel> reels, String? nextCursor})> fetchReels({
    int limit = 10,
    String? cursor,
  }) async {
    try {
      // Armamos los query params. Si cursor es null, no lo incluimos.
      final queryParams = {
        'limit': limit.toString(),
        if (cursor != null) 'cursor': cursor,
      };

      // Uri.https construye la URL de forma segura
      final url = Uri.https(_baseUrl, _endpoint, queryParams);

      debugPrint('ReelsService: pidiendo reels desde $url');

      final response = await http.get(url);

      if (response.statusCode != 200) {
        debugPrint(
          'ReelsService: error HTTP ${response.statusCode} al pedir reels. '
          'Cuerpo: ${response.body}',
        );
        throw Exception('Error al cargar reels (HTTP ${response.statusCode})');
      }

      // Parseamos el JSON
      final data = json.decode(response.body) as Map<String, dynamic>;

      // Esperamos un objeto con { reels: [...], nextCursor: "..." o null }
      final reelsList = (data['reels'] as List<dynamic>)
          .map((json) => Reel.fromJson(json as Map<String, dynamic>))
          .toList();

      final nextCursor = data['nextCursor'] as String?;

      debugPrint(
        'ReelsService: traídos ${reelsList.length} reels. '
        'nextCursor=$nextCursor',
      );

      return (reels: reelsList, nextCursor: nextCursor);
    } catch (e) {
      debugPrint('ReelsService: excepción al pedir reels: $e');
      rethrow; // Deja que la excepción suba al Cubit
    }
  }

  /// Obtiene un único reel por su [id]. Se usa al abrir la app desde un
  /// deep link (elcontraste://reel/{id}) o desde una notificación.
  ///
  /// Requiere que el backend exponga `GET /api/v1/reels/{id}.json`
  /// devolviendo el objeto del reel directamente (mismo shape que cada
  /// item de "reels" en reels.json).
  Future<Reel> fetchReelById(String id) async {
    final url = Uri.https(_baseUrl, '$_singleReelPath/$id.json');

    debugPrint('ReelsService: pidiendo reel individual desde $url');

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception(
        'Error al cargar el reel $id (HTTP ${response.statusCode})',
      );
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    return Reel.fromJson(data);
  }

  /// Da like a un reel. Requiere que el backend implemente
  /// `POST /api/v1/reels/{id}/like` con body `{device_id}`, devolviendo
  /// `{likes_count: N}`.
  ///
  /// ⚠️ Este endpoint todavía no existe en el backend (pendiente de
  /// coordinar). Por eso devuelve `null` en vez de lanzar una excepción
  /// si falla — quien llame debe tratar `null` como "no se pudo
  /// sincronizar con el servidor, pero el like local ya quedó guardado".
  Future<int?> likeReel(String id, String deviceId) =>
      _postLikeAction(id, deviceId, 'like');

  /// Quita el like de un reel. Requiere `POST /api/v1/reels/{id}/unlike`
  /// con el mismo shape que [likeReel]. Ver las notas de ese método.
  Future<int?> unlikeReel(String id, String deviceId) =>
      _postLikeAction(id, deviceId, 'unlike');

  Future<int?> _postLikeAction(
    String id,
    String deviceId,
    String action,
  ) async {
    try {
      final url = Uri.https(_baseUrl, '$_singleReelPath/$id/$action');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'device_id': deviceId}),
      );

      if (response.statusCode != 200) {
        debugPrint(
          'ReelsService: $action falló con HTTP ${response.statusCode}',
        );
        return null;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      return data['likes_count'] as int?;
    } catch (e) {
      debugPrint('ReelsService: no se pudo sincronizar "$action": $e');
      return null;
    }
  }
}
