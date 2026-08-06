/**
 * qr.js -- finding and interpreting the QR code printed on a worksheet.
 *
 * Decoding uses the browser's native BarcodeDetector when it exists (fast, off
 * the main thread) and falls back to jsQR everywhere else — notably iOS Safari,
 * which is the most likely device to be pointed at a piece of paper.
 */
import jsQR from 'jsqr'

let nativeDetector
let nativeChecked = false

function getNativeDetector () {
  if (!nativeChecked) {
    nativeChecked = true
    try {
      if (typeof window !== 'undefined' && window.BarcodeDetector) {
        nativeDetector = new window.BarcodeDetector({ formats: ['qr_code'] })
      }
    } catch (err) {
      nativeDetector = null
    }
  }
  return nativeDetector
}

/**
 * Read a QR code out of an ImageData buffer.
 * @returns {string|null} the encoded text
 */
export function decodeQRFromImageData (imageData) {
  if (!imageData) return null
  // `attemptBoth` also tries an inverted image, which costs a second pass but
  // catches worksheets photographed against glare.
  const result = jsQR(imageData.data, imageData.width, imageData.height, { inversionAttempts: 'attemptBoth' })
  return result?.data || null
}

/**
 * Read a QR code from anything drawable, preferring the native detector.
 * @param {CanvasImageSource} source video, image or canvas
 * @param {ImageData} [imageData] already-read pixels for the jsQR path
 */
export async function decodeQR (source, imageData) {
  const detector = getNativeDetector()
  if (detector && source) {
    try {
      const codes = await detector.detect(source)
      if (codes && codes.length) return codes[0].rawValue
    } catch (err) {
      // Some sources (a detached canvas, a paused video) throw; fall through.
    }
  }
  return decodeQRFromImageData(imageData)
}

/**
 * Pull the scenario and student out of a worksheet QR code.
 *
 * Worksheets encode a full URL. Both the scan form and the older project form
 * are accepted so that sheets printed before the QR target changed still work:
 *   /ai-junior/scan/<scenarioHandle>[/<userId>]
 *   /ai-junior/project/<scenarioHandle>[/<userId>[/<projectId>]]
 *
 * @returns {{scenarioHandle: string, userId: string|null}|null}
 */
export function parseWorksheetQR (text) {
  if (!text || typeof text !== 'string') return null
  let path = text.trim()
  try {
    // Accept a bare path as well as an absolute URL from another host: a sheet
    // printed from localhost should still scan on the phone's LAN address.
    path = new URL(path, 'http://worksheet.invalid').pathname
  } catch (err) {
    return null
  }
  const match = /^\/ai-junior\/(?:scan|project)\/([^/]+)(?:\/([^/]+))?/.exec(path)
  if (!match) return null
  const scenarioHandle = decodeURIComponent(match[1])
  const userId = match[2] ? decodeURIComponent(match[2]) : null
  if (!scenarioHandle) return null
  return { scenarioHandle, userId: /^[a-f0-9]{24}$/i.test(userId || '') ? userId : null }
}
