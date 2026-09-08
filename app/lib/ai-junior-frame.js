// This code runs inside an opaque-origin sandbox. Only dimensions and a
// fullscreen flag cross the boundary; neither side evaluates received code.
export const FRAME_BRIDGE = `(() => {
  const report = () => parent.postMessage({ type: 'ai-junior:size', height: document.body.scrollHeight }, '*');
  addEventListener('message', event => {
    if (event.source !== parent || event.data?.type !== 'ai-junior:fullscreen') return;
    if (typeof event.data.enabled !== 'boolean') return;
    document.body.classList.toggle('aij-fullscreen', event.data.enabled);
    if (!event.data.enabled) requestAnimationFrame(report);
  });
  addEventListener('load', report);
  if (typeof ResizeObserver !== 'undefined') new ResizeObserver(report).observe(document.body);
  report();
})();`

export function previewHeight (event, frame, viewportHeight) {
  if (!frame || event.source !== frame.contentWindow || event.data?.type !== 'ai-junior:size') return null
  const height = event.data.height
  if (typeof height !== 'number' || !Number.isFinite(height) || height < 0) return null
  return Math.min(Math.max(height + 24, 240), Math.round(viewportHeight * 0.85))
}
