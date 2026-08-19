part of 'reels_cubit.dart';

enum ReelsStatus {
  initial, // La app acaba de abrir, sin reels todavía
  loading, // Pidiendo la primera página
  success, // Ya hay reels en pantalla
  error,   // Falló al pedir reels
}

class ReelsState {
  final ReelsStatus status;
  final List<Reel> reels; // Lista acumulada de reels (aumenta con pagination)
  final String? nextCursor; // Cursor para la próxima página (null = no hay más reels)
  final bool loadingMore; // True mientras se pide la próxima página
  final String? errorMessage; // Mensaje de error, si status == error

  ReelsState({
    required this.status,
    required this.reels,
    this.nextCursor,
    this.loadingMore = false,
    this.errorMessage,
  });

  // Getter conveniente: ¿hay más reels para pedir?
  bool get hasMore => nextCursor != null;

  // copyWith para crear nuevas instancias con cambios selectivos
  ReelsState copyWith({
    ReelsStatus? status,
    List<Reel>? reels,
    String? nextCursor,
    bool? loadingMore,
    String? errorMessage,
  }) {
    return ReelsState(
      status: status ?? this.status,
      reels: reels ?? this.reels,
      nextCursor: nextCursor ?? this.nextCursor,
      loadingMore: loadingMore ?? this.loadingMore,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  // Estado inicial: sin reels, sin error
  factory ReelsState.initial() {
    return ReelsState(
      status: ReelsStatus.initial,
      reels: [],
      nextCursor: null,
      loadingMore: false,
      errorMessage: null,
    );
  }
}
