import 'package:cached_network_image/cached_network_image.dart';
import 'package:elcontrasteapp/data/models/post_model.dart';
import 'package:elcontrasteapp/data/services/news_service.dart';
import 'package:elcontrasteapp/presentation/pages/home/news_detail_page.dart';
import 'package:elcontrasteapp/presentation/widgets/radio_player_widget.dart';

import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = ["Radio", "Noticias", "Deportes"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.radio),
        //title: const Text('El Contraste App'),
        actions: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //Text('21:55', style: TextStyle(fontWeight: FontWeight.bold)),
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
            Image.asset('assets/logoradio.png', height: 90),
            const _NowplayingWidget(),
            const SizedBox(height: 24),
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
            const SizedBox(height: 10),
            Expanded(
              child: IndexedStack(
                index: _selectedTabIndex,
                children: const [
                  _ProgrammingWidget(),
                  _NewsWidget(),
                  _SportsWidget(),
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
  const _NowplayingWidget();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Color.fromARGB(255, 7, 38, 65),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            //const Icon(Icons.radio, size: 60, color: Colors.white70),
            const SizedBox(height: 16),
            const Text(
              'El Contraste Radio',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            const RadioPlayerWidget(),
          ],
        ),
      ),
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

class _NewsWidget extends StatefulWidget {
  const _NewsWidget();

  @override
  State<_NewsWidget> createState() => _NewsWidgetState();
}

class _NewsWidgetState extends State<_NewsWidget> {
  late Future<List<Post>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _postsFuture = NewsService().fetchPosts();
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
          return const Center(child: Text('No hay noticias disponibles.'));
        }

        final posts = snapshot.data!;
        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return _NewsCard(post: post);
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
              child: Text(
                post.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SportsWidget extends StatelessWidget {
  const _SportsWidget();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Text(
          'Sección de Deportes próximamente...',
          style: TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
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
