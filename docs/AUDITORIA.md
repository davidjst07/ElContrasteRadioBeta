# INFORME DE AUDITORÍA TÉCNICA — El Contraste Radio App v3.2.0

- **Fecha**: 23 de julio de 2026 (actualización de la auditoría de junio 2026)
- **Versión analizada**: 3.2.0+32 — **ya publicada y aprobada en producción de Play Store**
- **SDK**: Flutter 3.41.9 (stable)
- **Propósito**: Actualizar la auditoría de junio 2026 con el estado real del proyecto después de un ciclo de trabajo que implementó 7 de los 7 ítems críticos del roadmap a 3 meses, más 5 ítems del roadmap a 8 meses, y agregó funcionalidad no contemplada originalmente (splash, deep link de notificaciones, chequeo de actualizaciones).

---

## 0. RESUMEN DE CAMBIOS DESDE V3.1.0

### Resuelto ✅ (roadmap "Meses 1-3", los 7 ítems críticos)

| # | Mejora | Estado |
|---|--------|--------|
| 1 | Clean Architecture (`core/data/domain/presentation`, repositorios) | ✅ Hecho |
| 2 | Inyección de dependencias (GetIt) | ✅ Hecho |
| 3 | State Management: noticias migradas a Cubit | ✅ Hecho |
| 4 | Caché local (Hive) para noticias | ✅ Hecho — stale-while-revalidate |
| 5 | Rediseño del feed de noticias | ✅ Hecho, y más ambicioso de lo planeado: en vez de solo pasar a scroll vertical, quedó en `PageView` de una noticia a pantalla completa por swipe |
| 6 | Skeleton/Shimmer loading | ✅ Hecho |
| 7 | Proxy server para API keys | ✅ Hecho — Cloud Function `youtubeVideos` + Secret Manager; se eliminó `.env`/`flutter_dotenv` del bundle y se rotó la API key de YouTube expuesta anteriormente |

### Resuelto ✅ (adelantado del roadmap "Meses 4-8")

| # | Mejora | Estado |
|---|--------|--------|
| 8 | Paginación infinita | ✅ Hecho (junto con el ítem 4) |
| 9 | Favoritos (Hive) | ✅ Hecho |
| 10 | Buscador de noticias | ✅ Hecho |
| 12 | Notificaciones segmentadas | ⚠️ Parcial — topics FCM opcionales por categoría (`categoria_<id>`), opt-in desde la app; falta panel de administración para gestionar categorías sin tocar código |
| 17 | Wrapper de `CachedNetworkImage` | ✅ Hecho (`AppNetworkImage`) |
| 18 | Widget genérico de loading/error | ✅ Hecho (`AsyncStateView`) |

### Agregado, fuera del roadmap original

- **Splash screen** con logo de JYD Producciones.
- **Deep link de notificaciones push**: tocar una notificación (o el push mientras la app está abierta) abre directamente la noticia correspondiente — vía el payload `data` de FCM (`type`/`post_id`), no vía un esquema de URL.
- **Chequeo de actualizaciones de Play Store** (`in_app_update` + Firebase Remote Config): actualización flexible por defecto, con interruptor remoto para forzar actualización inmediata en casos críticos sin publicar código nuevo.
- **`targetSdk` actualizado a 36** — requisito de cumplimiento de Play Store que no estaba en el roadmap pero bloqueaba las subidas.

### Aún pendiente (sin cambios desde junio)

Ítems 11, 13, 14, 15, 16, 19, 20 del roadmap original — ver sección 9 actualizada.

---

## 1. ARQUITECTURA DEL PROYECTO

### 1.1 Estructura de Carpetas Actual

```
lib/
├── main.dart                              # 264 líneas — inicialización + navegación de notificaciones
├── firebase_options.dart
├── config/
│   └── local_notifications/local_notifications.dart
├── core/
│   ├── constants/news_categories.dart
│   ├── di/service_locator.dart            # GetIt
│   ├── themes/app_theme.dart
│   └── utils/{date_formatter, html_utils}.dart
├── data/
│   ├── local/                             # Hive: news_cache_store, favorites_store, notification_prefs_store
│   ├── models/                            # post, video, now_playing, playlist_song, radio_emission
│   ├── repositories/                      # emissions, now_playing, videos
│   └── services/                          # news_service, app_update_service
├── domain/
│   └── entities/push_message.dart
└── presentation/
    ├── audio/radio_player_handler.dart
    ├── blocs/{news, notifications}/
    ├── pages/{home, favorites, search, notifications, splash}/
    └── widgets/{menu_app, radio_player_widget, shimmer_box, app_network_image, async_state_view, favorite_button, news_list_tile}.dart
```

La reorganización de junio se mantiene y se amplió correctamente: los stores de Hive quedaron todos en `data/local/`, los widgets reutilizables en `presentation/widgets/`, y no hay archivos sueltos en la raíz de `lib/`.

### 1.2 Problemas de Arquitectura — Estado Actualizado

| # | Problema (junio) | Estado hoy |
|---|----------|-----------|
| 1 | Archivos en raíz de `lib/` | ✅ Resuelto |
| 2 | `home_page.dart` con ~829 líneas | 🔴 **Empeoró: ahora tiene 1013 líneas.** Ver 1.3 |
| 3 | `video_model.dart` en lugar incorrecto | ✅ Resuelto (`data/models/video_model.dart`) |
| 4 | Models de dominio mezclados | ✅ Resuelto |
| 5 | Sin capa de repositorio | ✅ Resuelto (`data/repositories/`) |

### 1.3 Hallazgo nuevo: `home_page.dart` sigue siendo el archivo más grande del proyecto

Es el único punto de la refactorización de arquitectura que no se completó — de hecho fue en la dirección contraria. Aunque la lógica de negocio salió del archivo (ahora vive en `NewsCubit`, los repositorios y los stores de Hive), la UI de las 4 pestañas (Radio, Noticias, Videos, Programación) — incluyendo sus respectivos skeletons de shimmer, favoritos, categorías y widgets internos — sigue completa en un solo archivo, que creció de 829 a **1013 líneas** con las features nuevas.

**Recomendación**: dividir por tab, por ejemplo:
```
presentation/pages/home/
├── home_page.dart          # Scaffold + AppBar + tabs, ~150 líneas
├── tabs/
│   ├── radio_tab.dart
│   ├── news_tab.dart       # incluye _NewsCard, _NewsCardSkeleton, PageView
│   ├── videos_tab.dart
│   └── schedule_tab.dart
```
Esfuerzo: bajo-medio (es mover código existente, no reescribirlo), 3-4 días. No es urgente porque `flutter analyze` está limpio y el archivo compila y funciona bien, pero cada feature nueva que toque la pantalla principal va a seguir volviendo este archivo más difícil de navegar y de revisar en pull requests.

### 1.4 Manejo de Estado — Estado Actualizado

| Aspecto | Junio | Hoy |
|---------|--------------|------|
| Notificaciones | ✅ Bloc | ✅ Sin cambios |
| Radio | ⚠️ ChangeNotifier + Provider | ⚠️ Sin cambios (funciona, no es prioritario migrarlo) |
| Noticias | ❌ FutureBuilder sin estado | ✅ `NewsCubit` con caché Hive y paginación |
| Videos | ❌ FutureBuilder sin estado | ⚠️ Sigue en `FutureBuilder`, pero ahora envuelto en `AsyncStateView` (loading/error consistentes) y con caché de 5 min del lado del proxy — no tiene caché local propia |
| Emisiones | ❌ FutureBuilder sin estado | ⚠️ Sin cambios |

### 1.5 Navegación

Sin cambios desde junio: `Navigator.push` + `MaterialPageRoute`, sin GoRouter, sin deep linking real por URL (el deep link de notificaciones push que se agregó usa el payload de FCM directamente, no una ruta/URL — ver sección 3.5).

---

## 2. RENDIMIENTO

Los puntos de junio sobre reconstrucciones innecesarias en `RadioPlayerWidget` y el manejo de `notifyListeners()` siguen vigentes sin cambios — no se tocó esa parte esta ronda.

### 2.1 Mejoras logradas

- **Skeleton loading**: implementado en Noticias, Videos y Programación (`shimmer`), reemplazando el `CircularProgressIndicator` genérico.
- **Caché de noticias**: `NewsCacheStore` (Hive) con patrón stale-while-revalidate — la app muestra contenido cacheado instantáneamente y refresca en segundo plano.
- **Paginación**: noticias cargan de a páginas con scroll infinito, ya no se trae todo de una vez.
- **Proxy con caché de 5 minutos**: el Cloud Function `youtubeVideos` cachea la respuesta de YouTube en memoria del lado del servidor, reduciendo llamadas repetidas a la API externa.

### 2.2 Sin cambios desde junio

- Polling de AzuraCast cada 15s desde cada dispositivo (ítem 14 del roadmap, evaluado pero no implementado — pendiente confirmar si el panel de AzuraCast soporta WebSocket/SSE).
- Sin `compute()`/isolates para parseo de JSON o limpieza de HTML.
- Inicio secuencial de servicios en `main()` (Firebase → FCM → notificaciones locales → AudioService), ahora con un paso adicional (Hive.initFlutter()) pero sigue siendo secuencial, no paralelizado.

---

## 3. SEGURIDAD

### 3.1 API Keys — RESUELTO ✅

La API key de YouTube ya **no está en el bundle de la app**. Se implementó un Cloud Function (`youtubeVideos`) que hace la llamada a la API de YouTube del lado del servidor, usando Secret Manager para guardar la key. La key original que estaba expuesta en `.env` fue **rotada** (se generó una nueva, restringida a YouTube Data API v3, sin restricción de la anterior que causaba el bug de sobre-restricción).

`flutter_dotenv` fue eliminado del proyecto por completo — ya no hay ningún secreto empaquetado en el APK/AAB.

### 3.2 Hallazgo nuevo: el proxy `youtubeVideos` es un endpoint público sin autenticación

```js
exports.youtubeVideos = onRequest(
  {secrets: [youtubeApiKey], cors: true, maxInstances: 5},
  ...
```

`cors: true` acepta peticiones de cualquier origen, y no hay verificación de que la petición venga realmente de la app (ni Firebase App Check, ni un token, ni nada). Cualquiera que descubra la URL (`https://us-central1-elcontrastenoticias-f0ac1.cloudfunctions.net/youtubeVideos`) puede llamarla directamente y consumir la cuota de YouTube API usando la key del servidor.

**Mitigación actual, parcial**: caché de 5 minutos en memoria (limita cuánto se llega a llamar realmente a YouTube) + `maxInstances: 5` (limita el costo máximo de Cloud Functions aunque abusen del endpoint).

**Riesgo real**: bajo-medio. No hay datos sensibles detrás del endpoint (solo videos públicos del canal de YouTube), y el peor caso es agotar la cuota gratuita de YouTube API (10,000 unidades/día) o generar algo de costo en Cloud Functions — no es una fuga de datos. Pero es la única puerta de la app que quedó sin ningún control de acceso.

**Recomendación**: agregar [Firebase App Check](https://firebase.google.com/docs/app-check) al Cloud Function — verifica que la petición venga de una instancia legítima de la app (Play Integrity en Android) antes de ejecutar la lógica. Esfuerzo: bajo (1-2 días), costo: $0 en el tier gratuito para este volumen.

### 3.3 Hallazgo nuevo: `usesCleartextTraffic="true"` probablemente ya no es necesario

Verifiqué las 3 URLs base que usa la app:
- WordPress: `https://elcontraste.co/wp-json/...` — HTTPS
- AzuraCast now-playing: `https://radio.elcontraste.co/api/nowplaying/...` — HTTPS
- Stream de radio: `https://radio.elcontraste.co/listen/el_contraste_radio/radio.mp3` — HTTPS

Las tres son HTTPS. El flag `usesCleartextTraffic="true"` en `AndroidManifest.xml` sigue activo de cuando posiblemente el stream era HTTP. **Recomendación**: probar cambiándolo a `false` (o quitar el atributo, que por defecto es `false` desde Android 9) y confirmar que el stream y todas las llamadas siguen funcionando — si es así, cierra una superficie de ataque (permite que cualquier tráfico HTTP sin cifrar entre/salga de la app) sin costo ni esfuerzo real.

### 3.4 Autenticación

Sin cambios desde junio: no existe sistema de autenticación de usuarios, ni Firebase Auth, ni login social. Esto sigue siendo un prerrequisito si en algún momento se implementa el ítem 11 (comentarios).

### 3.5 Deep link de notificaciones — aclaración de seguridad

El deep link que abre una noticia específica al tocar una notificación push **no usa un esquema de URL** (no hay `intent-filter` con `android:scheme` en el manifest, ni paquetes como `uni_links`/`app_links`). Usa directamente el campo `data` del mensaje FCM (`type`, `post_id`), leído por el código Dart. Esto significa:
- No hay superficie de ataque de "deep link injection" vía URL maliciosa, porque no existe ese mecanismo.
- Pero tampoco se puede compartir un link tipo `https://app.elcontraste.co/noticia/1234` desde fuera de la app (WhatsApp, correo, web) que abra la noticia directo — si se quiere esa funcionalidad, es un desarrollo aparte (Android App Links).

### 3.6 Permisos Android

Sin cambios desde junio — todos los permisos declarados (`INTERNET`, `ACCESS_NETWORK_STATE`, `POST_NOTIFICATIONS`, `WAKE_LOCK`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK`) son necesarios para las funciones que ya tiene la app.

---

## 4. EXPERIENCIA DE USUARIO (UX)

### 4.1 Resuelto ✅

- **Feed de noticias**: ya no es scroll horizontal. Ahora es `PageView` vertical, una noticia a pantalla completa por swipe — más allá de lo que pedía el roadmap original (que solo pedía scroll vertical con tarjetas).
- **Reproductor de radio**: se redujo de tamaño cuando el usuario está en la pestaña de Noticias, dejando más espacio a las noticias.
- **Loading states**: shimmer en vez de spinners genéricos.
- **Favoritos y buscador**: accesibles desde el ícono de búsqueda en el AppBar y desde el drawer.

### 4.2 Accesibilidad — sin cambios, sigue en cero

Confirmé que **no hay ningún widget `Semantics`** en todo el proyecto (`grep -rn "Semantics(" lib/` → 0 resultados). Sigue sin soporte para lectores de pantalla, sin adaptación a tamaño de fuente del sistema. Este punto no se tocó en este ciclo y sigue siendo una brecha real, especialmente relevante para una app de noticias que aspira a alcance regional amplio.

### 4.3 Categorías de Noticias

Sin cambios: siguen siendo las mismas 4 (Últimas, Pasto, Nariño, Colombia), ahora centralizadas en `core/constants/news_categories.dart` en vez de estar hardcodeadas — más fácil de ampliar el día que WordPress exponga más categorías, pero la limitación funcional sigue igual.

---

## 5. ESCALABILIDAD

| Factor | Junio | Hoy |
|--------|--------|--------|
| Caché de datos | ❌ No existe | ✅ Noticias (Hive) |
| Paginación | ❌ No existe | ✅ Noticias |
| Backend propio | ❌ No | ⚠️ Parcial — 1 Cloud Function (proxy de YouTube), no un backend completo |
| State Management | ⚠️ Básico | ✅ Cubit para noticias, resto sin cambios |
| Testing | ❌ Sin tests | ❌ **Sigue sin tests** — no existe carpeta `test/` |
| CI/CD | ❌ No configurado | ❌ **Sigue sin configurar** — no hay workflows en `.github/` |

### 5.1 Dependencias desactualizadas (mantenimiento rutinario, no urgente)

`flutter pub outdated` reporta 34 dependencias ancladas en `pubspec.lock` a versiones más viejas que la disponible, y 11 con actualizaciones mayores posibles sin romper el rango declarado en `pubspec.yaml` (`get_it` 8→9, `bloc` 9.1→9.2, `font_awesome_flutter` 10→11, `youtube_player_flutter` 9→10, `flutter_local_notifications` 21→22, entre otras). No detecté ninguna con una vulnerabilidad conocida asociada — es deuda técnica normal de un proyecto activo, no una alerta de seguridad. Recomiendo revisar `flutter pub outdated` cada 2-3 meses y actualizar en bloques pequeños (no todas a la vez) para poder aislar cualquier breaking change.

---

## 6. MONETIZACIÓN

Sin cambios desde junio — sigue en cero monetización, cero analytics. El análisis de oportunidades de la auditoría original (sección 6, no reproducida aquí para no duplicar) sigue vigente sin modificaciones.

---

## 7. FUNCIONALIDADES — Estado Actualizado

| Funcionalidad | Junio | Hoy |
|---------------|-----------|-----------|
| Búsqueda de noticias | ❌ | ✅ Hecho |
| Favoritos / guardar | ❌ | ✅ Hecho |
| Modo Offline | ❌ | ⚠️ Parcial — caché de noticias sí, resto de la app no |
| Notificaciones segmentadas | ⚠️ Parcial | ⚠️ Parcial (por categoría, funcional pero sin panel admin) |
| Historial de lectura | ❌ | ❌ Sin cambios |
| Comentarios en noticias | ❌ | ❌ Sin cambios |
| Podcasts | ❌ | ❌ Sin cambios (WordPress sigue sin post type de podcasts) |
| Modo oscuro | ✅ | ✅ |
| Transmisiones en vivo | ✅ | ✅ |
| Notificaciones push | ✅ | ✅ + deep link a la noticia |
| Splash screen de marca | — | ✅ Nuevo |
| Chequeo de actualizaciones | — | ✅ Nuevo |

---

## 8. ANÁLISIS SISTEMA DE COMENTARIOS

Sin cambios desde junio — este análisis (comparativa Firebase/Supabase/WordPress/anónimo, recomendación de Firestore + Auth) sigue siendo válido tal cual estaba, porque el ítem 11 del roadmap no se tocó en este ciclo. Ver el documento de junio o el historial de git para el detalle completo si se retoma este ítem.

---

## 9. ROADMAP — Estado Actualizado

### Completado en este ciclo ✅

| # | Mejora | Estado |
|---|--------|--------|
| 1 | Clean Architecture | ✅ |
| 2 | Inyección de dependencias | ✅ |
| 3 | State Management (Cubit) | ✅ |
| 4 | Caché local (Hive) | ✅ |
| 5 | Scroll vertical de noticias | ✅ (superado: PageView) |
| 6 | Skeleton/Shimmer loading | ✅ |
| 7 | Proxy server para API keys | ✅ |
| 8 | Paginación infinita | ✅ |
| 9 | Favoritos | ✅ |
| 10 | Buscador de noticias | ✅ |
| 12 | Notificaciones segmentadas | ⚠️ Parcial |
| 17 | Wrapper CachedNetworkImage | ✅ |
| 18 | Widget genérico AsyncWidgetBuilder | ✅ |

### Pendiente — sin cambios desde junio

| # | Mejora | Impacto | Dificultad | Costo | Tiempo | Notas |
|---|--------|---------|-----------|-------|--------|-------|
| 11 | Sistema de comentarios (Firebase + Auth) | 🟡 Alto | Alta | $0-20/mes | 4-6 sem | Requiere decisión de producto, no solo técnica |
| 13 | Modo Offline completo | 🟡 Alto | Alta | $0 | 4-6 sem | Ya hay caché de noticias; falta radio/videos/programación y sincronización |
| 14 | Reducir polling AzuraCast (WebSocket/SSE) | 🟡 Medio | Baja | $0 | 1 sem | Pendiente confirmar si el panel de AzuraCast lo soporta (el endpoint SSE estándar probado devolvió 404) |
| 15 | Google AdMob | 🟡 Alto | Baja | $0 | 2 sem | Requiere decisión de producto |
| 16 | Pantalla de Podcasts | 🟡 Medio | Media | $0 | 2-3 sem | No aplica todavía — WordPress no tiene post type de podcasts |
| 19 | Testing (unit + widget) | 🟡 Medio | Media | $0 | Continuo | **Sigue en cero, y la app ya tiene bastante más superficie que auditar (Cubit, DI, Hive, Cloud Functions) que en junio** |
| 20 | CI/CD (GitHub Actions) | 🟡 Medio | Media | $0-30/mes | 2-3 sem | Sin cambios |

### Nuevo hallazgo de esta ronda, agregado al roadmap

| # | Mejora | Impacto | Dificultad | Costo | Tiempo |
|---|--------|---------|-----------|-------|--------|
| 31 | Firebase App Check en el Cloud Function `youtubeVideos` | 🟡 Medio | Baja | $0 | 1-2 días |
| 32 | Evaluar quitar `usesCleartextTraffic="true"` | 🟢 Bajo | Muy baja | $0 | < 1 día (con prueba de regresión del stream) |
| 33 | Dividir `home_page.dart` (1013 líneas) por tab | 🟡 Medio | Baja-Media | $0 | 3-4 días |
| 34 | Accesibilidad básica (`Semantics` en controles clave: play/pausa, favoritos, navegación) | 🟡 Medio | Media | $0 | 1-2 sem |
| 35 | Deep linking real por URL (Android App Links) — solo si se quiere compartir noticias fuera de la app | 🟢 Bajo | Media | $0 | 2-3 sem |

Las mejoras "Meses 9-12" de la auditoría de junio (sistema de usuarios, reacciones, reportes ciudadanos, reels, gamificación, membresías, tablets, deep linking, analytics) siguen sin cambios y no se tocaron en este ciclo.

---

## 10. RESUMEN EJECUTIVO

### Lo que se resolvió desde junio ✅
1. Arquitectura limpia con DI — completo.
2. Noticias con caché local, paginación y Cubit — completo.
3. Seguridad de API keys — completo, incluida rotación de la key expuesta.
4. UX del feed de noticias — completo, superó lo planeado.
5. Favoritos, buscador, notificaciones segmentadas, wrappers reutilizables — completo/parcial.
6. La app ya está publicada en producción con todo esto (3.2.0+32, aprobada en Play Store).

### Lo que sigue urgente 🔴
1. **`home_page.dart` con 1013 líneas** — el único punto de la refactorización original que empeoró en vez de mejorar.
2. **Testing en cero** — cada vez más riesgoso a medida que crece la complejidad (Cubit, DI, Hive, Cloud Functions).
3. **Sin App Check en el Cloud Function** — única puerta sin control de acceso del proyecto.

### Lo que aportará más valor a continuación 🟡
1. Testing y CI/CD (para poder seguir agregando features sin miedo a romper algo).
2. Modo offline completo (radio/videos, no solo noticias).
3. Accesibilidad básica.
4. Decisión de producto sobre comentarios y monetización (son decisiones de negocio, no solo técnicas).

---

*Documento actualizado el 23 de julio de 2026 sobre la base de la auditoría original de junio de 2026.*
*Para el detalle completo de las secciones sin cambios (monetización, comparativa de comentarios, roadmap meses 9-12), ver el historial de git de este archivo.*
