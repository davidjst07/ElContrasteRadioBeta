import 'dart:convert';
import 'package:elcontrasteapp/data/models/reel_model.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ReelsService {
  // Endpoint del backend auto-alojado (Astro + VPS)
  static const String _baseUrl = 'www.elcontraste.co';
  static const String _endpoint = '/api/v1/reels.json';

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
        throw Exception(
          'Error al cargar reels (HTTP ${response.statusCode})',
        );
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
}
