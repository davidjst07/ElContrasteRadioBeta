const {onRequest} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const logger = require("firebase-functions/logger");

const youtubeApiKey = defineSecret("YOUTUBE_API_KEY");

// Canal de El Contraste en YouTube — es publico (aparece en la URL del
// canal), no es un secreto, por eso va fijo en el codigo del servidor.
const CHANNEL_ID = "UC-jqog56YKjpHZESo2cTAtQ";
const MAX_RESULTS = 20;

// Cache en memoria por instancia: mientras la instancia de la funcion siga
// "tibia", evita volver a golpear la API de YouTube (y su cuota) en cada
// apertura de la app.
let cachedBody = null;
let cachedAt = 0;
const CACHE_TTL_MS = 5 * 60 * 1000;

exports.youtubeVideos = onRequest(
  {secrets: [youtubeApiKey], cors: true, maxInstances: 5},
  async (request, response) => {
    try {
      const now = Date.now();
      if (cachedBody && now - cachedAt < CACHE_TTL_MS) {
        response.status(200).json(cachedBody);
        return;
      }

      const url = new URL("https://www.googleapis.com/youtube/v3/search");
      url.searchParams.set("part", "snippet");
      url.searchParams.set("channelId", CHANNEL_ID);
      url.searchParams.set("maxResults", String(MAX_RESULTS));
      url.searchParams.set("order", "date");
      url.searchParams.set("type", "video");
      url.searchParams.set("key", youtubeApiKey.value());

      const ytResponse = await fetch(url.toString());
      const data = await ytResponse.json();

      if (!ytResponse.ok) {
        logger.error("Error de la API de YouTube", data);
        response.status(ytResponse.status).json({
          error: "No se pudo obtener los videos de YouTube",
        });
        return;
      }

      cachedBody = data;
      cachedAt = now;

      response.status(200).json(data);
    } catch (error) {
      logger.error("Error inesperado en youtubeVideos", error);
      response.status(500).json({error: "Error interno del servidor"});
    }
  },
);
