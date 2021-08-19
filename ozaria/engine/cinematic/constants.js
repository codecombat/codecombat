/**
 * Max size assumptions for the cinematic system.
 *
 * We place the speech bubbles using pixels assuming the max width of
 * 1366 by 768. Then we can use this assumption to change the pixel
 * placement into percentages for smaller screen sizes.
 */

const ThangTypeConstants = require('lib/ThangTypeConstants')

const WIDTH = 1366
const HEIGHT = 768

const CINEMATIC_ASPECT_RATIO = HEIGHT / WIDTH
const LETTER_ANIMATE_TIME = 45

const LEFT_SPEAKER_CAMERA_POS = { x: -165, y: -65 }
const RIGHT_SPEAKER_CAMERA_POS = { x: 165, y: -65 }

// The default hero if the user has malformed state or missing hero.
// Useful if an admin is testing without selecting a hero in advance.
const HERO_THANG_ID = ThangTypeConstants.ozariaCinematicHeroes['hero-a']

const AVATAR_THANG_ID = '5d48b61ae92cc00030a9b2db'
const PET_AVATAR_THANG_ID = '5d48bd7677c98f0029118e11'

// WARNING - Tied to cinematic schema
// Key constants for special lank types
const LEFT_LANK_KEY = 'left'
const RIGHT_LANK_KEY = 'right'
const HERO_PET = 'HERO_PET'
const BACKGROUND_OBJECT = 'BACKGROUND_OBJECT'
const BACKGROUND = 'BACKGROUND'

const VOICE_OVER_VOLUME = 0.9
const BACKGROUND_VOLUME = 0.15

const QUILL_CONFIG = {
  paragraphTag: 'div',
  // https://github.com/nozer/quill-delta-to-html/tree/68715d1948cf2eb4f5d6a41ec2e1181849ebaadd#rendering-inline-styles
  // Map from custom stuff in the `new Quill` configuration to styles that work for us
  // So far we only change font sizes, but we can change the following:
  // indent
  // align
  // direction
  // font
  // size
  inlineStyles: {
    size: {
      small: 'font-size: 0.8em',
      large: 'font-size: 1.1em',
      huge: 'font-size: 1.5em'
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
  QUILL_CONFIG,
  VOICE_OVER_VOLUME,
  BACKGROUND_VOLUME
}
