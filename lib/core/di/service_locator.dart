import 'package:get_it/get_it.dart';

import 'package:elcontrasteapp/data/services/news_service.dart';
import 'package:elcontrasteapp/data/services/reels_service.dart';
import 'package:elcontrasteapp/data/repositories/videos_repository.dart';
import 'package:elcontrasteapp/data/local/news_cache_store.dart';
import 'package:elcontrasteapp/data/local/favorites_store.dart';
import 'package:elcontrasteapp/data/local/notification_prefs_store.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  getIt.registerLazySingleton<NewsService>(() => NewsService());
  getIt.registerLazySingleton<ReelsService>(() => ReelsService());
  getIt.registerLazySingleton<VideosRepository>(() => VideosRepository());
  getIt.registerLazySingleton<NewsCacheStore>(() => NewsCacheStore());
  getIt.registerLazySingleton<FavoritesStore>(() => FavoritesStore());
  getIt.registerLazySingleton<NotificationPrefsStore>(
    () => NotificationPrefsStore(),
  );
}
