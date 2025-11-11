import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class MenuApp extends StatelessWidget {
  const MenuApp({super.key});

  Future<void> _launchURL(String url, BuildContext context) async {
    if (!context.mounted) return; // Verifica si el widget sigue montado

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      debugPrint('No se pudo abrir $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF0B375E)),
            child: Text(
              'El Contraste App',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          /*ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Inicio'),
            onTap: () {
              Navigator.pop(context); // Cierra el Drawer
              if (ModalRoute.of(context)?.settings.name != '/') {
                Navigator.pushReplacementNamed(context, '/'); // Navega solo si no estás en la pantalla de inicio
              }
            },
          ),*/
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
                leading: const FaIcon(
                  FontAwesomeIcons.xTwitter,
                  //color: Colors.blue,
                ),
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
              const phone = '3136902821'; // Número de WhatsApp
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
        ],
      ),
    );
  }
}
