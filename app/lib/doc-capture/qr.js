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
 * The compact form printed on a worksheet.
 *
 * Written entirely in uppercase on purpose. QR has an alphanumeric mode that
 * packs digits, uppercase letters and a handful of symbols (including `:` `/`
 * and `.`) at 11 bits per two characters instead of 8 bits per character.
 * Lowercase letters need a byte-mode segment. Scheme and host are case-
 * insensitive, and our route is too, so uppercase keeps the payload smaller. The server supplies
 * a collision-checked 12-character fingerprint of the whole scenario ID. A
 * full ID is the fallback when the compact code is unavailable.
 *
 * @param {string} origin e.g. https://codecombat.com
 * @param {string} scenarioId 24-character hex ObjectId
 * @param {string|null} userId 24-character hex ObjectId, when the sheet is for
 *   a particular child
 * @param {string|null} compactCode server-issued worksheet code
 */
export function worksheetQRText (origin, scenarioId, userId, compactCode) {
  const scenario = /^[a-f0-9]{12}$/i.test(compactCode || '') ? compactCode : String(scenarioId || '')
  const token = `${scenario}${userId || ''}`
  return `${origin}/s/${token}`.toUpperCase()
}

/**
 * Pull the scenario and student out of a worksheet QR code.
 *
 * Three forms are accepted. The short one is what worksheets print now; the
 * other two keep sheets printed earlier working:
 *   /s/<12-character fingerprint or full scenarioId>[<userId>]
 *     (legacy six-character prefixes still accepted)
 *   /ai-junior/scan/<scenarioHandle>[/<userId>]
 *   /ai-junior/project/<scenarioHandle>[/<userId>[/<projectId>]]
 *
 * @returns {{scenarioHandle: string, userId: string|null, isPrefix: boolean, isFingerprint?: boolean}|null}
 *   `isPrefix` marks a scenario identified by the leading characters of its id
 *   rather than by a slug or a whole id. `isFingerprint` needs server resolution.
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

  const short = /^\/s\/([0-9a-f]{24}|[0-9a-f]{12}|[0-9a-f]{6})([0-9a-f]{24})?$/i.exec(path)
  if (short) {
    return {
      scenarioHandle: short[1].toLowerCase(),
      userId: short[2] ? short[2].toLowerCase() : null,
      isPrefix: short[1].length === 6,
      ...(short[1].length === 12 ? { isFingerprint: true } : {}),
    }
  }

  const match = /^\/ai-junior\/(?:scan|project)\/([^/]+)(?:\/([^/]+))?(?:\/[a-f0-9]{24})?\/?$/i.exec(path)
  if (!match) return null
  let scenarioHandle, userId
  try {
    scenarioHandle = decodeURIComponent(match[1])
    userId = match[2] ? decodeURIComponent(match[2]) : null
  } catch (err) {
    return null
  }
  if (!scenarioHandle) return null
  return {
    scenarioHandle,
    userId: /^[a-f0-9]{24}$/i.test(userId || '') ? userId : null,
    isPrefix: false,
  }
}
