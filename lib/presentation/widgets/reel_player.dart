import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:elcontrasteapp/data/models/reel_model.dart';
import 'package:elcontrasteapp/presentation/widgets/app_network_image.dart';

class ReelPlayerWidget extends StatefulWidget {
  /// El reel a reproducir
  final Reel reel;

  /// True si este reel es el actualmente visible en pantalla
  /// False si está fuera de vista (arriba o abajo)
  /// El widget usa esto para inicializar/pausar el video
  final bool isActive;

  /// True si este reel es el SIGUIENTE (un índice adelante)
  /// Sirve para precargarlo mientras ves el actual
  /// El video se inicializa pero NO se reproduce
  final bool shouldPreload;

  /// Callback que se ejecuta cuando el video termina
  /// Útil para pasar automáticamente al siguiente reel
  final VoidCallback? onVideoEnded;

  /// Callback al hacer doble-tap sobre el video (estilo like de TikTok/IG)
  final VoidCallback? onDoubleTap;

  const ReelPlayerWidget({
    super.key,
    required this.reel,
    required this.isActive,
    this.shouldPreload = false,
    this.onVideoEnded,
    this.onDoubleTap,
  });

  @override
  State<ReelPlayerWidget> createState() => _ReelPlayerWidgetState();
}

class _ReelPlayerWidgetState extends State<ReelPlayerWidget> {
  // Volumen compartido entre TODOS los reels durante la sesión de la app.
  // Si el usuario sube/baja el volumen o lo mutea en un reel, ese mismo nivel
  // se aplica al siguiente reel en vez de reiniciar siempre a 50%.
  static double _sharedVolume = 0.5;

  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  VoidCallback? _videoListener;
  double _lastTrackedVolume = _sharedVolume; // Para detectar cambios de volumen
  DateTime?
  _lastTapTime; // Para detectar doble-tap manualmente (ver _handlePointerDown)

  @override
  void initState() {
    super.initState();
    // Inicializa el controller, pero NO lo reproduce todavía
    _initializeVideo();
  }

  /// Inicializa el VideoPlayerController con la URL HLS
  void _initializeVideo() {
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(widget.reel.urlHls),
    );

    _videoController
        .initialize()
        .then((_) {
          if (mounted) {
            setState(() => _isInitialized = true);
            // Si ya está activo cuando termina de inicializar, reproduce
            if (widget.isActive) {
              _play();
            }
          }
        })
        .catchError((e) {
          debugPrint(
            'Error inicializando video del reel ${widget.reel.id}: $e',
          );
        });
  }

  /// Crea ChewieController (sin reproducir)
  /// Se llama durante precarga o cuando se activa el reel
  void _createChewieIfNeeded() {
    if (!_isInitialized || _chewieController != null) return;

    _chewieController = ChewieController(
      videoPlayerController: _videoController,
      autoPlay: false, // No reproducir automáticamente
      looping: false,
      showControls: true,
      materialProgressColors: ChewieProgressColors(
        playedColor: Colors.red,
        handleColor: Colors.redAccent,
        backgroundColor: Colors.grey[400]!,
        bufferedColor: Colors.grey[300]!,
      ),
      showOptions: false,
      allowPlaybackSpeedChanging: false,
      allowMuting: true,
    );

    // Aplica el último volumen usado (compartido entre reels)
    _videoController.setVolume(_sharedVolume);

    setState(
      () {},
    ); // Reconstruye para mostrar Chewie (aunque aún no reproduce)
  }

  /// Inicia la reproducción + crea ChewieController si no existe
  void _play() {
    if (!_isInitialized) return;

    // Crear Chewie si no existe
    _createChewieIfNeeded();

    // Reproducir
    _videoController.play();
    _addVideoListener();
  }

  /// Agrega listener que detecta cuando el video termina
  void _addVideoListener() {
    // Remove el listener anterior si existe
    if (_videoListener != null) {
      _videoController.removeListener(_videoListener!);
    }

    _videoListener = () {
      if (!mounted) return;

      final position = _videoController.value.position;
      final duration = _videoController.value.duration;

      // Si llegó al final (dentro de 500ms de diferencia)
      if (position.inMilliseconds > 0 &&
          duration.inMilliseconds > 0 &&
          (duration - position).inMilliseconds < 500) {
        // Pasa al siguiente reel
        _goToNextReel();
      }

      // Si el usuario cambió el volumen (con el control de Chewie),
      // lo guardamos como el volumen compartido para el próximo reel
      final currentVolume = _videoController.value.volume;
      if (currentVolume != _lastTrackedVolume) {
        _lastTrackedVolume = currentVolume;
        _sharedVolume = currentVolume;
      }
    };

    _videoController.addListener(_videoListener!);
  }

  /// Pasa al siguiente reel automáticamente
  void _goToNextReel() {
    debugPrint('Video terminó, pasando al siguiente reel...');
    widget.onVideoEnded?.call();
  }

  /// Pausa la reproducción
  void _pause() {
    if (_isInitialized && _videoController.value.isPlaying) {
      _videoController.pause();
    }
  }

  /// Detecta doble-tap manualmente comparando el tiempo entre toques.
  ///
  /// No usamos GestureDetector.onDoubleTap aquí a propósito: un
  /// GestureDetector con onTap/onDoubleTap ENTRA en la arena de gestos y,
  /// si gana, se queda con el toque — bloqueando el tap-para-pausar/
  /// mostrar-controles NATIVO de Chewie que vive debajo en el Stack (por
  /// eso antes, al ocultarse la barra de progreso, ya no había forma de
  /// volver a mostrarla: nuestro detector se quedaba con cada toque).
  ///
  /// Listener, en cambio, solo OBSERVA punteros sin competir por la
  /// arena, así que Chewie sigue recibiendo y procesando cada tap con
  /// total normalidad debajo nuestro.
  void _handlePointerDown(PointerDownEvent event) {
    final now = DateTime.now();
    if (_lastTapTime != null &&
        now.difference(_lastTapTime!) < const Duration(milliseconds: 300)) {
      widget.onDoubleTap?.call();
      _lastTapTime = null; // evita que un tercer toque rápido re-dispare
    } else {
      _lastTapTime = now;
    }
  }

  @override
  void didUpdateWidget(ReelPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Si el reel cambió (swipeó a otro reel), reinicia todo
    if (oldWidget.reel.id != widget.reel.id) {
      _dispose();
      _initializeVideo();
      return;
    }

    // Si isActive cambió de false a true: reproduce
    if (!oldWidget.isActive && widget.isActive) {
      _play();
    }
    // Si isActive cambió de true a false: pausa
    else if (oldWidget.isActive && !widget.isActive) {
      _pause();
    }

    // Si shouldPreload cambió a true (este es el siguiente reel):
    // inicializa el video Y crea el ChewieController (pero no reproduce)
    if (!oldWidget.shouldPreload && widget.shouldPreload) {
      if (!_isInitialized) {
        _initializeVideo();
      } else {
        // Ya está inicializado, solo crear Chewie
        _createChewieIfNeeded();
      }
    }
  }

  /// Limpia controllers
  void _dispose() {
    if (_videoListener != null) {
      _videoController.removeListener(_videoListener!);
      _videoListener = null;
    }
    _chewieController?.dispose();
    _chewieController = null;
    _videoController.dispose();
    _isInitialized = false;
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Si no está inicializado, mostrar thumbnail + spinner
    if (!_isInitialized) {
      return Stack(
        fit: StackFit.expand,
        children: [
          AppNetworkImage(
            imageUrl: widget.reel.thumbnailUrl,
            fit: BoxFit.cover,
          ),
          const Center(child: CircularProgressIndicator()),
        ],
      );
    }

    // Si está inicializado pero no tiene ChewieController, mostrar thumbnail
    // (esto ocurre mientras espera que sea activo)
    if (_chewieController == null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          AppNetworkImage(
            imageUrl: widget.reel.thumbnailUrl,
            fit: BoxFit.cover,
          ),
          // Play button overlay
          Center(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(20),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),
        ],
      );
    }

    // Reproduciendo con Chewie. Chewie YA trae su propio comportamiento
    // nativo de tap: pausa/reproduce Y muestra/oculta su barra de
    // controles — no lo reimplementamos. Solo superponemos un Listener
    // (no un GestureDetector) que observa los toques para detectar
    // doble-tap (like) SIN competir por el gesto ni bloquear a Chewie.
    return Stack(
      fit: StackFit.expand,
      children: [
        Chewie(controller: _chewieController!),
        Positioned.fill(
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: _handlePointerDown,
          ),
        ),
      ],
    );
  }
}
