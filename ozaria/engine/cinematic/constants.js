/**
 * Max size assumptions for the cinematic system.
 *
 * We place the speech bubbles using pixels assuming the max width of
 * 1366 by 768. Then we can use this assumption to change the pixel
 * placement into percentages for smaller screen sizes.
 */

const WIDTH = 1366
const HEIGHT = 768

const CINEMATIC_ASPECT_RATIO = HEIGHT / WIDTH
const LETTER_ANIMATE_TIME = 45

const LEFT_SPEAKER_CAMERA_POS = { x: -165, y: -65 }
const RIGHT_SPEAKER_CAMERA_POS = { x: 165, y: -65 }

// The default hero if the user has malformed state or missing hero.
// Useful if an admin is testing without selecting a hero in advance.
const HERO_THANG_ID = '5d03e18887ed53004682e340'

const AVATAR_THANG_ID = '5d48b61ae92cc00030a9b2db'
const PET_AVATAR_THANG_ID = '5d48bd7677c98f0029118e11'

// WARNING - Tied to cinematic schema
// Key constants for special lank types
const LEFT_LANK_KEY = 'left'
const RIGHT_LANK_KEY = 'right'
const HERO_PET = 'HERO_PET'
const BACKGROUND_OBJECT = 'BACKGROUND_OBJECT'
const BACKGROUND = 'BACKGROUND'

const QUILL_CONFIG = {
  paragraphTag: 'div',
  customTagAttributes: (op) => {
    if (op.attributes.align) {
      // Replace Quill align attribute with CSS text-align style attribute
      return { 'style': `text-align: ${op.attributes.align};` }
    } else if (op.attributes.size) {
      switch (op.attributes.size) {
        case 'small':
          return { 'style': `font-size: 18px;` }
        case 'large':
          return { 'style': `font-size: 28px;` }
        case 'huge':
          return { 'style': `font-size: 32px;` }
      }
    } else if (op.attributes.font) {
      return { 'style': `font-family: ${op.attributes.font};` }
    }
  }
}

// The server imports from this file via cinematic schema and cannot use any modern syntax.
module.exports = {
  WIDTH,
  HEIGHT,
  CINEMATIC_ASPECT_RATIO,
  LETTER_ANIMATE_TIME,
  LEFT_SPEAKER_CAMERA_POS,
  RIGHT_SPEAKER_CAMERA_POS,
  HERO_THANG_ID,
  AVATAR_THANG_ID,
  PET_AVATAR_THANG_ID,
  LEFT_LANK_KEY,
  RIGHT_LANK_KEY,
  HERO_PET,
  BACKGROUND_OBJECT,
  BACKGROUND,
  QUILL_CONFIG
}
