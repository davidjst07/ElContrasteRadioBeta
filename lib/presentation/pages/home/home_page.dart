import 'package:cached_network_image/cached_network_image.dart';
import 'package:elcontrasteapp/core/themes/app_theme.dart';
import 'package:elcontrasteapp/data/models/post_model.dart';
import 'package:elcontrasteapp/data/services/news_service.dart';
import 'package:elcontrasteapp/presentation/pages/home/news_detail_page.dart';
import 'package:elcontrasteapp/presentation/pages/home/video_model.dart';
import 'package:elcontrasteapp/presentation/pages/home/video_player_page.dart';
import 'package:elcontrasteapp/presentation/pages/home/youtube_service.dart';
import 'package:elcontrasteapp/presentation/widgets/menu_app.dart';
import 'package:elcontrasteapp/presentation/widgets/radio_player_widget.dart';
import 'package:elcontrasteapp/audio_state_service.dart';
import 'package:elcontrasteapp/emissions_service.dart';
import 'package:provider/provider.dart';

import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = ["Radio", "Noticias", "Videos"];

  final Map<String, int?> _newsCategories = {
    'Últimas': null,
    'Pasto': 2,
    'Nariño': 1,
    'Colombia': 7,
  };
  int? _selectedNewsCategoryId;

  late final List<Widget?> _tabWidgets;

  @override
  void initState() {
    super.initState();
    _tabWidgets = List<Widget?>.filled(_tabs.length, null);
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
              const Text(
                ' EN VIVO ',
                style: TextStyle(
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
            AnimatedSize(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              child: const _NowplayingWidget(),
            ),
            const SizedBox(height: 16),
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
            AnimatedSize(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              child: _selectedTabIndex == 1
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 16),
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
            Expanded(child: _buildTabContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    if (_selectedTabIndex == 1) {
      _tabWidgets[1] = _getWidgetForTab(_selectedTabIndex);
    } else {
      _tabWidgets[_selectedTabIndex] ??= _getWidgetForTab(_selectedTabIndex);
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey<int>(_selectedTabIndex),
        child: _tabWidgets[_selectedTabIndex],
      ),
    );
  }

  Widget _getWidgetForTab(int index) {
    switch (index) {
      case 1:
        return _NewsWidget(
          key: ValueKey<int?>(_selectedNewsCategoryId),
          categoryId: _selectedNewsCategoryId,
        );
      case 2:
        return const _VideosWidget();
      default:
        return const SimpleScheduleWidget();
    }
  }
}

class _NowplayingWidget extends StatelessWidget {
  const _NowplayingWidget();

  Widget _buildFullPlayer(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 28.0),
        child: Column(
          children: [
            Text(
              "El Contraste Radio",
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const RadioPlayerWidget(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildFullPlayer(context);
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
    final themeColors = context.themeColors;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36,
          alignment: Alignment.center,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? themeColors.tabBarSelected : AppColors.blueBrand,
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
    final theme = Theme.of(context);
    final surfaceColor = theme.colorScheme.surface;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? surfaceColor : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? surfaceColor : Colors.grey[400]!,
            width: 1.5,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? theme.textTheme.bodyLarge?.color : Colors.white,
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
    _postsFuture = NewsService().fetchPosts(categoryId: widget.categoryId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                'No se encontraron noticias en esta categoría.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16),
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
    final theme = Theme.of(context);
    final themeColors = context.themeColors;
    final onSurfaceVariant = theme.textTheme.bodySmall?.color ?? Colors.white70;
    final onSurface = theme.textTheme.bodyLarge?.color ?? Colors.white;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NewsDetailPage(post: post)),
        );
      },
      child: Card(
        color: themeColors.cardColor,
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
                        color: themeColors.placeholderColor,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.image_not_supported, size: 50),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatDate(post.date),
                            style: TextStyle(
                              color: onSurfaceVariant,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (post.excerpt.isNotEmpty)
                        Text(
                          _cleanHtml(post.excerpt),
                          style: TextStyle(
                            color: onSurfaceVariant,
                            fontSize: 14,
                            height: 1.4,
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        )
                      else if (post.content.isNotEmpty)
                        Text(
                          _cleanHtml(post.content),
                          style: TextStyle(
                            color: onSurfaceVariant,
                            fontSize: 14,
                            height: 1.4,
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.blueBrand.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.blueBrand.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Leer noticia completa",
                              style: TextStyle(
                                color: onSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward,
                              color: onSurface,
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hoy';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
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
    _videosFuture = YoutubeService().fetchChannelVideos();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeColors = context.themeColors;
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
          return Center(
            child: Text(
              'No se encontraron videos.',
              style: theme.textTheme.bodyMedium,
            ),
          );
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
                color: themeColors.cardColor,
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
                          color: themeColors.placeholderColor,
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
                            style: theme.textTheme.titleMedium?.copyWith(
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

class SimpleScheduleWidget extends StatefulWidget {
  const SimpleScheduleWidget({super.key});

  @override
  State<SimpleScheduleWidget> createState() => _SimpleScheduleWidgetState();
}

class _SimpleScheduleWidgetState extends State<SimpleScheduleWidget> {
  late Future<List<RadioEmission>> _emissionsFuture;

  @override
  void initState() {
    super.initState();
    _emissionsFuture = EmissionsService.getEmissions();
  }

  Future<void> _refreshEmissions() async {
    setState(() {
      _emissionsFuture = EmissionsService.getEmissions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeColors = context.themeColors;

    return Card(
      color: themeColors.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Emisiones guardadas',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    context.read<RadioPlayerHandler>().playLiveRadio();
                  },
                  icon: const Icon(Icons.radio),
                  label: const Text('Volver al vivo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.blueText,
                    side: BorderSide(color: AppColors.blueText, width: 1.4),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshEmissions,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      FutureBuilder<List<RadioEmission>>(
                        future: _emissionsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          if (snapshot.hasError) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Text(
                                'No se pudieron cargar las emisiones.',
                                style: theme.textTheme.bodyMedium,
                              ),
                            );
                          }

                          final emissions = snapshot.data ?? [];

                          if (emissions.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Text(
                                'No hay emisiones disponibles.',
                                style: theme.textTheme.bodyMedium,
                              ),
                            );
                          }

                          return Column(
                            children: emissions
                                .map(
                                  (emission) => Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: _ScheduleTile(emission: emission),
                                  ),
                                )
                                .toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  final RadioEmission emission;

  const _ScheduleTile({required this.emission});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.titleLarge?.color ?? Colors.white;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      trailing: Icon(
        Icons.play_circle_fill_rounded,
        color: AppColors.blueText,
        size: 32,
      ),
      title: Text(
        emission.displayTitle,
        style: TextStyle(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            emission.displayTime,
            style: TextStyle(
              color: AppColors.blueText,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          if (emission.displayDuration.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'Duracion: ${emission.displayDuration}',
              style: TextStyle(
                color: textColor.withValues(alpha: 0.75),
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
      onTap: () {
        context.read<RadioPlayerHandler>().playEmission(
          audioUrl: emission.audioUrl,
          title: emission.displayTitle,
          artist: emission.displayTime,
        );
      },
    );
  }
}
