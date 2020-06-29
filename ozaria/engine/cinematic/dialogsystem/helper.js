import utils from 'app/core/utils'
import tmpl from 'tmpl'

/**
 * Extract the text from the DialogNode, and transform it into an html element ready for animation.
 *
 * This function handles internationalization, text interpolation and html processing.
 *
 * We use very light weight [Javascript-Templates](https://blueimp.github.io/JavaScript-Templates/)
 * in order to provide text templating.
 *
 * @param {DialogNode} dialogNode
 * @param {Object} context - The object referred to as `o` in the text templates.
 * @param {bool} wrap - Whether we want to wrap the transpiled text in html tags.
 * @returns {HTMLElement|undefined} The processed element.
 */
export function processText (dialogNode, context, wrap = true) {
  let text = utils.i18n(dialogNode, 'text')
  text = tmpl(text || '', context)
  if (!text) {
    return undefined
  }

  if (wrap) {
    return wrapText(`<div>${text}</div>`)
  }
  return text
}

/**
 * From the stackoverflow answer: https://stackoverflow.com/a/20693791/6421793
 *
 * Default behaviour:
 *
 * Wraps each letter with a span set at opacity 0.
 * This lets us calculate the bounding box of the html element.
 * To prevent the possible occurrance of line breaks in the middle of a word
 * we must also wrap words with a span tag.
 *
 * @param {string} htmlString is a raw string representation of html
 * @param {function} wrapLetterString takes a letter and can return a wrapped letter.
 * @param {function} wrapWordString takes a word and can return a wrapped word.
 * @returns {string} transformed html string.
 */
export function wrapText (htmlString, wrapLetterString, wrapWordString) {
  if (!wrapLetterString) {
    wrapLetterString = l => `<span class="letter" style="display: inline-block; opacity:0">${l}</span>`
  }
  if (!wrapWordString) {
    wrapWordString = l => `<span class="word" style="display: inline-block; whites-space: nowrap">${l}</span>`
  }

  // Method that replaces text content within an html string.
  function replaceHtmlContent (str, match, replaceFn) {
    // we use the "g" and "i" flags to make it replace all occurrences and ignore case
    var re = new RegExp(match, 'gi')
    // this RegExp will match any char sequence that doesn't contain "<" or ">"
    // and that is followed by a tag
    return str.replace(/([^<>]+)(?=<[^>]+>)/g, function (s, content) {
      return content.replace(re, replaceFn)
    })
  }

  function wrapLetter (src, match) {
    return replaceHtmlContent(src, match, wrapLetterString)
  }

  // wrapWord maintains spaces on either side of the word.
  function wrapWord (src, match) {
    return replaceHtmlContent(src, match, function (str) {
      let result = ''
      if (str[0] === ' ') {
        result += ' '
      }
      result += wrapLetter(wrapWordString(str.trim()), /[^ ]/)
      if (str.substr(-1) === ' ') {
        result += ' '
      }
      return result
    })
  }

  return wrapWord(htmlString, / ?([^ ])+ ?/)
}

/**
 * Try to guess the frame of the camera and provide sensible defaults for the
 * text bubbles. Uses values sourced from Brian.
 *
 * If value can't be guessed, sets the text bubble in the center of the canvas.
 *
 * @param {'left'|'right'} speaker
 * @param {number} cameraZoom
 */
export function getDefaultTextPosition (speaker, cameraZoom) {
  // Handling special cases of zoom, checking if speaker is in frame.
  if (speaker === 'left') {
    if (cameraZoom === 1) {
      return { x: 540, y: 280 }
    } else if (cameraZoom === 2) {
      return { x: 800, y: 250 }
    }
  } else if (speaker === 'right') {
    if (cameraZoom === 1) {
      return { x: 875, y: 280 }
    } else if (cameraZoom === 2) {
      return { x: 600, y: 300 }
    }
  }
  // Default to center
  return { x: 1366 / 2, y: 768 / 2 }
}
