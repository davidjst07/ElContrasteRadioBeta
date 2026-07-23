import 'dart:io';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

import 'package:elcontrasteapp/main.dart';

class AppUpdateService {
  static Future<void> checkForUpdate() async {
    if (!Platform.isAndroid) return;
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return;
      }

      final forceImmediate = await _shouldForceImmediate();

      if (forceImmediate && info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
        return;
      }

      if (info.flexibleUpdateAllowed) {
        final result = await InAppUpdate.startFlexibleUpdate();
        if (result == AppUpdateResult.success) {
          _showRestartBanner();
        }
      }
    } catch (e) {
      debugPrint('Error revisando actualizaciones: $e');
    }
  }

  static Future<bool> _shouldForceImmediate() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );
      await remoteConfig.setDefaults({'force_immediate_update': false});
      await remoteConfig.fetchAndActivate();
      return remoteConfig.getBool('force_immediate_update');
    } catch (e) {
      debugPrint('No se pudo leer Remote Config: $e');
      return false;
    }
  }

  static void _showRestartBanner() {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        content: const Text(
          'Hay una actualización lista. Reinicia para aplicarla.',
        ),
        actions: [
          TextButton(
            onPressed: () => InAppUpdate.completeFlexibleUpdate(),
            child: const Text('REINICIAR'),
          ),
          TextButton(
            onPressed: () =>
                ScaffoldMessenger.of(context).hideCurrentMaterialBanner(),
            child: const Text('DESPUÉS'),
          ),
        ],
      ),
    );
  }
}
