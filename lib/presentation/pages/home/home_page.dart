import 'package:elcontrasteapp/core/constants/news_categories.dart';
import 'package:elcontrasteapp/core/di/service_locator.dart';
import 'package:elcontrasteapp/core/themes/app_theme.dart';
import 'package:elcontrasteapp/data/models/post_model.dart';
import 'package:elcontrasteapp/data/services/app_update_service.dart';
import 'package:elcontrasteapp/data/services/news_service.dart';
import 'package:elcontrasteapp/presentation/pages/home/news_detail_page.dart';
import 'package:elcontrasteapp/data/models/video_model.dart';
import 'package:elcontrasteapp/presentation/pages/home/video_player_page.dart';
import 'package:elcontrasteapp/data/repositories/videos_repository.dart';
import 'package:elcontrasteapp/presentation/pages/reels/reels_page.dart';
import 'package:elcontrasteapp/presentation/widgets/menu_app.dart';
import 'package:elcontrasteapp/presentation/widgets/radio_player_widget.dart';
import 'package:elcontrasteapp/presentation/widgets/shimmer_box.dart';
import 'package:elcontrasteapp/presentation/widgets/app_network_image.dart';
import 'package:elcontrasteapp/presentation/widgets/async_state_view.dart';
import 'package:elcontrasteapp/presentation/widgets/favorite_button.dart';
import 'package:elcontrasteapp/presentation/pages/search/news_search_page.dart';
import 'package:shimmer/shimmer.dart';
import 'package:elcontrasteapp/presentation/audio/radio_player_handler.dart';
import 'package:elcontrasteapp/data/repositories/emissions_repository.dart';
import 'package:elcontrasteapp/data/models/radio_emission_model.dart';
import 'package:elcontrasteapp/core/utils/html_utils.dart';
import 'package:elcontrasteapp/core/utils/date_formatter.dart';
import 'package:elcontrasteapp/data/local/news_cache_store.dart';
import 'package:elcontrasteapp/presentation/blocs/news/news_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = ["Radio", "Noticias", "Videos"];
  int? _selectedNewsCategoryId;
  Video? _liveVideo;

  late final List<Widget?> _tabWidgets;

  @override
  void initState() {
    super.initState();
    _tabWidgets = List<Widget?>.filled(_tabs.length, null);
    _tabWidgets[0] = const SimpleScheduleWidget();
    AppUpdateService.checkForUpdate();
    _checkLiveStatus();
  }

  Future<void> _checkLiveStatus() async {
    final video = await getIt<VideosRepository>().fetchLiveVideo();
    if (mounted) {
      setState(() => _liveVideo = video);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('El Contraste Noticias'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Buscar noticias',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NewsSearchPage()),
              );
            },
          ),
          if (_liveVideo != null)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoPlayerPage(
                      videoId: _liveVideo!.id,
                      title: 'En Vivo',
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: Colors.white, size: 8),
                    SizedBox(width: 6),
                    Text(
                      'EN VIVO',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
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
              child: _NowplayingWidget(compact: _selectedTabIndex == 1),
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
                          categories: newsCategories,
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
        return const ReelsPage(showAppBar: false);
      default:
        return const SimpleScheduleWidget();
    }
  }
}

class _NowplayingWidget extends StatelessWidget {
  final bool compact;
  const _NowplayingWidget({this.compact = false});

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

  Widget _buildCompactPlayer(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
        child: Row(
          children: [
            Icon(
              Icons.radio,
              color: theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "El Contraste Radio en vivo",
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const RadioPlayerWidget(isCompact: true),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return compact ? _buildCompactPlayer(context) : _buildFullPlayer(context);
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

class _NewsWidget extends StatelessWidget {
  final int? categoryId;
  const _NewsWidget({super.key, this.categoryId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NewsCubit>(
      lazy: false,
      create: (_) => NewsCubit(
        newsService: getIt<NewsService>(),
        cacheStore: getIt<NewsCacheStore>(),
        categoryId: categoryId,
      )..fetchInitial(),
      child: const _NewsListView(),
    );
  }
}

class _NewsListView extends StatefulWidget {
  const _NewsListView();

  @override
  State<_NewsListView> createState() => _NewsListViewState();
}

class _NewsListViewState extends State<_NewsListView> {
  final PageController _pageController = PageController();

  void _handlePageChanged(int index, NewsState state) {
    if (state.hasMore &&
        !state.loadingMore &&
        index >= state.posts.length - 2) {
      context.read<NewsCubit>().loadMore();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<NewsCubit, NewsState>(
      builder: (context, state) {
        if (state.status == NewsStatus.loading ||
            state.status == NewsStatus.initial) {
          return const _NewsCardSkeleton();
        }

        if (state.status == NewsStatus.error) {
          return Center(
            child: Text(
              'Error al cargar noticias: ${state.errorMessage}',
              textAlign: TextAlign.center,
            ),
          );
        }

        if (state.posts.isEmpty) {
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

        return PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          itemCount: state.posts.length,
          onPageChanged: (index) => _handlePageChanged(index, state),
          itemBuilder: (context, index) => _NewsCard(post: state.posts[index]),
        );
      },
    );
  }
}

class _NewsCardSkeleton extends StatelessWidget {
  const _NewsCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    return Shimmer.fromColors(
      baseColor: themeColors.cardColor,
      highlightColor: Color.lerp(themeColors.cardColor, Colors.white, 0.25)!,
      child: Card(
        color: themeColors.cardColor,
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        elevation: 5,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              flex: 4,
              child: ShimmerBox(
                width: double.infinity,
                height: double.infinity,
                borderRadius: BorderRadius.zero,
              ),
            ),
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ShimmerBox(width: 220, height: 20),
                    const SizedBox(height: 8),
                    const ShimmerBox(width: 140, height: 20),
                    const SizedBox(height: 12),
                    const ShimmerBox(width: 100, height: 14),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          ShimmerBox(width: double.infinity, height: 12),
                          SizedBox(height: 8),
                          ShimmerBox(width: double.infinity, height: 12),
                          SizedBox(height: 8),
                          ShimmerBox(width: 180, height: 12),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ShimmerBox(
                      width: double.infinity,
                      height: 44,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
    final hasImage = post.featuredImageUrl != null;
    final description = post.excerpt.isNotEmpty
        ? post.excerpt
        : (post.content.isNotEmpty ? post.content : null);

    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NewsDetailPage(post: post),
              ),
            );
          },
          child: Card(
            color: themeColors.cardColor,
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            elevation: 5,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            // Todo el contenido se reparte con Expanded según proporciones, no
            // alturas fijas: así la tarjeta siempre ocupa exactamente el alto
            // que le da el PageView, sin desbordarse ni recortar el botón de
            // abajo, sin importar el tamaño de pantalla.
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasImage)
                  Expanded(
                    flex: 4,
                    child: Hero(
                      tag: 'news_image_${post.id}',
                      child: AppNetworkImage(
                        imageUrl: post.featuredImageUrl!,
                        width: double.infinity,
                        height: double.infinity,
                        placeholderBackground: themeColors.placeholderColor,
                      ),
                    ),
                  ),
                Expanded(
                  flex: hasImage ? 6 : 10,
                  child: Padding(
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              formatRelativeDate(post.date),
                              style: TextStyle(
                                color: onSurfaceVariant,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (description != null)
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                // Calcula cuántas líneas caben en el espacio
                                // sobrante real, en vez de un maxLines fijo que
                                // se rompe en pantallas chicas o grandes.
                                const lineHeight = 14 * 1.4;
                                final maxLines =
                                    (constraints.maxHeight / lineHeight)
                                        .floor()
                                        .clamp(1, 20);
                                return Text(
                                  stripHtml(description),
                                  style: TextStyle(
                                    color: onSurfaceVariant,
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                  maxLines: maxLines,
                                  overflow: TextOverflow.ellipsis,
                                );
                              },
                            ),
                          )
                        else
                          const Spacer(),
                        const SizedBox(height: 8),
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
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: FavoriteButton(post: post, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _VideoCardSkeleton extends StatelessWidget {
  const _VideoCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    return Shimmer.fromColors(
      baseColor: themeColors.cardColor,
      highlightColor: Color.lerp(themeColors.cardColor, Colors.white, 0.25)!,
      child: Card(
        color: themeColors.cardColor,
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        elevation: 5,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerBox(
              width: double.infinity,
              height: 200,
              borderRadius: BorderRadius.zero,
            ),
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: ShimmerBox(width: double.infinity, height: 18),
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
    _videosFuture = getIt<VideosRepository>().fetchChannelVideos();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeColors = context.themeColors;
    return FutureBuilder<List<Video>>(
      future: _videosFuture,
      builder: (context, snapshot) {
        return AsyncStateView<List<Video>>(
          snapshot: snapshot,
          loadingBuilder: (context) => ListView.builder(
            itemCount: 4,
            itemBuilder: (context, index) => const _VideoCardSkeleton(),
          ),
          errorMessage: (error) => 'Error al cargar los videos: $error',
          isEmpty: (videos) => videos.isEmpty,
          emptyMessage: 'No se encontraron videos.',
          builder: (context, videos) {
            return ListView.builder(
              itemCount: videos.length,
              itemBuilder: (context, index) {
                final video = videos[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            VideoPlayerPage(videoId: video.id),
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
                          AppNetworkImage(
                            imageUrl: video.thumbnailUrl,
                            height: 200,
                            width: double.infinity,
                            placeholderBackground: themeColors.placeholderColor,
                            errorIcon: Icons.video_library_outlined,
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
    _emissionsFuture = EmissionsRepository.getEmissions();
  }

  Future<void> _refreshEmissions() async {
    setState(() {
      _emissionsFuture = EmissionsRepository.getEmissions();
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
                          return AsyncStateView<List<RadioEmission>>(
                            snapshot: snapshot,
                            loadingBuilder: (context) => Column(
                              children: List.generate(
                                3,
                                (index) => const Padding(
                                  padding: EdgeInsets.only(bottom: 16),
                                  child: _ScheduleTileSkeleton(),
                                ),
                              ),
                            ),
                            errorMessage: (error) =>
                                'No se pudieron cargar las emisiones.',
                            isEmpty: (emissions) => emissions.isEmpty,
                            emptyMessage: 'No hay emisiones disponibles.',
                            builder: (context, emissions) {
                              return Column(
                                children: emissions
                                    .map(
                                      (emission) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 16,
                                        ),
                                        child: _ScheduleTile(
                                          emission: emission,
                                        ),
                                      ),
                                    )
                                    .toList(),
                              );
                            },
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

class _ScheduleTileSkeleton extends StatelessWidget {
  const _ScheduleTileSkeleton();

  @override
  Widget build(BuildContext context) {
    final themeColors = context.themeColors;
    return Shimmer.fromColors(
      baseColor: themeColors.cardColor,
      highlightColor: Color.lerp(themeColors.cardColor, Colors.white, 0.25)!,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBox(width: 220, height: 18),
                SizedBox(height: 8),
                ShimmerBox(width: 120, height: 16),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const ShimmerBox(
            width: 32,
            height: 32,
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ],
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
