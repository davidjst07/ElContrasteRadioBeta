import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'package:elcontrasteapp/core/constants/news_categories.dart';
import 'package:elcontrasteapp/core/di/service_locator.dart';
import 'package:elcontrasteapp/data/local/notification_prefs_store.dart';

class NotificationPreferencesPage extends StatefulWidget {
  const NotificationPreferencesPage({super.key});

  @override
  State<NotificationPreferencesPage> createState() =>
      _NotificationPreferencesPageState();
}

class _NotificationPreferencesPageState
    extends State<NotificationPreferencesPage> {
  Set<int>? _subscribedCategoryIds;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ids = await getIt<NotificationPrefsStore>()
        .getSubscribedCategoryIds();
    if (!mounted) return;
    setState(() => _subscribedCategoryIds = ids);
  }

  Future<void> _onChanged(int categoryId, bool value) async {
    setState(() {
      if (value) {
        _subscribedCategoryIds?.add(categoryId);
      } else {
        _subscribedCategoryIds?.remove(categoryId);
      }
    });

    final topic = 'categoria_$categoryId';
    try {
      if (value) {
        await FirebaseMessaging.instance.subscribeToTopic(topic);
      } else {
        await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
      }
      await getIt<NotificationPrefsStore>().setSubscribed(categoryId, value);
    } catch (e) {
      debugPrint('Error cambiando suscripción a $topic: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscribed = _subscribedCategoryIds;
    final categoryEntries = newsCategories.entries
        .where((entry) => entry.value != null)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Preferencias de notificaciones')),
      body: subscribed == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Recibes notificaciones generales de todas formas. '
                    'Activa una categoría si además quieres avisos '
                    'específicos de esa zona.',
                  ),
                ),
                for (final entry in categoryEntries)
                  SwitchListTile(
                    title: Text(entry.key),
                    value: subscribed.contains(entry.value),
                    onChanged: (value) => _onChanged(entry.value!, value),
                  ),
              ],
            ),
    );
  }
}
