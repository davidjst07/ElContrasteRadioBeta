import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:elcontrasteapp/data/models/reel_model.dart';
import 'package:elcontrasteapp/presentation/blocs/reels/reels_cubit.dart';
import 'package:elcontrasteapp/presentation/widgets/reel_player.dart';

class ReelsPage extends StatelessWidget {
  /// Si showAppBar es true, muestra AppBar con logo y botón atrás
  /// (útil cuando se abre desde home_page como pestaña)
  final bool showAppBar;

  const ReelsPage({
    super.key,
    this.showAppBar = true,
  });

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
        body: const _ReelsContent(),
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

    // Verificamos si estamos cerca del final (últimos 2 reels)
    final cubit = context.read<ReelsCubit>();
    final reelsCount = cubit.state.reels.length;

    if (reelsCount > 0 && page >= reelsCount - 2) {
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
          return const Center(
            child: CircularProgressIndicator(),
          );
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
          return const Center(
            child: Text('No hay reels disponibles'),
          );
        }

        return _ReelsListView(
          reels: state.reels,
          pageController: _pageController,
          currentPageIndex: _currentPageIndex,
          loadingMore: state.loadingMore,
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

  const _ReelsListView({
    required this.reels,
    required this.pageController,
    required this.currentPageIndex,
    required this.loadingMore,
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
    return PageView.builder(
      scrollDirection: Axis.vertical, // Swipe vertical
      controller: widget.pageController,
      onPageChanged: (index) {
        // El listener del controller ya maneja esto en _ReelsContentState
      },
      itemCount: widget.reels.length +
          (widget.loadingMore ? 1 : 0), // +1 si está pidiendo más
      itemBuilder: (context, index) {
        // Si es el último item y está pidiendo más, mostrar skeleton
        if (index >= widget.reels.length) {
          return _ReelCardSkeleton();
        }

        final reel = widget.reels[index];
        // isActive: true solo si este reel es el actualmente visible
        final isActive = index == widget.currentPageIndex;
        return _ReelCard(
          reel: reel,
          isActive: isActive,
          onVideoEnded: () {
            // Cuando termina el video, avanza al siguiente reel
            if (index < widget.reels.length - 1) {
              widget.pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          },
        );
      },
    );
  }
}

/// Card individual con reproductor + título
class _ReelCard extends StatelessWidget {
  final Reel reel;
  final bool isActive;
  final VoidCallback? onVideoEnded;

  const _ReelCard({
    required this.reel,
    required this.isActive,
    this.onVideoEnded,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Reproductor (o thumbnail si no está activo)
        ReelPlayerWidget(
          reel: reel,
          isActive: isActive,
          onVideoEnded: onVideoEnded,
        ),

        // Overlay oscuro en la parte inferior para el título
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: GestureDetector(
            onTap: () => _showTitleModal(context),
            child: Container(
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
              padding: const EdgeInsets.all(16),
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
                  const SizedBox(height: 8),
                  // Duración del video
                  Text(
                    '${reel.duracionSeg ~/ 60}:${(reel.duracionSeg % 60).toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Muestra un modal con el título completo del reel
  void _showTitleModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Información del video',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              reel.titulo,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.access_time, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Duración: ${reel.duracionSeg ~/ 60}:${(reel.duracionSeg % 60).toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Publicado: ${reel.creadoEn.day}/${reel.creadoEn.month}/${reel.creadoEn.year}',
                  style: Theme.of(context).textTheme.bodySmall,
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
                      Colors.grey[400]!.withOpacity(0.8),
                      Colors.grey[400]!.withOpacity(0.4),
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
                    Container(
                      height: 20,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 16,
                      width: 100,
                      color: Colors.grey[400],
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
