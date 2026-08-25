import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:elcontrasteapp/core/di/service_locator.dart';
import 'package:elcontrasteapp/data/local/liked_reels_store.dart';
import 'package:elcontrasteapp/data/models/reel_model.dart';
import 'package:elcontrasteapp/presentation/blocs/reels/reels_cubit.dart';
import 'package:elcontrasteapp/presentation/widgets/reel_player.dart';

class ReelsPage extends StatelessWidget {
  /// Si showAppBar es true, muestra AppBar con logo y botón atrás
  /// (útil cuando se abre desde home_page como pestaña)
  final bool showAppBar;

  const ReelsPage({super.key, this.showAppBar = true});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ReelsCubit()..fetchInitial(),
      child: Scaffold(
        appBar: showAppBar
            ? AppBar(
                title: const Text('Reels'),
                elevation: 0,
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                leading: Navigator.canPop(context)
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      )
                    : null,
              )
            : null,
        body: GestureDetector(
          // Swipe de derecha a izquierda (desde izquierda) para atrás
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity! > 0) {
              // Swipe hacia la derecha = atrás
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            }
          },
          child: const _ReelsContent(),
        ),
        backgroundColor: Colors.black,
      ),
    );
  }
}

class _ReelsContent extends StatefulWidget {
  const _ReelsContent();

  @override
  State<_ReelsContent> createState() => _ReelsContentState();
}

class _ReelsContentState extends State<_ReelsContent> {
  late PageController _pageController;
  int _currentPageIndex = 0;
  int _lastLoadMoreIndex = -1; // Guard para evitar cargar dos veces
  bool _isAutoScrolling = false; // Flag: si es scroll programático

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(_onPageChanged);
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    super.dispose();
  }

  /// Se dispara cuando el usuario swipea a otra página
  /// Si se acerca al final de la lista, pide más reels
  void _onPageChanged() {
    final page = _pageController.page?.toInt() ?? 0;
    setState(() => _currentPageIndex = page);

    // Solo pide más si NO está en un scroll automático
    // (evita conflictos cuando termina un video y hace nextPage)
    if (_isAutoScrolling) return;

    // Verificamos si estamos en el ÚLTIMO reel (no cerca, sino en el último)
    final cubit = context.read<ReelsCubit>();
    final reelsCount = cubit.state.reels.length;

    // Guard: solo pide más si es el último reel y no lo hemos pedido antes
    if (reelsCount > 0 &&
        page >= reelsCount - 1 &&
        page != _lastLoadMoreIndex) {
      _lastLoadMoreIndex = page;
      // Pide la próxima página (si existe cursor)
      cubit.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReelsCubit, ReelsState>(
      builder: (context, state) {
        // Estado inicial: sin datos todavía
        if (state.status == ReelsStatus.initial) {
          return const Center(child: CircularProgressIndicator());
        }

        // Error: mostrar mensaje + botón reintentar
        if (state.status == ReelsStatus.error) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  state.errorMessage ?? 'Error desconocido',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    context.read<ReelsCubit>().retry();
                  },
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        // Loading: mostrar esqueleto mientras carga la primera página
        if (state.status == ReelsStatus.loading && state.reels.isEmpty) {
          return _ReelCardSkeleton();
        }

        // Success: mostrar la lista con PageView
        if (state.reels.isEmpty) {
          return const Center(child: Text('No hay reels disponibles'));
        }

        return _ReelsListView(
          reels: state.reels,
          pageController: _pageController,
          currentPageIndex: _currentPageIndex,
          loadingMore: state.loadingMore,
          hasMore: state.hasMore,
          onAutoScroll: (isAutoScrolling) {
            setState(() => _isAutoScrolling = isAutoScrolling);
          },
        );
      },
    );
  }
}

/// ListView con PageView vertical (estilo TikTok/Reels)
class _ReelsListView extends StatefulWidget {
  final List<Reel> reels;
  final PageController pageController;
  final int currentPageIndex;
  final bool loadingMore;
  final bool hasMore; // False cuando el backend ya no tiene más reels
  final Function(bool) onAutoScroll; // Callback para comunicar auto-scroll

  const _ReelsListView({
    required this.reels,
    required this.pageController,
    required this.currentPageIndex,
    required this.loadingMore,
    required this.hasMore,
    required this.onAutoScroll,
  });

  @override
  State<_ReelsListView> createState() => _ReelsListViewState();
}

class _ReelsListViewState extends State<_ReelsListView> {
  @override
  void initState() {
    super.initState();
    // Cuando la lista se actualiza, reconstruye para que el PageView
    // sea consciente de nuevos items
  }

  @override
  Widget build(BuildContext context) {
    // Se agrega una página extra al final: skeleton mientras carga más,
    // o el mensaje de "fin del feed" cuando ya no hay más reels que pedir.
    final showEndCard = !widget.loadingMore && !widget.hasMore;

    return PageView.builder(
      scrollDirection: Axis.vertical, // Swipe vertical
      controller: widget.pageController,
      onPageChanged: (index) {
        // El listener del controller ya maneja esto en _ReelsContentState
      },
      itemCount:
          widget.reels.length + (widget.loadingMore || showEndCard ? 1 : 0),
      itemBuilder: (context, index) {
        // Página extra al final de la lista
        if (index >= widget.reels.length) {
          if (widget.loadingMore) {
            return _ReelCardSkeleton();
          }
          return _EndOfFeedCard(
            onBackToStart: () {
              widget.pageController.animateToPage(
                0,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              );
            },
          );
        }

        final reel = widget.reels[index];
        // isActive: true solo si este reel es el actualmente visible
        final isActive = index == widget.currentPageIndex;
        // shouldPreload: true si es el siguiente reel (precarga)
        final shouldPreload = index == widget.currentPageIndex + 1;
        return _ReelCard(
          reel: reel,
          isActive: isActive,
          shouldPreload: shouldPreload,
          onVideoEnded: () {
            // Cuando termina el video, avanza al siguiente reel
            if (index < widget.reels.length - 1) {
              // Mark que es scroll automático
              widget.onAutoScroll(true);

              widget.pageController
                  .nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  )
                  .then((_) {
                    // Después de terminar el scroll, vuelve a false
                    Future.delayed(const Duration(milliseconds: 350), () {
                      widget.onAutoScroll(false);
                    });
                  });
            }
          },
        );
      },
    );
  }
}

/// Card individual con reproductor + título
class _ReelCard extends StatefulWidget {
  final Reel reel;
  final bool isActive;
  final bool shouldPreload;
  final VoidCallback? onVideoEnded;

  const _ReelCard({
    required this.reel,
    required this.isActive,
    this.shouldPreload = false,
    this.onVideoEnded,
  });

  @override
  State<_ReelCard> createState() => _ReelCardState();
}

class _ReelCardState extends State<_ReelCard>
    with SingleTickerProviderStateMixin {
  // Controla la animación del corazón grande que aparece al doble-tap
  // (estilo Instagram/TikTok): escala + fade, sin loop.
  late final AnimationController _heartBurstController;
  late final Animation<double> _heartBurstScale;
  late final Animation<double> _heartBurstOpacity;

  // Contador de likes mostrado en pantalla. Arranca con el valor que ya
  // trajo el backend y se actualiza de forma OPTIMISTA (+1/-1 al toque),
  // sin esperar la respuesta del servidor — mismo patrón que Instagram.
  late int _likesCount;

  Reel get reel => widget.reel;

  @override
  void initState() {
    super.initState();
    _likesCount = reel.likesCount;
    _heartBurstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _heartBurstScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.6,
          end: 1.2,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.2,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 60,
      ),
    ]).animate(_heartBurstController);
    _heartBurstOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_heartBurstController);
  }

  @override
  void dispose() {
    _heartBurstController.dispose();
    super.dispose();
  }

  /// Doble-tap sobre el video: le da like (si no lo tenía) y siempre
  /// muestra la animación del corazón como confirmación visual.
  void _handleDoubleTapLike() async {
    final store = getIt<LikedReelsStore>();
    final alreadyLiked = await store.isLiked(reel.id);
    if (!alreadyLiked) {
      store.like(reel.id);
      if (mounted) setState(() => _likesCount++);
    }
    _heartBurstController.forward(from: 0);
  }

  /// Formatea el contador para no desbordar el botón con números grandes
  /// (ej. 1200 → "1.2K")
  String _formatLikesCount(int count) {
    if (count < 1000) return count.toString();
    return '${(count / 1000).toStringAsFixed(1)}K';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Reproductor (o thumbnail si no está activo)
        ReelPlayerWidget(
          reel: reel,
          isActive: widget.isActive,
          shouldPreload: widget.shouldPreload,
          onVideoEnded: widget.onVideoEnded,
          onDoubleTap: _handleDoubleTapLike,
        ),

        // Gradiente oscuro inferior — SOLO visual.
        // IgnorePointer deja pasar los toques a los controles de Chewie
        // (barra de progreso y botón de mute) que están debajo en el Stack.
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),

        // Corazón grande que aparece brevemente al doble-tap (no bloquea
        // toques: es puramente visual, por eso va en IgnorePointer)
        IgnorePointer(
          child: Center(
            child: AnimatedBuilder(
              animation: _heartBurstController,
              builder: (context, child) {
                return Opacity(
                  opacity: _heartBurstOpacity.value,
                  child: Transform.scale(
                    scale: _heartBurstScale.value,
                    child: child,
                  ),
                );
              },
              child: const Icon(
                Icons.favorite,
                color: Colors.red,
                size: 110,
                shadows: [Shadow(color: Colors.black45, blurRadius: 12)],
              ),
            ),
          ),
        ),

        // Botón de like, columna de acciones a la derecha (estilo
        // TikTok/Reels), arriba del botón de compartir.
        // Reactivo: se pinta rojo/relleno si el reel ya tiene like
        // guardado localmente (ValueListenableBuilder sobre el box Hive).
        Positioned(
          bottom: 160,
          right: 12,
          child: FutureBuilder<Box<bool>>(
            future: getIt<LikedReelsStore>().box,
            builder: (context, snapshot) {
              final box = snapshot.data;
              if (box == null) {
                return const SizedBox(width: 44, height: 44);
              }
              return ValueListenableBuilder<Box<bool>>(
                valueListenable: box.listenable(),
                builder: (context, box, _) {
                  final isLiked = box.containsKey(reel.id);
                  return GestureDetector(
                    onTap: () {
                      getIt<LikedReelsStore>().toggle(reel.id);
                      setState(() => _likesCount += isLiked ? -1 : 1);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red : Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatLikesCount(_likesCount),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            shadows: [
                              Shadow(color: Colors.black54, blurRadius: 4),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),

        // Botón de compartir, columna de acciones a la derecha
        // (estilo TikTok/Reels), arriba de la barra de controles de Chewie
        Positioned(
          bottom: 90,
          right: 12,
          child: GestureDetector(
            onTap: () => _shareReel(context),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(10),
              child: const Icon(Icons.share, color: Colors.white, size: 24),
            ),
          ),
        ),

        // Título tappable, ubicado ARRIBA de la barra de controles de Chewie
        // para no taparla (los controles ocupan la franja inferior ~70px)
        // right: 72 deja espacio para el botón de compartir
        Positioned(
          bottom: 90,
          left: 16,
          right: 72,
          child: GestureDetector(
            onTap: () => _showTitleModal(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Título truncado a 2 líneas (tap para ver completo)
                Text(
                  reel.titulo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // "Ver más" como guía de que el título es tappable
                const Text(
                  'Ver más',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                // Duración del video
                Text(
                  '${reel.duracionSeg ~/ 60}:${(reel.duracionSeg % 60).toString().padLeft(2, '0')}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Comparte el reel: título + link a su página pública específica
  /// (https://www.elcontraste.co/reels/{id}), con preview de Open Graph
  /// y botón "Abrir en la app" (deep link elcontraste://reel/{id}).
  void _shareReel(BuildContext context) {
    SharePlus.instance.share(
      ShareParams(
        text:
            '${reel.titulo}\n\nMira este video de El Contraste 👉 https://www.elcontraste.co/reels/${reel.id}',
      ),
    );
  }

  /// Muestra un modal con el título completo del reel
  /// isScrollControlled permite que el modal crezca hasta un límite y,
  /// si el contenido (título largo) no cabe, se pueda hacer scroll dentro.
  void _showTitleModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(
        context,
      ).scaffoldBackgroundColor.withValues(alpha: 0.7),
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(
          // No más del 70% de la pantalla, para dejar ver el video detrás
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Información del video',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(179, 255, 255, 255),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                reel.titulo,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color.fromARGB(204, 255, 255, 255),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 18,
                    color: Colors.grey[600]?.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Duración: ${reel.duracionSeg ~/ 60}:${(reel.duracionSeg % 60).toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color.fromARGB(179, 255, 255, 255),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 18,
                    color: Colors.grey[600]?.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Publicado: ${reel.creadoEn.day}/${reel.creadoEn.month}/${reel.creadoEn.year}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color.fromARGB(179, 255, 255, 255),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card que se muestra al llegar al final del feed (no hay más reels
/// que pedir al backend). Invita a volver al inicio del feed.
class _EndOfFeedCard extends StatelessWidget {
  final VoidCallback onBackToStart;

  const _EndOfFeedCard({required this.onBackToStart});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text(
              'Estás al día',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ya viste todos los reels disponibles.\nVuelve más tarde por contenido nuevo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onBackToStart,
              icon: const Icon(Icons.replay, color: Colors.white),
              label: const Text(
                'Volver al inicio',
                style: TextStyle(color: Colors.white),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton loading mientras carga reels
class _ReelCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        color: Colors.grey[300],
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Fondo shimmer
            Container(color: Colors.grey[300]),
            // Overlay con título placeholder
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.grey[400]!.withValues(alpha: 0.8),
                      Colors.grey[400]!.withValues(alpha: 0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(16),
                height: 120,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(height: 20, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Container(height: 16, width: 100, color: Colors.grey[400]),
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
