/**
 * This is an internal script that can be used in the thangEditor to normalize
 * all the Adobe Animate colors in the shapes to hex values that can be customized.
 */
import _ from 'lodash'

const colorBuckets = {
  hairLight: '#752744',
  hairMid: '#431D32',
  hairDark: '#330A1D',
  skinLight: '#DA6D46',
  skinMid: '#703E31',
  skinDark: '#58322A',
  skinAccent: '#3A1E15'
}

const rgbaRegex = /rgba\((.*?),(.*?),(.*?),(.*?)\)/g

function hexToRgb (hex) {
  const extractHex = (start, end) => parseInt(hex.slice(start, end), 16)
  return [extractHex(1, 3), extractHex(3, 5), extractHex(5, 7)]
}

// Used to check if two colors are similar.
const isSimilar = (a, b) => Math.abs(a - b) <= 3

/**
 * Replaces rgba values with the bucketed hex value.
* Tries to detect if the value is similar to one of the bucket values.
 * If so, will round into a bucket value.
 * @param s text contents of the file
 */
function replaceRgbaWithHex (s) {
  return s.replace(rgbaRegex, (matchedString, r, g, b, _a) => {
    const r1 = parseInt(r, 10)
    const g1 = parseInt(g, 10)
    const b1 = parseInt(b, 10)
    for (const hexColor of Object.values(colorBuckets)) {
      const [r2, g2, b2] = hexToRgb(hexColor)
      if ([[r1, r2], [g1, g2], [b1, b2]].every(([v1, v2]) => isSimilar(v1, v2))) {
        console.log(`replacing ${matchedString} with normalized value: ${hexColor}`)
        return `${hexColor}`
      }
    }
    return matchedString
  })
}

// Returns a new shapesObject with colors replaced.
export default function replaceRgbaWithCustomizableHex (shapesObject) {
  console.group('Logs for replaceRgbaWithCustomizableHex execution')
  const result = {}
  for (const shapeKey of Object.keys(shapesObject)) {
    const shape = _.cloneDeep(shapesObject[shapeKey])
    if (shape.fc) {
      shape.fc = replaceRgbaWithHex(shape.fc)
    }
    result[shapeKey] = shape
  }
  console.groupEnd()
  return result
}
