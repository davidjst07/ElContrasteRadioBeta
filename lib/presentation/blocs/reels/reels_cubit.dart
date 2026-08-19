import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:elcontrasteapp/data/models/reel_model.dart';
import 'package:elcontrasteapp/data/services/reels_service.dart';
import 'package:get_it/get_it.dart';

part 'reels_state.dart';

class ReelsCubit extends Cubit<ReelsState> {
  final ReelsService _reelsService;

  ReelsCubit({ReelsService? reelsService})
      : _reelsService = reelsService ?? GetIt.I<ReelsService>(),
        super(ReelsState.initial());

  /// Pide la primera página de reels (sin cursor)
  Future<void> fetchInitial() async {
    try {
      // Cambia el estado a "loading" para mostrar spinner/skeleton
      emit(state.copyWith(status: ReelsStatus.loading));

      // Llamamos al servicio sin cursor (primera página)
      final result = await _reelsService.fetchReels(limit: 10);

      // Éxito: emitimos los reels + el cursor para la próxima página
      emit(
        state.copyWith(
          status: ReelsStatus.success,
          reels: result.reels,
          nextCursor: result.nextCursor,
          loadingMore: false,
          errorMessage: null,
        ),
      );
    } catch (e) {
      // Error: emitimos el mensaje de error
      emit(
        state.copyWith(
          status: ReelsStatus.error,
          errorMessage: 'Error al cargar reels: $e',
        ),
      );
    }
  }

  /// Pide la próxima página de reels (con cursor)
  /// No hace nada si ya está pidiendo más o si no hay más reels
  Future<void> loadMore() async {
    // Guardias: si ya está pidiendo más, o si no hay cursor, no hace nada
    if (state.loadingMore || !state.hasMore) {
      return;
    }

    try {
      // Marca que está pidiendo más (para no triggear dos peticiones simultáneas)
      emit(state.copyWith(loadingMore: true));

      // Llamamos al servicio CON el cursor de la página anterior
      final result = await _reelsService.fetchReels(
        limit: 10,
        cursor: state.nextCursor,
      );

      // Éxito: agregamos los NUEVOS reels a la lista existente
      emit(
        state.copyWith(
          status: ReelsStatus.success,
          reels: [...state.reels, ...result.reels], // Append, no reemplazo
          nextCursor: result.nextCursor,
          loadingMore: false,
          errorMessage: null,
        ),
      );
    } catch (e) {
      // Error al pedir más: mantenemos los reels que ya tenemos,
      // pero marcamos que falló esta carga incremental
      emit(
        state.copyWith(
          loadingMore: false,
          errorMessage: 'Error al cargar más reels: $e',
        ),
      );
    }
  }

  /// Reinicia el feed (útil si hay error y el usuario presiona "Reintentar")
  Future<void> retry() async {
    await fetchInitial();
  }
}
