/**
 * Color values named by appearance (not by UI function).
 * Use functional names only at the call site, e.g. lockedColor = colors.grey
 */
/** '#7B1FA2' (or '7B1FA2', '#abc') → [123, 31, 162] */
const hexToRgb = hex => {
  hex = hex.replace(/^#/, '')
  if (hex.length === 3) hex = hex.split('').map(c => c + c).join('')
  return [0, 2, 4].map(i => parseInt(hex.slice(i, i + 2), 16))
}

/** [123, 31, 162] → '#7b1fa2' */
const rgbToHex = rgb => '#' + rgb.map(c => Math.round(c).toString(16).padStart(2, '0')).join('')

module.exports = {
  black: '#000000',
  grey: '#d9d9d9',
  lightGold: '#e6c200',
  red: '#ff0000',
  tan: '#AF9F7D',
  gold: '#EBD689',
  yellow: '#FFD702',

  jayBlue: '#5082C8',
  lightBlue: '#ADD8E6',
  infernoRed: '#ff503c',
  sparkySilver: '#c1c1c1',
  seaGreen: '#2d9151',
  lightGreen: '#90EE90',
  darkGreen: '#006400',
  mysticViolet: '#AD62F8',

  green: '#00ff00',
  blue: '#0000ff',
  leafGreen: '#4FCA52',
  skyBlue: '#45AAFF',
  lavender: '#D8B4FE',
  deepPurple: '#7B1FA2',

  hexToRgb,
  rgbToHex,
}
