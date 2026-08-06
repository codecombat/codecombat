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

// How many leading hex characters of the scenario id go in a short code. There
// are single-digit numbers of scenarios, so this is unambiguous with enormous
// margin, and every character saved makes the printed modules bigger.
export const SCENARIO_PREFIX_LENGTH = 6

/**
 * The compact form printed on a worksheet.
 *
 * Written entirely in uppercase on purpose. QR has an alphanumeric mode that
 * packs digits, uppercase letters and a handful of symbols (including `:` `/`
 * and `.`) at 11 bits per two characters instead of 8 bits per character, and a
 * single lowercase letter anywhere in the payload forces the whole thing into
 * byte mode. Uppercasing the URL costs nothing — scheme and host are
 * case-insensitive, and the route matching the path is too — and it takes this
 * payload from 33 modules to 29.
 *
 * @param {string} origin e.g. https://codecombat.com
 * @param {string} scenarioId 24-character hex ObjectId
 * @param {string|null} userId 24-character hex ObjectId, when the sheet is for
 *   a particular child
 */
export function worksheetQRText (origin, scenarioId, userId) {
  const scenario = String(scenarioId || '').slice(0, SCENARIO_PREFIX_LENGTH)
  const token = `${scenario}${userId || ''}`
  return `${origin}/s/${token}`.toUpperCase()
}

/**
 * Pull the scenario and student out of a worksheet QR code.
 *
 * Three forms are accepted. The short one is what worksheets print now; the
 * other two keep sheets printed earlier working:
 *   /s/<scenarioIdPrefix>[<userId>]
 *   /ai-junior/scan/<scenarioHandle>[/<userId>]
 *   /ai-junior/project/<scenarioHandle>[/<userId>[/<projectId>]]
 *
 * @returns {{scenarioHandle: string, userId: string|null, isPrefix: boolean}|null}
 *   `isPrefix` marks a scenario identified by the leading characters of its id
 *   rather than by a slug or a whole id, so the caller knows to resolve it.
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

  const short = /^\/s\/([0-9a-f]{6})([0-9a-f]{24})?$/i.exec(path)
  if (short) {
    return {
      scenarioHandle: short[1].toLowerCase(),
      userId: short[2] ? short[2].toLowerCase() : null,
      isPrefix: true,
    }
  }

  const match = /^\/ai-junior\/(?:scan|project)\/([^/]+)(?:\/([^/]+))?/.exec(path)
  if (!match) return null
  const scenarioHandle = decodeURIComponent(match[1])
  const userId = match[2] ? decodeURIComponent(match[2]) : null
  if (!scenarioHandle) return null
  return {
    scenarioHandle,
    userId: /^[a-f0-9]{24}$/i.test(userId || '') ? userId : null,
    isPrefix: false,
  }
}
