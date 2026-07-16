# INFORME DE AUDITORÍA TÉCNICA — El Contraste Radio App v3.1.0

- **Fecha**: Junio 2026
- **Versión analizada**: 3.1.0+31
- **SDK**: Flutter ^3.9.0
- **Propósito**: Auditoría completa de arquitectura, rendimiento, seguridad, UX, escalabilidad, monetización y roadmap estratégico 12 meses.

---

## 1. ARQUITECTURA DEL PROYECTO

### 1.1 Estructura de Carpetas Actual

```
lib/
├── main.dart                              # Punto de entrada (sobrecargado)
├── firebase_options.dart                  # Config Firebase generada
├── audio_state_service.dart               # RadioPlayerHandler (audio)
├── now_playing_service.dart               # AzuraCast + NowPlaying models
├── emissions_service.dart                 # Servicio de emisiones guardadas
├── config/
│   └── local_notifications/
│       └── local_notifications.dart
├── core/
│   └── themes/
│       └── app_theme.dart
├── data/
│   ├── models/
│   │   └── post_model.dart
│   └── services/
│       └── news_service.dart
├── domain/
│   └── entities/
│       └── push_message.dart
└── presentation/
    ├── blocs/
    │   └── notifications/
    │       ├── notifications_bloc.dart
    │       ├── notifications_event.dart
    │       └── notifications_state.dart
    ├── pages/
    │   └── home/
    │       ├── home_page.dart               # ~829 líneas (TODO en un archivo)
    │       ├── news_detail_page.dart
    │       ├── video_player_page.dart
    │       ├── video_model.dart
    │       └── youtube_service.dart
    └── widgets/
        ├── menu_app.dart
        └── radio_player_widget.dart
```

### 1.2 Problemas de Arquitectura

| # | Problema | Severidad | Archivo |
|---|----------|-----------|---------|
| 1 | **Archivos en raíz de lib/** — `audio_state_service.dart`, `now_playing_service.dart`, `emissions_service.dart` deberían estar en carpetas organizadas | Alta | `lib/` |
| 2 | **home_page.dart con ~829 líneas** — mezcla widgets, lógica de negocio, servicios y estilos | Crítica | `lib/presentation/pages/home/home_page.dart` |
| 3 | **video_model.dart en lugar incorrecto** — debería estar en `data/models/` | Media | `lib/presentation/pages/home/video_model.dart` |
| 4 | **Models de dominio mezclados** — `Post` (WP) y `Video` (YT) deberían ser `data/models/`, `PushMessage` en `domain/entities/` está bien | Media | Varios |
| 5 | **Sin capa de repositorio** — `NewsService()` llama directo a HTTP sin abstracción | Alta | `lib/data/services/news_service.dart` |

### 1.3 Código Duplicado y Deuda Técnica

1. **Singleton manual duplicado**: `NewsService()` y `YoutubeService()` implementan el mismo patrón singleton manual. Mejor usar inyección de dependencias (GetIt/Riverpod).
2. **`_cleanHtml()` inline**: El método de limpieza HTML está definido como método privado dentro de `_NewsCard`. Debería ser un utility reutilizable.
3. **Patrón FutureBuilder repetido**: El mismo patrón `FutureBuilder<List<T>>` con `CircularProgressIndicator` se repite en `_NewsWidget` (línea 317), `_VideosWidget` (línea 549) y `SimpleScheduleWidget` (línea 715). Debería ser un widget genérico.
4. **CachedNetworkImage sin wrapper**: El placeholder + errorWidget se repite idéntico en `_NewsCard` (línea 395), `_VideosWidget` (línea 599) y `NewsDetailPage` (línea 25).
5. **Limpieza HTML duplicada**: `_cleanHtml()` en `home_page.dart` línea 521 y el `replaceAll` en `post_model.dart` línea 32 hacen lo mismo.

### 1.4 Manejo de Estado

| Aspecto | Estado Actual | Problema |
|---------|--------------|----------|
| Notificaciones | ✅ Bloc (flutter_bloc) | Correcto, bien implementado |
| Radio | ⚠️ ChangeNotifier + Provider | ~14 `notifyListeners()` manuales |
| Noticias | ❌ FutureBuilder sin estado | Sin caché, se recarga al cambiar tab |
| Videos | ❌ FutureBuilder sin estado | Sin caché |
| Emisiones | ❌ FutureBuilder sin estado | Sin caché |

### 1.5 Navegación

- **Sin GoRouter ni Navigator 2.0** — se usa `Navigator.push` con `MaterialPageRoute`.
- Sin deep linking, sin rutas nombradas, sin soporte para web (URLs).
- `NavigatorKey` global usado desde notificaciones — frágil y acoplado.

---

## 2. RENDIMIENTO

### 2.1 Reconstrucciones Innecesarias

| Widget | Problema | Impacto |
|--------|----------|---------|
| `_NewsWidget`/`_VideosWidget` | `FutureBuilder` se reconstruye en cada `setState` del padre | Medio |
| `_TabButton` | Usa `GestureDetector` en vez de `InkWell`/`TextButton` | Bajo |
| `MenuApp` | `BlocBuilder` envuelve todo el menú, no solo notificaciones | Medio |
| `RadioPlayerWidget` | Múltiples `StreamBuilder` anidados + `Consumer` → reconstrucción en cascada | Alto |
| `Image.asset('assets/logoradio.png')` | Sin `const`, se recarga en cada build | Bajo |

### 2.2 Consumo de Memoria

1. **Sin paginación**: `fetchPosts()` sin límite explícito. WordPress default = 10, pero sin paginación futura.
2. **Scroll horizontal de noticias**: Tarjetas de 450px de alto en `ListView.builder` horizontal → todas se construyen si no hay viewport suficiente.
3. **`CachedNetworkImage` sin dimensiones en detalle**: Las imágenes inline del HTML (vía `TagExtension`) no tienen width/height fijos → re-layout constante.
4. **No se usa `const` en varios constructores** donde es posible.

### 2.3 Operaciones en Background

| Operación | Hilo | Debería estar en |
|-----------|------|-----------------|
| `fetchPosts()` | Main | Background isolate o `compute()` |
| `getNowPlaying()` (cada 15s) | Main | Background isolate |
| `_cleanHtml()` (procesamiento HTML) | Main | `compute()` |
| `jsonDecode` de respuestas HTTP | Main | `compute()` |

### 2.4 Tiempos de Carga

1. **Inicio secuencial**: `main()` inicializa Firebase → FCM → Local Notifications → dotenv → AudioService en serie.
2. **Sin skeleton loading** en noticias, videos ni emisiones. Solo `CircularProgressIndicator`.
3. **YouTube API** puede ser lenta (1-3s). Sin timeout específico en `fetchChannelVideos()`.

---

## 3. SEGURIDAD

### 3.1 CRÍTICO — API Keys Expuestas en el Bundle

| Key | Archivo | Riesgo |
|-----|---------|--------|
| `YOUTUBE_API_KEY=AIzaSyD4q-XN1Rccom7NKN_gdDA-TL8wuaVGWi4` | `.env` (incluido en bundle via flutter_dotenv) | Uso no autorizado de YouTube API por terceros |
| Firebase API Keys (4 plataformas) | `firebase_options.dart` | Bajo (protegidas por Firebase App Check) |

**Solución**: Implementar un proxy server (Cloudflare Worker, Firebase Functions, o backend propio) que haga las llamadas a APIs externas y exponga endpoints propios con rate limiting.

### 3.2 Consumo de APIs

| API | Tipo | Seguridad |
|-----|------|-----------|
| `https://elcontraste.co/wp-json/wp/v2/posts` | WordPress REST | Público — sin restricciones |
| `https://radio.elcontraste.co/api/nowplaying/...` | AzuraCast | Público — sin autenticación |
| `https://www.googleapis.com/youtube/v3/search` | YouTube Data API | Key expuesta — sin restricción de referrer |

### 3.3 Autenticación

- **No existe** sistema de autenticación en la app.
- FCM tokens se obtienen pero **no se almacenan** ni envían a un backend.
- Sin Firebase Auth, Sin Google Sign-In, Sin Apple Sign-In.

### 3.4 Permisos Android

| Permiso | Estado | Uso |
|---------|--------|-----|
| `INTERNET` | ✅ | Requerido |
| `ACCESS_NETWORK_STATE` | ✅ | Requerido |
| `POST_NOTIFICATIONS` | ✅ | Requerido |
| `WAKE_LOCK` | ✅ | Para audio en segundo plano |
| `FOREGROUND_SERVICE` | ✅ | Para audio en segundo plano |
| `FOREGROUND_SERVICE_MEDIA_PLAYBACK` | ✅ | Android 14+ |

**Riesgo**: `usesCleartextTraffic="true"` en AndroidManifest.xml permite tráfico HTTP no cifrado. Necesario si el stream de radio es HTTP, pero debería restringirse si es posible.

---

## 4. EXPERIENCIA DE USUARIO (UX)

### 4.1 Navegación

- Drawer lateral con enlaces a redes sociales, contacto, WhatsApp, web.
- 3 tabs: Radio, Noticias, Videos.
- Sin bottom navigation ni rutas anidadas.
- Sin deep linking (no se puede compartir una noticia con link directo a la app).

### 4.2 Flujo de Lectura de Noticias

**Problema crítico**: Las noticias se muestran en **scroll horizontal** (`ListView.builder` con `scrollDirection: Axis.horizontal`). Esto es contra-intuitivo para una app de noticias:

- El usuario espera scroll vertical (como Twitter, Facebook, cualquier RSS reader).
- Cada tarjeta ocupa 85% del ancho de pantalla + altura de 450px → swipe horizontal + scroll vertical dentro de la tarjeta.
- La etiqueta "Leer noticia completa" es confusa si ya se ve el contenido parcial.

**Recomendación**: Migrar a scroll vertical con tarjetas de altura dinámica y carga infinita (paginación).

### 4.3 Categorías de Noticias

Solo 4 categorías: Últimas, Pasto, Nariño, Colombia. Muy limitado para un medio regional. WordPress puede tener más categorías que no se están exponiendo.

### 4.4 Accesibilidad

- ❌ Sin `Semantics` en ningún widget.
- ❌ Sin soporte para lectores de pantalla.
- ❌ Sin adaptación a preferencias de tamaño de fuente del sistema.
- ⚠️ Contraste de color: `#2A86C7` (azul) sobre `#0B1B2B` (azul oscuro) tiene ratio bajo.

### 4.5 Pantallas Confusas

| Pantalla | Problema |
|----------|----------|
| **Radio** | Logo + reproductor + "Now Playing" + emisiones guardadas. Demasiada info junta |
| **Noticias** | Scroll horizontal + tarjetas muy grandes + categorías poco visibles |
| **Detalle noticia** | AppBar con título completo (se trunca). Sin barra de progreso de lectura |
| **Videos** | Solo miniaturas. Sin descripción, fecha, ni duración visible |

---

## 5. ESCALABILIDAD

### 5.1 Preparación para Crecimiento

| Factor | Estado | Riesgo |
|--------|--------|--------|
| Caché de datos | ❌ No existe | Sin caché = sin offline |
| Paginación | ❌ No existe | +50 noticias → app lenta |
| CDN imágenes | ⚠️ Parcial (CachedNetworkImage) | WordPress ya optimiza |
| Backend propio | ❌ No | Dependencia total de WP |
| State Management | ⚠️ Básico | No escala a +10 pantallas |
| Testing | ❌ Sin tests | Sin unit, widget, ni integration |
| CI/CD | ❌ No configurado | Sin automatización |

### 5.2 Cuellos de Botella Futuros

1. **WordPress API sin caché**: Con +1000 peticiones/día, WordPress puede rate-limitear.
2. **YouTube API**: Cuota gratuita 10,000 unidades/día. Cada fetch = 100 unidades. Con 100 usuarios/día se agota.
3. **AzuraCast polling**: Cada 15s desde CADA dispositivo. Con 1000 usuarios → ~5.7M requests/día.
4. **Sin base de datos local**: Sin persistencia offline, la app depende 100% de conexión.

### 5.3 Modularización

- Sin división por features (todo plano en `lib/`).
- Sin inyección de dependencias.
- Sin capa de repositorio.

---

## 6. MONETIZACIÓN

### 6.1 Estado Actual

- **Cero monetización** — la app es completamente gratuita.
- **Sin anuncios**, sin suscripciones, sin donaciones.
- Sin tracking de analytics (no hay Firebase Analytics, ni Google Analytics).

### 6.2 Oportunidades

| Oportunidad | Impacto | Dificultad | Ingreso estimado |
|-------------|---------|------------|------------------|
| **Google AdMob** (banners + intersticiales) | Medio | Baja | $50-300/mes |
| **Donaciones** (Buy Me a Coffee / PayPal) | Bajo | Muy Baja | $10-50/mes |
| **Publicidad nativa** (auspicios locales) | Alto | Media | $200-1000/mes |
| **Contenido premium** (suscripción) | Alto | Alta | $300-2000/mes |
| **Membresías** (contenido exclusivo) | Medio | Alta | $100-500/mes |

---

## 7. FUNCIONALIDADES RECOMENDADAS

| Funcionalidad | Prioridad | Impacto UX | Esfuerzo | ¿Ya existe? |
|---------------|-----------|-----------|----------|-------------|
| Búsqueda de noticias | 🔴 Alta | Alto | Medio | ❌ |
| Favoritos / guardar | 🔴 Alta | Alto | Medio | ❌ |
| Modo Offline | 🔴 Alta | Crítico | Alto | ❌ |
| Historial de lectura | 🟡 Media | Medio | Medio | ❌ |
| Perfil de usuario | 🟡 Media | Medio | Alto | ❌ |
| Sistema de usuarios | 🟡 Media | Alto | Alto | ❌ |
| Notificaciones segmentadas | 🔴 Alta | Alto | Alto | ⚠️ Parcial |
| Comentarios en noticias | 🟡 Media | Alto | Medio-Alto | ❌ |
| Reacciones (me gusta) | 🟡 Media | Medio | Bajo | ❌ |
| Reportes ciudadanos | 🟢 Baja | Diferenciador | Alto | ❌ |
| Videos tipo Reels/Shorts | 🟢 Baja | Medio | Alto | ❌ |
| Podcasts | 🟡 Media | Medio | Bajo | ❌ |
| Gamificación | 🟢 Baja | Lealtad | Alto | ❌ |
| Modo oscuro | ✅ Ya existe | — | — | ✅ |
| Transmisiones en vivo | ✅ Ya existe | — | — | ✅ |
| Notificaciones push | ✅ Ya existe | — | — | ✅ |

---

## 8. ANÁLISIS SISTEMA DE COMENTARIOS

### 8.1 Ventajas y Desventajas

| Ventajas | Desventajas |
|----------|-------------|
| +30-40% retención de usuarios | Riesgo legal (Ley 1273/2009 Colombia) |
| Comunidad alrededor del medio | Moderación: $500-2000/mes (humana) |
| Feedback directo de lectores | Costo IA moderación: $100-300/mes |
| Mayor tiempo en app | Contenido tóxico daña reputación |
| SEO (comentarios en WordPress) | Rendimiento adicional |

### 8.2 Comparativa de Alternativas

| Factor | A. WordPress Nativo | B. Firebase Firestore | C. Supabase | D. Solo Google Auth | E. Redes Sociales | F. Anónimo Moderado |
|--------|---------------------|----------------------|-------------|---------------------|-------------------|---------------------|
| **Complejidad** | Baja (ya tienes WP) | Media-Alta | Media | Baja | Baja | Muy Baja |
| **Costo** | $0 (ya incluido) | Gratis 50K docs/día | Gratis 500MB/50K rows | $0 | $0 | $0 |
| **Escalabilidad** | ⚠️ Media | ✅ Alta | ✅ Alta | ✅ Alta | ✅ Alta | ✅ Alta |
| **Seguridad** | ⚠️ Media | ✅ Alta | ✅ Alta | ✅ Alta | ⚠️ Media | ❌ Baja |
| **UX Nativa** | ❌ WebView | ✅ Nativa | ✅ Nativa | ✅ Nativa | ⚠️ Media | ⚠️ Baja |
| **Moderación** | Herramientas WP | Custom vía Admin panel | Custom SQL | Custom | Moderación red social | Muy difícil |
| **Offline** | ❌ No | ✅ Firestore offline | ✅ | ❌ No | ❌ No | ✅ |
| **Login social** | ❌ No nativo | Firebase Auth | Supabase Auth | Solo Google | Nativo | No necesita |
| **Riesgo trolls** | Medio | Bajo | Bajo | Medio | Alto | Muy Alto |

### 8.3 Recomendación

**Opción recomendada: Firebase Firestore + Firebase Auth (Google + anónimo)**

**Razones:**
1. El proyecto ya tiene Firebase configurado.
2. Firestore escala sin servidores dedicados.
3. Google Auth reduce trolls sin crear barrera.
4. Integración nativa con Flutter.
5. Plan Spark (gratuito) cubre 50K lecturas/día para un medio regional.

**Arquitectura sugerida:**
```
Firebase Firestore
  └── comments/
       ├── {postId}/
       │    ├── {commentId}/
       │    │    ├── userId: string
       │    │    ├── text: string
       │    │    ├── createdAt: timestamp
       │    │    ├── status: "pending" | "approved" | "rejected"
       │    │    └── parentId: string? (para replies)
       │    └── ...
       └── stats/
            └── {postId}/
                 └── commentCount: number
```

**No recomendado**:
- WordPress nativo (WebView = mala UX).
- Anónimo sin moderación (riesgo legal alto para medio de comunicación).

---

## 9. ROADMAP 12 MESES

### Meses 1-3: Mejoras Críticas

| # | Mejora | Impacto | Dificultad | Costo | Tiempo | Notas |
|---|--------|---------|-----------|-------|--------|-------|
| 1 | **Refactorizar a Clean Architecture**: Separar `data/domain/presentation`, mover archivos de raíz, crear repositorios | 🔴 Crítico | Media | $0 | 3-4 sem | Desbloquea todo lo demás |
| 2 | **Inyección de dependencias** (GetIt o Riverpod) | 🔴 Crítico | Baja | $0 | 1 sem | Eliminar singletons manuales |
| 3 | **State Management**: Migrar noticias a Bloc/Cubit con caché | 🔴 Crítico | Media | $0 | 2-3 sem | Eliminar FutureBuilder |
| 4 | **Caché local** (Hive o Isar) para noticias | 🔴 Crítico | Media | $0 | 2-3 sem | Soporte offline básico |
| 5 | **Scroll vertical de noticias** + paginación | 🔴 Crítico | Baja | $0 | 1-2 sem | UX priority #1 |
| 6 | **Skeleton/Shimmer loading** | 🔴 Crítico | Baja | $0 | 1 sem | UX inmediata |
| 7 | **Proxy server para API keys** (Cloudflare Worker o Firebase Functions) | 🔴 Crítico | Alta | ~$5/mes | 3-4 sem | Seguridad |

### Meses 4-8: Mejoras Recomendadas

| # | Mejora | Impacto | Dificultad | Costo | Tiempo |
|---|--------|---------|-----------|-------|--------|
| 8 | **Paginación infinita** (scroll infinito con carga diferida) | 🟡 Alto | Media | $0 | 1-2 sem |
| 9 | **Favoritos** (local con Hive) | 🟡 Alto | Baja | $0 | 1 sem |
| 10 | **Buscador de noticias** | 🟡 Alto | Media | $0 | 2-3 sem |
| 11 | **Sistema de comentarios** (Firebase + Google Auth) | 🟡 Alto | Alta | $0-20/mes | 4-6 sem |
| 12 | **Notificaciones segmentadas** (tópicos FCM por categoría) | 🟡 Alto | Media | $0 | 2-3 sem |
| 13 | **Modo Offline completo** (caché + sincronización) | 🟡 Alto | Alta | $0 | 4-6 sem |
| 14 | **Reducir polling AzuraCast** (WebSocket en vez de HTTP cada 15s) | 🟡 Medio | Baja | $0 | 1 sem |
| 15 | **Google AdMob** (banners + intersticiales) | 🟡 Alto | Baja | $0 | 2 sem |
| 16 | **Pantalla de Podcasts** (desde RSS de WordPress) | 🟡 Medio | Media | $0 | 2-3 sem |
| 17 | **Widget wrapper** para CachedNetworkImage (DRY) | 🟡 Medio | Baja | $0 | 2 días |
| 18 | **Widget genérico AsyncWidgetBuilder** | 🟡 Medio | Baja | $0 | 2 días |
| 19 | **Testing**: Unit tests + widget tests | 🟡 Medio | Media | $0 | Continuo |
| 20 | **CI/CD** (GitHub Actions + CodeMagic o similar) | 🟡 Medio | Media | $0-30/mes | 2-3 sem |

### Meses 9-12: Mejoras Opcionales

| # | Mejora | Impacto | Dificultad | Costo | Tiempo |
|---|--------|---------|-----------|-------|--------|
| 21 | **Sistema de usuarios completo** (perfil, ajustes, avatar) | 🟢 Medio | Alta | $0-100/mes | 6-8 sem |
| 22 | **Reacciones en noticias** (me gusta, me importa, etc.) | 🟢 Bajo | Baja | $0 | 1 sem |
| 23 | **Reportes ciudadanos** (foto + ubicación + descripción) | 🟢 Medio | Alta | ~$50/mes | 6-8 sem |
| 24 | **Videos Reels/Shorts** (feed vertical tipo TikTok) | 🟢 Medio | Alta | $0 | 4-6 sem |
| 25 | **Gamificación** (puntos por leer, compartir, comentar) | 🟢 Bajo | Media | $0-50/mes | 4-6 sem |
| 26 | **Integración membership** (Stripe/PayPal para suscripciones) | 🟢 Alto | Alta | ~$50/mes | 6-8 sem |
| 27 | **Dark mode refinado** (temas personalizados, colores ajustables) | 🟢 Bajo | Baja | $0 | 1 sem |
| 28 | **Soporte para tablets** (layout adaptativo, Master-Detail) | 🟢 Medio | Media | $0 | 3-4 sem |
| 29 | **Analytics** (Firebase Analytics o Mixpanel) | 🟢 Medio | Baja | $0 | 1 sem |
| 30 | **Deep Linking** (GoRouter, links compartibles) | 🟢 Medio | Media | $0 | 2-3 sem |

---

## 10. RESUMEN EJECUTIVO

### Lo que funciona bien ✅
- Radio en vivo con reproducción en segundo plano (audio_service + just_audio)
- Notificaciones push con Firebase Cloud Messaging
- Tema claro/oscuro automático (ThemeMode.system)
- Integración con YouTube API
- Integración con WordPress REST API
- Reproducción de emisiones guardadas (programación diferida)

### Lo que debe arreglarse URGENTE 🔴
1. **Arquitectura**: Migrar a Clean Architecture con separación de capas.
2. **UX**: Scroll vertical de noticias (reemplazar horizontal).
3. **Caché/Offline**: Implementar persistencia local (Hive/Isar).
4. **Seguridad**: Proteger API Keys con proxy server.
5. **State Management**: Reemplazar FutureBuilder por Bloc/Cubit.

### Lo que aportará más valor 🟡
1. Comentarios (Firebase Firestore + Google Auth).
2. Favoritos e historial de lectura.
3. Notificaciones segmentadas por categoría.
4. Monetización (AdMob inicialmente, membresías después).
5. Testing y CI/CD.

---

*Documento generado automáticamente como parte de la auditoría técnica de Junio 2026.*
*Para más detalle sobre algún punto, revisar el código fuente en las rutas indicadas.*
