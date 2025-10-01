import 'package:cached_network_image/cached_network_image.dart';
import 'package:elcontrasteapp/presentation/pages/home/post_model.dart';
import 'package:elcontrasteapp/presentation/pages/home/news_service.dart';
import 'package:elcontrasteapp/presentation/pages/home/news_detail_page.dart';
import 'package:elcontrasteapp/presentation/pages/home/video_model.dart';
import 'package:elcontrasteapp/presentation/pages/home/video_player_page.dart';
import 'package:elcontrasteapp/presentation/pages/home/youtube_service.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
              child: IndexedStack(
                index: _selectedTabIndex,
                children: [
                  const _ProgrammingWidget(),
                  // Usamos una ValueKey para que el widget de noticias se reconstruya
                  // y recargue los posts cuando cambia la categoría seleccionada.
                  _NewsWidget(
                    key: ValueKey(_selectedNewsCategoryId),
                    categoryId: _selectedNewsCategoryId,
                  ),
                  const _VideosWidget(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NowplayingWidget extends StatelessWidget {
  final bool isNewsSelected;

  const _NowplayingWidget({this.isNewsSelected = false});

  Widget _buildFullPlayer(BuildContext context) {
    return Card(
      color: const Color.fromARGB(255, 7, 38, 65),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 4,
      child: const Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          children: [
            SizedBox(height: 16),
            Text(
              'El Contraste Radio',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            RadioPlayerWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactPlayer(BuildContext context) {
    return Card(
      color: const Color.fromARGB(255, 7, 38, 65),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        child: RadioPlayerWidget(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 400),
      firstChild: _buildFullPlayer(context),
      secondChild: _buildCompactPlayer(context),
      crossFadeState: isNewsSelected
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      // Este layoutBuilder ayuda a que la animación de tamaño sea más fluida
      // al evitar problemas de overflow mientras los widgets cambian de tamaño.
      layoutBuilder: (topChild, topChildKey, bottomChild, bottomChildKey) {
        return Stack(
          alignment: Alignment.center,
          children: <Widget>[bottomChild, topChild],
        );
      },
    );
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
        color: const Color(
          0xFF1A2B40,
        ), // <-- AÑADE ESTA LÍNEA PARA CAMBIAR EL COLOR
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        elevation: 5,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.featuredImageUrl != null)
              Hero(
                tag: 'news_image_${post.id}',
                child: CachedNetworkImage(
                  imageUrl: post.featuredImageUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 180,
                    color: Colors.grey[800],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.image_not_supported, size: 50),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              /*child: Text(
                post.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),*/
            ),
          ],
        ),
      ),
    );
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
                      child: Text(
                        video.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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

class _ProgrammingWidget extends StatelessWidget {
  const _ProgrammingWidget();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Programación',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            color: const Color.fromARGB(255, 42, 76, 156),
            child: ListTile(
              leading: const Icon(Icons.person, color: Colors.greenAccent),
              title: const Text(
                'DJ Carlos',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text('Éxitos de los 80s y 90s'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'EN VIVO',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Próximo: 18:00',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Text('Música Tropical con DJ María'),
        ],
      ),
    );
  }
}
