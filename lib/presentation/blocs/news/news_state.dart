part of 'news_cubit.dart';

enum NewsStatus { initial, loading, success, error }

class NewsState extends Equatable {
  final NewsStatus status;
  final List<Post> posts;
  final int currentPage;
  final bool hasMore;
  final bool loadingMore;
  final bool isFromCache;
  final String? errorMessage;

  const NewsState({
    this.status = NewsStatus.initial,
    this.posts = const [],
    this.currentPage = 1,
    this.hasMore = true,
    this.loadingMore = false,
    this.isFromCache = false,
    this.errorMessage,
  });

  NewsState copyWith({
    NewsStatus? status,
    List<Post>? posts,
    int? currentPage,
    bool? hasMore,
    bool? loadingMore,
    bool? isFromCache,
    String? errorMessage,
  }) => NewsState(
    status: status ?? this.status,
    posts: posts ?? this.posts,
    currentPage: currentPage ?? this.currentPage,
    hasMore: hasMore ?? this.hasMore,
    loadingMore: loadingMore ?? this.loadingMore,
    isFromCache: isFromCache ?? this.isFromCache,
    // Sin `?? this.errorMessage` a propósito: un success debe limpiar
    // un error viejo en vez de arrastrarlo para siempre.
    errorMessage: errorMessage,
  );

  @override
  List<Object?> get props => [
    status,
    posts,
    currentPage,
    hasMore,
    loadingMore,
    isFromCache,
    errorMessage,
  ];
}
