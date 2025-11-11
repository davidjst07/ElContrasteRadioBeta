import 'package:cached_network_image/cached_network_image.dart';
import 'package:elcontrasteapp/presentation/pages/home/post_model.dart';
import 'package:elcontrasteapp/presentation/pages/home/news_service.dart';
import 'package:elcontrasteapp/presentation/pages/home/news_detail_page.dart';
import 'package:elcontrasteapp/presentation/pages/home/video_model.dart';
import 'package:elcontrasteapp/presentation/pages/home/video_player_page.dart';
import 'package:elcontrasteapp/presentation/pages/home/youtube_service.dart';
import 'package:elcontrasteapp/presentation/widgets/menu_app.dart';
import 'package:elcontrasteapp/presentation/widgets/radio_player_widget.dart';

import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = ["Radio", "Noticias", "Videos"];

  // Definimos las categorías de noticias con sus respectivos IDs de WordPress
  final Map<String, int?> _newsCategories = {
    'Últimas': null, // null para obtener todas las noticias
    // NOTA: Los IDs 10 (Pasto) y 11 (Nariño) parecen tener un problema en el servidor de 'elcontraste.co'
    // y no devuelven noticias. Esto es un problema externo a la app que debería ser revisado en el sitio web.
    'Pasto': 2,
    'Nariño': 1,
    // Se ha cambiado el ID 12 por el 17, que corresponde a la categoría 'Nación' en WordPress
    // y sí devuelve los resultados esperados para Colombia.
    'Colombia': 7,
  };
  int? _selectedNewsCategoryId; // Inicia con 'Ultimas Noticias' (null)

  // Lista para almacenar los widgets de las pestañas y cargarlos perezosamente.
  late final List<Widget?> _tabWidgets;

  @override
  void initState() {
    super.initState();
    // Inicializamos la lista con nulls. El tamaño debe coincidir con el número de pestañas.
    _tabWidgets = List<Widget?>.filled(_tabs.length, null);
    // Creamos el widget de la primera pestaña (Radio) ya que es la inicial.
    _tabWidgets[0] = const SimpleScheduleWidget();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('El Contraste Noticias'),
        actions: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                ' EN VIVO ',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const MenuApp(),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Image.asset('assets/logoradio.png', height: 80),
            const SizedBox(height: 16),
            // Envolvemos el reproductor en AnimatedSize para que el espacio que ocupa
            // se anime suavemente, permitiendo que el contenido de abajo suba.
            AnimatedSize(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              child: _NowplayingWidget(isNewsSelected: _selectedTabIndex == 1),
            ),
            const SizedBox(height: 16), // Espacio entre reproductor y pestañas
            Row(
              children: _tabs.asMap().entries.map((entry) {
                final index = entry.key;
                final text = entry.value;
                return _TabButton(
                  text: text,
                  selected: _selectedTabIndex == index,
                  onTap: () {
                    setState(() {
                      _selectedTabIndex = index;
                    });
                  },
                );
              }).toList(),
            ),
            // Este Column agrupa los widgets de la sección de noticias y se anima
            // para aparecer o desaparecer, optimizando el espacio vertical.
            AnimatedSize(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              child: _selectedTabIndex == 1
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          height: 16,
                        ), // Espacio antes de las categorías
                        _NewsCategories(
                          categories: _newsCategories,
                          selectedCategoryId: _selectedNewsCategoryId,
                          onCategorySelected: (id) {
                            setState(() {
                              _selectedNewsCategoryId = id;
                            });
                          },
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
            Expanded(
              // Este es el widget que nos dará la carga perezosa.
              child: _buildTabContent(),
            ),
          ],
        ),
      ),
    );
  }

  // Método para construir el contenido de la pestaña de forma perezosa.
  Widget _buildTabContent() {
    // Si el widget para la pestaña actual aún no ha sido creado (es null), lo creamos.
    if (_selectedTabIndex == 1) {
      // Para la pestaña de noticias, la reconstruimos siempre para que el filtro de categoría funcione.
      _tabWidgets[1] = _getWidgetForTab(_selectedTabIndex);
    } else {
      // Para las otras pestañas, solo las creamos una vez.
      _tabWidgets[_selectedTabIndex] ??= _getWidgetForTab(_selectedTabIndex);
    }

    // Usamos un AnimatedSwitcher para una transición suave entre pestañas.
    // La clave (key) es importante para que AnimatedSwitcher sepa que el widget ha cambiado.
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey<int>(_selectedTabIndex),
        child: _tabWidgets[_selectedTabIndex],
      ),
    );
  }

  // Devuelve el widget correspondiente a cada pestaña.
  Widget _getWidgetForTab(int index) {
    switch (index) {
      case 1:
        return _NewsWidget(
          key: ValueKey<int?>(_selectedNewsCategoryId),
          categoryId: _selectedNewsCategoryId,
        );
      case 2:
        return const _VideosWidget();
      default: // case 0 y cualquier otro caso
        return const SimpleScheduleWidget();
    }
  }
}

class _NowplayingWidget extends StatelessWidget {
  final bool isNewsSelected;

  // El parámetro se conservará, pero ya no se usará.
  const _NowplayingWidget({this.isNewsSelected = false});

  Widget _buildFullPlayer(BuildContext context) {
    return Card(
      color: const Color.fromARGB(255, 7, 38, 65),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 28.0),
        child: Column(
          children: [
            const Text(
              "El Contraste Radio",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const RadioPlayerWidget(),
          ],
        ),
      ),
    );
  }

  // Dejamos la versión compacta aquí pero comentada
  /*
  Widget _buildCompactPlayer(BuildContext context) {
    return Card(
      color: const Color.fromARGB(255, 7, 38, 65),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Ahora suena:",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    "El Contraste Radio",
                    style: TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            // Envolvemos el RadioPlayerWidget en Flexible para que se ajuste
            // al espacio disponible en la Row, solucionando el error de layout.
            // Le indicamos que es la versión compacta.
            const Flexible(child: RadioPlayerWidget(isCompact: true)),
          ],
        ),
      ),
    );
  }
  */

  @override
  Widget build(BuildContext context) {
    // Always show the full player; do not alternate by isNewsSelected.
    return _buildFullPlayer(context);

    // Código original con AnimatedCrossFade, solo para referencia:
    /*
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 400),
      firstChild: _buildFullPlayer(context),
      secondChild: _buildCompactPlayer(context),
      crossFadeState: isNewsSelected
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      layoutBuilder: (topChild, topChildKey, bottomChild, bottomChildKey) {
        return Stack(
          alignment: Alignment.center,
          children: <Widget>[bottomChild, topChild],
        );
      },
    );
    */
  }
}

class _TabButton extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36,
          alignment: Alignment.center,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: selected
                ? Color.fromARGB(255, 42, 76, 156)
                : Color(0xFF2A86C7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

// Widget para mostrar los botones de filtro de categorías de noticias
class _NewsCategories extends StatelessWidget {
  final Map<String, int?> categories;
  final int? selectedCategoryId;
  final ValueChanged<int?> onCategorySelected;

  const _NewsCategories({
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 35,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: categories.entries.map((entry) {
          final name = entry.key;
          final id = entry.value;
          return _CategoryButton(
            text: name,
            selected: selectedCategoryId == id,
            onTap: () => onCategorySelected(id),
          );
        }).toList(),
      ),
    );
  }
}

// Botón individual para una categoría de noticia
class _CategoryButton extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryButton({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? Colors.white : Colors.grey[400]!,
            width: 1.5,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? const Color(0xFF1A2B40) : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _NewsWidget extends StatefulWidget {
  final int? categoryId;
  const _NewsWidget({super.key, this.categoryId});

  @override
  State<_NewsWidget> createState() => _NewsWidgetState();
}

class _NewsWidgetState extends State<_NewsWidget> {
  late Future<List<Post>> _postsFuture;

  @override
  void initState() {
    super.initState();
    // Obtenemos los posts para la categoría que nos pasan.
    // Como usamos una ValueKey en el widget, initState se vuelve a llamar
    // cada vez que la categoría cambia, recargando las noticias.
    _postsFuture = NewsService().fetchPosts(categoryId: widget.categoryId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Post>>(
      future: _postsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error al cargar noticias: ${snapshot.error}',
              textAlign: TextAlign.center,
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'No se encontraron noticias en esta categoría.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
          );
        }

        final posts = snapshot.data!;
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            // Envolvemos la tarjeta en un SizedBox para darle un ancho específico
            // en la lista horizontal. Esto hace que se vea parte de la siguiente tarjeta.
            return SizedBox(
              width: MediaQuery.of(context).size.width * 0.85,
              height: 450,
              child: _NewsCard(post: post),
            );
          },
        );
      },
    );
  }
}

class _NewsCard extends StatelessWidget {
  final Post post;
  const _NewsCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NewsDetailPage(post: post)),
        );
      },
      child: Card(
        color: const Color.fromARGB(255, 13, 42, 78),
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        elevation: 5,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 450, maxHeight: 600),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Imagen completa
                if (post.featuredImageUrl != null)
                  Hero(
                    tag: 'news_image_${post.id}',
                    child: CachedNetworkImage(
                      imageUrl: post.featuredImageUrl!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 200,
                        color: const Color.fromARGB(255, 32, 24, 104),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.image_not_supported, size: 50),
                    ),
                  ),

                // Contenido completo de la noticia
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título
                      Text(
                        post.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 12),

                      // ✅ FECHA - AHORA FUNCIONA
                      if (post.date != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatDate(post.date!),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),

                      if (post.date != null) const SizedBox(height: 12),

                      // Extracto o contenido resumido
                      if (post.excerpt.isNotEmpty)
                        Text(
                          _cleanHtml(post.excerpt),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.4,
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        )
                      else if (post.content.isNotEmpty)
                        Text(
                          _cleanHtml(post.content),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.4,
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),

                      const SizedBox(height: 16),

                      // Botón "Leer más" siempre visible
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.blue[800]!.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue[300]!),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Leer noticia completa",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ MÉTODO PARA FORMATEAR LA FECHA
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    // Si es hoy
    if (difference.inDays == 0) {
      return 'Hoy';
    }
    // Si es ayer
    else if (difference.inDays == 1) {
      return 'Ayer';
    }
    // Si es esta semana
    else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    }
    // Formato normal
    else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _cleanHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'&[^;]+;'), '')
        .trim();
  }
}

class _VideosWidget extends StatefulWidget {
  const _VideosWidget();

  @override
  State<_VideosWidget> createState() => _VideosWidgetState();
}

class _VideosWidgetState extends State<_VideosWidget> {
  late Future<List<Video>> _videosFuture;

  @override
  void initState() {
    super.initState();
    // Cargamos los videos del canal de YouTube
    _videosFuture = YoutubeService().fetchChannelVideos();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Video>>(
      future: _videosFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Error al cargar los videos: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No se encontraron videos.'));
        }

        final videos = snapshot.data!;
        return ListView.builder(
          itemCount: videos.length,
          itemBuilder: (context, index) {
            final video = videos[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoPlayerPage(videoId: video.id),
                  ),
                );
              },
              child: Card(
                color: const Color(0xFF1A2B40),
                margin: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 4.0,
                ),
                elevation: 5,
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (video.thumbnailUrl.isNotEmpty)
                      CachedNetworkImage(
                        imageUrl: video.thumbnailUrl,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 200,
                          color: Colors.grey[800],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.video_library_outlined, size: 50),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            video.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class SimpleScheduleWidget extends StatelessWidget {
  const SimpleScheduleWidget({Key? key}) : super(key: key);

  final List<_ScheduleItem> schedule = const [
    _ScheduleItem(
      time: '6:00 a.m. – 9:00 a.m.',
      program: 'El Contraste Noticias',
      description:
          'Noticiero de lunes a viernes con los hechos más importantes de Pasto, Nariño y Colombia transmitido en VIVO',
    ),
    _ScheduleItem(
      time: '9:00 a.m. – 12:00 p.m.',
      program: 'Rock del Día',
      description: 'Rock en español clásico y moderno.',
    ),
    _ScheduleItem(
      time: '12:00 p.m. – 2:00 p.m.',
      program: 'Salsa y Sabor',
      description: 'Salsa clásica y moderna.',
    ),
    _ScheduleItem(
      time: '2:00 p.m. – 5:00 p.m.',
      program: 'Rock Alternativo y Latino',
      description: 'Mezcla de géneros.',
    ),
    _ScheduleItem(
      time: '5:00 p.m. – 9:00 p.m.',
      program: 'Hecho en Colombia',
      description: 'Artistas nacionales y locales.',
    ),
    _ScheduleItem(
      time: '9:00 p.m. – 5:00 a.m.',
      program: 'Cristiana Alabanza y adoración',
      description: '',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color.fromARGB(255, 13, 42, 78),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6, // 🔹 Altura visible
          child: ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              const Text(
                'Programación',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...schedule.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _ScheduleTile(item: item),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScheduleItem {
  final String time;
  final String program;
  final String description;

  const _ScheduleItem({
    required this.time,
    required this.program,
    this.description = '',
  });
}

class _ScheduleTile extends StatelessWidget {
  final _ScheduleItem item;

  const _ScheduleTile({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textColor = Colors.white;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.time,
          style: TextStyle(
            color: Colors.blue[300],
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          item.program,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (item.description.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            item.description,
            style: TextStyle(color: textColor.withOpacity(0.75), fontSize: 14),
          ),
        ],
      ],
    );
  }
}
