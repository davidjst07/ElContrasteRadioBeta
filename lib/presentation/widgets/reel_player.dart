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

  /// Callback que se ejecuta cuando el video termina
  /// Útil para pasar automáticamente al siguiente reel
  final VoidCallback? onVideoEnded;

  const ReelPlayerWidget({
    super.key,
    required this.reel,
    required this.isActive,
    this.onVideoEnded,
  });

  @override
  State<ReelPlayerWidget> createState() => _ReelPlayerWidgetState();
}

class _ReelPlayerWidgetState extends State<ReelPlayerWidget> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  VoidCallback? _videoListener;

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

    _videoController.initialize().then((_) {
      if (mounted) {
        setState(() => _isInitialized = true);
        // Si ya está activo cuando termina de inicializar, reproduce
        if (widget.isActive) {
          _play();
        }
      }
    }).catchError((e) {
      debugPrint('Error inicializando video del reel ${widget.reel.id}: $e');
    });
  }

  /// Inicia la reproducción + crea ChewieController si no existe
  void _play() {
    if (!_isInitialized) return;

    // Si Chewie ya existe, solo reproduce
    if (_chewieController != null) {
      _videoController.play();
      _addVideoListener();
      return;
    }

    // Crear ChewieController la primera vez
    _chewieController = ChewieController(
      videoPlayerController: _videoController,
      autoPlay: true,
      looping: false,
      showControls: true,
      materialProgressColors: ChewieProgressColors(
        playedColor: Colors.red,
        handleColor: Colors.redAccent,
        backgroundColor: Colors.grey[400]!,
        bufferedColor: Colors.grey[300]!,
      ),
      showOptions: false,
    );

    // Volumen normal - el usuario puede mutearlo con el botón de Chewie
    // (No forzamos setVolume(0) porque bloquea el control del usuario)
    _videoController.setVolume(0.5); // 50% de volumen

    // Agregar listener para detectar cuando termina el video
    _addVideoListener();

    setState(() {}); // Reconstruye para mostrar Chewie
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
          const Center(
            child: CircularProgressIndicator(),
          ),
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

    // Reproduciendo con Chewie
    return Chewie(controller: _chewieController!);
  }
}
