// This code runs inside an opaque-origin sandbox. Only dimensions and a
// fullscreen flag cross the boundary; neither side evaluates received code.
export const FRAME_BRIDGE = `(() => {
  let pending = false;
  let lastHeight;
  const report = () => {
    if (pending) return;
    pending = true;
    setTimeout(() => {
      pending = false;
      const height = document.body.scrollHeight;
      if (height === lastHeight) return;
      lastHeight = height;
      parent.postMessage({ type: 'ai-junior:size', height }, '*');
    }, 100);
  };
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

/**
 * Validate a size report from this preview and bound its requested height.
 * @param {MessageEvent} event The untrusted cross-frame message.
 * @param {HTMLIFrameElement} frame The currently rendered preview iframe.
 * @param {number} viewportHeight The parent's available viewport height.
 * @returns {number|null} A bounded pixel height, or null for an invalid report.
 */
export function previewHeight (event, frame, viewportHeight) {
  if (!frame || event.source !== frame.contentWindow || event.data?.type !== 'ai-junior:size') return null
  const height = event.data.height
  if (typeof height !== 'number' || !Number.isFinite(height) || height < 0) return null
  return Math.min(Math.max(height + 24, 240), Math.round(viewportHeight * 0.85))
}
