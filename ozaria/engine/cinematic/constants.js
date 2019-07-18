/**
 * Max size assumptions for the cinematic system.
 *
 * We place the speech bubbles using pixels assuming the max width of
 * 1366 by 768. Then we can use this assumption to change the pixel
 * placement into percentages for smaller screen sizes.
 */
export const WIDTH = 1366
export const HEIGHT = 768
export const CINEMATIC_ASPECT_RATIO = HEIGHT / WIDTH

export const LETTER_ANIMATE_TIME = 90

export const LEFT_SPEAKER_CAMERA_POS = { x: -165, y: -65 }
export const RIGHT_SPEAKER_CAMERA_POS = { x: 165, y: -65 }

// The default hero if the user has malformed state or missing hero.
// Useful if an admin is testing without selecting a hero in advance.
export const HERO_THANG_ID = '5d03e18887ed53004682e340'
