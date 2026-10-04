import { modifier } from "ember-modifier";

const SAMPLE_SIZE = 16;
const cache = new Map();

// Average the corner pixels to see whether a logo sits on a solid dark or light
// box. Uses its own crossOrigin image so a CDN without CORS can't break the
// visible <img>; any failure just leaves the logo unclassified.
function classify(url) {
  if (!cache.has(url)) {
    cache.set(
      url,
      new Promise((resolve) => {
        const image = new Image();
        image.crossOrigin = "anonymous";
        image.onerror = () => resolve(null);
        image.onload = () => {
          try {
            const canvas = document.createElement("canvas");
            canvas.width = canvas.height = SAMPLE_SIZE;
            const context = canvas.getContext("2d", { willReadFrequently: true });
            context.drawImage(image, 0, 0, SAMPLE_SIZE, SAMPLE_SIZE);
            const edge = SAMPLE_SIZE - 1;
            const corners = [
              [0, 0],
              [edge, 0],
              [0, edge],
              [edge, edge],
            ].map(([x, y]) => context.getImageData(x, y, 1, 1).data);
            if (corners.some(([, , , alpha]) => alpha < 200)) {
              return resolve(null);
            }
            const luminance =
              corners.reduce(
                (sum, [r, g, b]) => sum + 0.2126 * r + 0.7152 * g + 0.0722 * b,
                0
              ) /
              (corners.length * 255);
            resolve(luminance < 0.35 ? "dark" : luminance > 0.75 ? "light" : null);
          } catch {
            resolve(null);
          }
        };
        image.src = url;
      })
    );
  }
  return cache.get(url);
}

export const logoBackdrop = modifier((element) => {
  let cancelled = false;
  classify(element.currentSrc || element.src).then((backdrop) => {
    if (!cancelled && backdrop) {
      element.dataset.backdrop = backdrop;
    }
  });
  return () => (cancelled = true);
});
