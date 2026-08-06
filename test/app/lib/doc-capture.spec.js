/**
 * Pure-logic tests for the worksheet capture pipeline. Everything exercised
 * here is plain maths over pixel buffers, so it runs without a camera, a
 * canvas or a network.
 */
const { parseWorksheetQR } = require('lib/doc-capture/qr')
const { isSkin, removeHands, flattenPage, cleanPage } = require('lib/doc-capture/cleanup')
const { orderQuad } = require('lib/doc-capture/geom')

/** An RGBA buffer of a given flat colour. */
function blank (width, height, [r, g, b]) {
  const data = new Uint8ClampedArray(width * height * 4)
  for (let i = 0; i < data.length; i += 4) {
    data[i] = r
    data[i + 1] = g
    data[i + 2] = b
    data[i + 3] = 255
  }
  return { width, height, data }
}

function fillRect (img, x0, y0, w, h, [r, g, b]) {
  for (let y = y0; y < y0 + h; y++) {
    for (let x = x0; x < x0 + w; x++) {
      if (x < 0 || y < 0 || x >= img.width || y >= img.height) continue
      const i = (y * img.width + x) * 4
      img.data[i] = r
      img.data[i + 1] = g
      img.data[i + 2] = b
      img.data[i + 3] = 255
    }
  }
}

function pixel (img, x, y) {
  const i = (y * img.width + x) * 4
  return [img.data[i], img.data[i + 1], img.data[i + 2]]
}

const PAPER = [253, 251, 245]
const SKIN = [216, 160, 116]
const INK = [30, 40, 160]

describe('parseWorksheetQR', () => {
  it('reads the scenario and student out of a scan URL', () => {
    const parsed = parseWorksheetQR('https://codecombat.com/ai-junior/scan/make-a-game/512ef4805a67a8c507000001')
    expect(parsed.scenarioHandle).toBe('make-a-game')
    expect(parsed.userId).toBe('512ef4805a67a8c507000001')
  })

  it('still reads sheets printed before the QR target changed', () => {
    const parsed = parseWorksheetQR('https://codecombat.com/ai-junior/project/design-a-character/512ef4805a67a8c507000001')
    expect(parsed.scenarioHandle).toBe('design-a-character')
    expect(parsed.userId).toBe('512ef4805a67a8c507000001')
  })

  it('accepts a scenario with no student', () => {
    const parsed = parseWorksheetQR('https://codecombat.com/ai-junior/scan/make-a-game')
    expect(parsed.scenarioHandle).toBe('make-a-game')
    expect(parsed.userId).toBe(null)
  })

  it('ignores the host, so a sheet printed on one machine scans on another', () => {
    // Worksheets are routinely printed from localhost and scanned from a phone
    // on the LAN address.
    const a = parseWorksheetQR('http://localhost:3000/ai-junior/scan/make-a-game')
    const b = parseWorksheetQR('http://192.168.0.84:3000/ai-junior/scan/make-a-game')
    expect(a.scenarioHandle).toBe('make-a-game')
    expect(b.scenarioHandle).toBe('make-a-game')
  })

  it('accepts a bare path', () => {
    expect(parseWorksheetQR('/ai-junior/scan/make-a-game').scenarioHandle).toBe('make-a-game')
  })

  it('drops a user segment that is not an id, rather than trusting it', () => {
    expect(parseWorksheetQR('/ai-junior/scan/make-a-game/not-an-id').userId).toBe(null)
  })

  it('rejects anything that is not an AI Junior worksheet', () => {
    expect(parseWorksheetQR('https://example.com/hello')).toBe(null)
    expect(parseWorksheetQR('https://codecombat.com/play')).toBe(null)
    expect(parseWorksheetQR('not a url at all')).toBe(null)
    expect(parseWorksheetQR('')).toBe(null)
    expect(parseWorksheetQR(null)).toBe(null)
    expect(parseWorksheetQR(undefined)).toBe(null)
  })
})

describe('isSkin', () => {
  it('recognises a range of skin tones', () => {
    expect(isSkin(216, 160, 116)).toBe(true)
    expect(isSkin(241, 194, 165)).toBe(true)
    expect(isSkin(160, 110, 75)).toBe(true)
  })

  it('does not classify paper, ink or foliage as skin', () => {
    expect(isSkin(253, 251, 245)).toBe(false)
    expect(isSkin(30, 40, 160)).toBe(false)
    expect(isSkin(40, 160, 60)).toBe(false)
    expect(isSkin(0, 0, 0)).toBe(false)
  })
})

describe('removeHands', () => {
  it('paints out a finger that reaches in from the edge of the page', () => {
    const page = blank(300, 200, PAPER)
    fillRect(page, 0, 120, 70, 60, SKIN) // a thumb intruding from the left
    const { image, removed } = removeHands(page)

    expect(removed).toBeGreaterThan(0)
    const [r, g, b] = pixel(image, 20, 150)
    expect(isSkin(r, g, b)).toBe(false)
    expect(r).toBeGreaterThan(200)
  })

  it("leaves a child's skin-toned drawing alone when it does not touch the edge", () => {
    // The whole point of the border rule: a face drawn in the middle of the
    // sheet is exactly the same colour as the thumb holding the corner.
    const page = blank(300, 200, PAPER)
    fillRect(page, 120, 70, 60, 60, SKIN)
    const { image, removed } = removeHands(page)

    expect(removed).toBe(0)
    const [r, g, b] = pixel(image, 150, 100)
    expect(isSkin(r, g, b)).toBe(true)
  })

  it('keeps the drawing even when a finger is removed from the same page', () => {
    const page = blank(300, 200, PAPER)
    fillRect(page, 0, 120, 70, 60, SKIN) // thumb at the edge
    fillRect(page, 140, 40, 50, 50, SKIN) // drawing in the middle
    const { image } = removeHands(page)

    expect(isSkin(...pixel(image, 20, 150))).toBe(false)
    expect(isSkin(...pixel(image, 165, 65))).toBe(true)
  })

  it('ignores a skin-coloured speck too small to be a hand', () => {
    const page = blank(300, 200, PAPER)
    fillRect(page, 0, 0, 3, 3, SKIN)
    expect(removeHands(page).removed).toBe(0)
  })

  it('returns the page untouched when there is no hand at all', () => {
    const page = blank(300, 200, PAPER)
    fillRect(page, 100, 100, 40, 20, INK)
    const { image, removed } = removeHands(page)
    expect(removed).toBe(0)
    expect(image).toBe(page)
  })
})

describe('flattenPage', () => {
  it('evens out a lighting gradient so the paper reads white throughout', () => {
    const page = blank(400, 200, [255, 255, 255])
    // A shadow falling across the right-hand side of the sheet.
    for (let y = 0; y < page.height; y++) {
      for (let x = 0; x < page.width; x++) {
        const shade = 255 - Math.round((x / page.width) * 130)
        const i = (y * page.width + x) * 4
        page.data[i] = shade
        page.data[i + 1] = shade
        page.data[i + 2] = shade
      }
    }
    const before = pixel(page, 380, 100)[0]
    const flat = flattenPage(page)
    const afterLeft = pixel(flat, 20, 100)[0]
    const afterRight = pixel(flat, 380, 100)[0]

    expect(before).toBeLessThan(160)
    expect(afterRight).toBeGreaterThan(230)
    expect(Math.abs(afterLeft - afterRight)).toBeLessThan(20)
  })

  it('keeps marks darker than the paper around them', () => {
    const page = blank(300, 200, [240, 240, 240])
    fillRect(page, 100, 80, 40, 40, [40, 40, 40])
    const flat = flattenPage(page)
    expect(pixel(flat, 120, 100)[0]).toBeLessThan(pixel(flat, 20, 20)[0])
  })
})

describe('cleanPage', () => {
  it('flattens and de-hands in one pass, and reports what it removed', () => {
    const page = blank(300, 200, PAPER)
    fillRect(page, 0, 120, 70, 60, SKIN)
    const { image, handsRemoved } = cleanPage(page)
    expect(handsRemoved).toBeGreaterThan(0)
    expect(image.width).toBe(300)
    expect(image.height).toBe(200)
  })

  it('can be asked to skip either pass', () => {
    const page = blank(300, 200, PAPER)
    fillRect(page, 0, 120, 70, 60, SKIN)
    expect(cleanPage(page, { removeHands: false }).handsRemoved).toBe(0)
  })
})

describe('orderQuad', () => {
  it('puts corners in a consistent order however they arrive', () => {
    const corners = [{ x: 10, y: 10 }, { x: 90, y: 12 }, { x: 88, y: 70 }, { x: 8, y: 68 }]
    for (const rotation of [0, 1, 2, 3]) {
      const rotated = corners.slice(rotation).concat(corners.slice(0, rotation))
      const ordered = orderQuad(rotated)
      expect(ordered[0].x).toBeLessThan(ordered[1].x) // top-left before top-right
      expect(ordered[0].y).toBeLessThan(ordered[3].y) // top-left above bottom-left
    }
  })
})
