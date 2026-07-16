import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:elcontrasteapp/data/models/radio_emission_model.dart';

class EmissionsRepository {
  static const String emissionsUrl = 'https://radio.elcontraste.co/emisiones';

  static Future<List<RadioEmission>> getEmissions() async {
    final response = await http
        .get(
          Uri.parse(emissionsUrl),
          headers: {
            'Accept': 'application/json',
            'User-Agent': 'ElContrasteRadioApp/1.0',
          },
        )
        .timeout(const Duration(seconds: 12));

    if (response.statusCode != 200) {
      throw Exception('Error cargando emisiones: ${response.statusCode}');
    }

    final Map<String, dynamic> json = jsonDecode(response.body);
    final List<dynamic> items = json['emisiones'] ?? [];

    return items
        .map((item) => RadioEmission.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
