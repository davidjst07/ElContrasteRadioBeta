import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:elcontrasteapp/data/local/news_cache_store.dart';
import 'package:elcontrasteapp/data/models/post_model.dart';
import 'package:elcontrasteapp/data/services/news_service.dart';

part 'news_state.dart';

class NewsCubit extends Cubit<NewsState> {
  final NewsService newsService;
  final NewsCacheStore cacheStore;
  final int? categoryId;
  final String? search;
  static const int _perPage = 10;

  // Evita que loadMore() pida la página 2 mientras la página 1 todavía
  // se está revalidando en background (ver fetchInitial()).
  bool _revalidating = false;

  bool get _isSearch => search != null && search!.isNotEmpty;

  NewsCubit({
    required this.newsService,
    required this.cacheStore,
    required this.categoryId,
    this.search,
  }) : super(const NewsState());

  Future<void> fetchInitial() async {
    // Los resultados de búsqueda no se cachean — son consultas puntuales,
    // no tiene sentido guardarlas para "modo offline".
    if (_isSearch) {
      emit(state.copyWith(status: NewsStatus.loading));
      _revalidating = true;
      await _fetchFirstPageFromNetwork();
      _revalidating = false;
      return;
    }

    final cached = await cacheStore.read(categoryId);
    if (cached != null && cached.isNotEmpty) {
      emit(
        state.copyWith(
          status: NewsStatus.success,
          posts: cached,
          currentPage: 1,
          hasMore: true,
          isFromCache: true,
        ),
      );
    } else {
      emit(state.copyWith(status: NewsStatus.loading));
    }

    _revalidating = true;
    await _fetchFirstPageFromNetwork();
    _revalidating = false;
  }

  Future<void> _fetchFirstPageFromNetwork() async {
    try {
      final posts = await newsService.fetchPosts(
        categoryId: categoryId,
        search: search,
        page: 1,
        perPage: _perPage,
      );
      if (!_isSearch) {
        unawaited(cacheStore.write(categoryId, posts));
      }
      emit(
        state.copyWith(
          status: NewsStatus.success,
          posts: posts,
          currentPage: 1,
          hasMore: posts.length == _perPage,
          isFromCache: false,
          errorMessage: null,
        ),
      );
    } catch (e) {
      debugPrint('NewsCubit: fallo el fetch inicial: $e');
      if (state.posts.isEmpty) {
        emit(
          state.copyWith(status: NewsStatus.error, errorMessage: e.toString()),
        );
      }
      // si ya había posts (de caché), se dejan mostrados en silencio.
    }
  }

  Future<void> loadMore() async {
    if (_revalidating ||
        state.loadingMore ||
        !state.hasMore ||
        state.status != NewsStatus.success) {
      return;
    }
    emit(state.copyWith(loadingMore: true));
    final nextPage = state.currentPage + 1;
    try {
      final morePosts = await newsService.fetchPosts(
        categoryId: categoryId,
        search: search,
        page: nextPage,
        perPage: _perPage,
      );
      emit(
        state.copyWith(
          posts: [...state.posts, ...morePosts],
          currentPage: nextPage,
          hasMore: morePosts.length == _perPage,
          loadingMore: false,
        ),
      );
    } catch (e) {
      debugPrint('NewsCubit: fallo loadMore: $e');
      emit(state.copyWith(loadingMore: false, hasMore: false));
    }
  }
}
