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
