import 'package:elcontrasteapp/core/themes/app_theme.dart';
import 'package:elcontrasteapp/presentation/blocs/notifications/notifications_bloc.dart';
import 'package:elcontrasteapp/presentation/pages/favorites/favorites_page.dart';
import 'package:elcontrasteapp/presentation/pages/notifications/notification_preferences_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class MenuApp extends StatelessWidget {
  const MenuApp({super.key});

  Future<void> _launchURL(String url, BuildContext context) async {
    if (!context.mounted) return;

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('No se pudo abrir $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: AppColors.navyAppbar),
            child: const Text(
              'El Contraste App',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),

          ExpansionTile(
            leading: const Icon(Icons.link),
            title: const Text('Síguenos'),
            children: [
              ListTile(
                leading: const Icon(Icons.facebook, color: Colors.blueAccent),
                title: const Text('Facebook'),
                onTap: () async {
                  Navigator.pop(context);
                  const fbPageId = '104383095006900';
                  final fbAppUrl = 'fb://page/$fbPageId';
                  final fbWebUrl =
                      'https://www.facebook.com/ElContrasteNoticias';

                  if (await canLaunchUrl(Uri.parse(fbAppUrl))) {
                    await launchUrl(
                      Uri.parse(fbAppUrl),
                      mode: LaunchMode.externalApplication,
                    );
                  } else {
                    await launchUrl(
                      Uri.parse(fbWebUrl),
                      mode: LaunchMode.externalApplication,
                    );
                  }
                },
              ),
              ListTile(
                leading: const FaIcon(FontAwesomeIcons.xTwitter),
                title: const Text('Twitter'),
                onTap: () async {
                  Navigator.pop(context);
                  const twitterAppUrl =
                      'twitter://user?screen_name=elcontrastenoti';
                  const twitterWebUrl = 'https://x.com/elcontrastenoti';

                  if (await canLaunchUrl(Uri.parse(twitterAppUrl))) {
                    await launchUrl(
                      Uri.parse(twitterAppUrl),
                      mode: LaunchMode.externalApplication,
                    );
                  } else if (await canLaunchUrl(Uri.parse(twitterWebUrl))) {
                    await launchUrl(
                      Uri.parse(twitterWebUrl),
                      mode: LaunchMode.externalApplication,
                    );
                  } else {
                    debugPrint(
                      'No se pudo abrir $twitterAppUrl ni $twitterWebUrl',
                    );
                  }
                },
              ),
              ListTile(
                leading: const FaIcon(
                  FontAwesomeIcons.instagram,
                  color: Colors.redAccent,
                ),
                title: const Text('Instagram'),
                onTap: () {
                  Navigator.pop(context);
                  _launchURL(
                    'https://www.instagram.com/elcontrastenoticias/',
                    context,
                  );
                },
              ),
              ListTile(
                leading: const FaIcon(
                  FontAwesomeIcons.youtube,
                  color: Colors.red,
                ),
                title: const Text('YouTube'),
                onTap: () {
                  Navigator.pop(context);
                  _launchURL(
                    'https://www.youtube.com/@ElContrasteNoticias',
                    context,
                  );
                },
              ),
              ListTile(
                leading: const FaIcon(
                  FontAwesomeIcons.tiktok,
                  color: Colors.black,
                ),
                title: const Text('TikTok'),
                onTap: () {
                  Navigator.pop(context);
                  _launchURL(
                    'https://www.tiktok.com/@el.contraste.noti',
                    context,
                  );
                },
              ),
            ],
          ),

          ListTile(
            leading: const FaIcon(
              FontAwesomeIcons.whatsapp,
              color: Colors.green,
            ),
            title: const Text('Contáctanos'),
            onTap: () async {
              Navigator.pop(context);
              const phone = '3136902821';
              const whatsappUrl = 'https://wa.me/$phone';
              if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
                await launchUrl(
                  Uri.parse(whatsappUrl),
                  mode: LaunchMode.externalApplication,
                );
              } else {
                debugPrint('No se pudo abrir WhatsApp');
              }
            },
          ),
          ListTile(
            leading: const FaIcon(
              FontAwesomeIcons.envelope,
              color: Colors.orange,
            ),
            title: const Text('info@elcontraste.co'),
            onTap: () {
              Navigator.pop(context);
              _launchURL('mailto:info@elcontraste.co', context);
            },
          ),
          ListTile(
            leading: const FaIcon(FontAwesomeIcons.globe, color: Colors.blue),
            title: const Text('elcontraste.co'),
            onTap: () {
              Navigator.pop(context);
              _launchURL('https://www.elcontraste.co', context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.bookmark, color: Colors.amber),
            title: const Text('Favoritos'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FavoritesPage()),
              );
            },
          ),

          const Divider(),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                Navigator.pop(context);
                _launchURL('https://jyd-producciones.com/index.html', context);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.75,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.45),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Desarrollada por',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        letterSpacing: 0.8,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.72,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'JYD Producciones',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      Icons.open_in_new,
                      size: 14,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.55,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          BlocBuilder<NotificationsBloc, NotificationsState>(
            builder: (context, state) {
              final isGranted = state.status == AuthorizationStatus.authorized;

              return ListTile(
                leading: const Icon(Icons.settings, color: Colors.grey),
                title: const Text('Notificaciones'),
                subtitle: Text(
                  isGranted ? 'Estado: permitidas' : 'Estado: no permitidas',
                ),
                trailing: IconButton(
                  icon: Icon(
                    isGranted
                        ? Icons.notifications_active
                        : Icons.notifications_off,
                    color: isGranted ? Colors.green : Colors.red,
                  ),
                  onPressed: () {
                    context.read<NotificationsBloc>().requestPermission();
                  },
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.tune, color: Colors.grey),
            title: const Text('Preferencias de notificaciones'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationPreferencesPage(),
                ),
              );
            },
          ),

          BlocBuilder<NotificationsBloc, NotificationsState>(
            builder: (context, state) {
              final notifications = state.notifications;

              if (notifications.isEmpty) {
                return const ListTile(
                  leading: Icon(Icons.notifications_none),
                  title: Text('Sin notificaciones recientes'),
                );
              }

              final lastNotifications = notifications.reversed.take(3).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8,
                    ),
                    child: Text(
                      'Últimas notificaciones',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.titleLarge?.color,
                      ),
                    ),
                  ),
                  ...lastNotifications.map((n) {
                    return ListTile(
                      leading: n.imageUrl != null && n.imageUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                n.imageUrl!,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(
                              Icons.notifications,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                      title: Text(
                        n.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: n.body.isNotEmpty
                          ? Text(
                              n.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                    );
                  }),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
