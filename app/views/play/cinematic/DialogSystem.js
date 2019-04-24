import anime from 'animejs/lib/anime.es.js'
import { Noop, AnimeCommand, SyncFunction } from './Command/AbstractCommand'
import { getText, getClearText, getTextPosition, getSpeaker } from '../../../schemas/selectors/cinematic'

// Polyfill for node.remove method.
// Reference: https://developer.mozilla.org/en-US/docs/Web/API/ChildNode/remove
// from:https://github.com/jserz/js_piece/blob/master/DOM/ChildNode/remove()/remove().md
(function (arr) {
  arr.forEach(function (item) {
    if (item.hasOwnProperty('remove')) {
      return
    }
    Object.defineProperty(item, 'remove', {
      configurable: true,
      enumerable: true,
      writable: true,
      value: function remove () {
        this.parentNode.removeChild(this)
      }
    })
  })
})([Element.prototype, CharacterData.prototype, DocumentType.prototype])

const SVGNS = 'http://www.w3.org/2000/svg'
const padding = 10

/**
 * This system coordinates drawing HTML and SVG to the screen.
 *
 * It's also responsible for disposing of used elements and
 * playing/ending the various animations of the text.
 */
export default class DialogSystem {
  constructor ({ canvasDiv, camera }) {
    const div = this.div = document.createElement('div')
    const width = camera.canvasWidth
    const height = camera.canvasHeight
    div.style.width = `${width}px`
    div.style.height = `${height}px`

    const svg = this.svg = document.createElementNS(SVGNS, 'svg')
    svg.setAttribute('xmlns', SVGNS)
    svg.setAttribute('height', `${height}`)
    svg.setAttribute('width', `${width}`)

    svg.style.pointerEvents = div.style.pointerEvents = 'none'
    svg.style.position = div.style.postition = 'absolute'

    canvasDiv.appendChild(svg)
    canvasDiv.appendChild(div)

    this.dialogBubbles = []
  }

  parseDialogNode (dialogNode) {
    const commands = []
    const text = getText(dialogNode)
    const shouldClear = getClearText(dialogNode)
    const { x, y } = getTextPosition(dialogNode) || { x: 200, y: 200 }
    const side = getSpeaker(dialogNode) || 'left'

    if (shouldClear) {
      commands.push(this.clearDialogBubbles())
    }

    if (text) {
      commands.push(this.createBubble({
        htmlString: `<div>${text}</div>`,
        x,
        y,
        side
      }))
    }
    return commands
  }

  clearDialogBubbles () {
    return new SyncFunction(() => {
      this.dialogBubbles.forEach(
        // Not supported on Internet explorer
        el => el.remove()
      )
    })
  }

  createBubble ({
    htmlString,
    x,
    y,
    side
  }) {
    return (new SpeechBubble({
      div: this.div,
      svg: this.svg,
      htmlString: wrapText(htmlString),
      x,
      y,
      side,
      dialogBubbles: this.dialogBubbles
    })).createBubbleCommand()
  }
}

let _id = 0
class SpeechBubble {
  constructor ({
    div,
    svg,
    htmlString,
    x,
    y,
    dialogBubbles,
    side
  }) {
    this.id = `speech-${_id++}`
    this.svg = svg
    const parser = new DOMParser()
    const html = parser.parseFromString(htmlString, 'text/html')
    const textDiv = html.body.firstChild
    textDiv.style.display = 'inline-block'
    textDiv.style.left = `${x}`
    textDiv.style.top = `${y}`
    textDiv.style.position = 'absolute'
    textDiv.id = this.id

    div.appendChild(textDiv)
    const bbox = textDiv.getBoundingClientRect()
    const width = bbox.right - bbox.left
    const height = bbox.bottom - bbox.top

    const svgGroup = this.createSvgShape({
      x,
      y: y - height,
      width,
      height,
      id: this.id,
      side
    })

    this.animation = anime
      .timeline({
        autoplay: false
      })
      .add({
        targets: `svg g.${this.id}`,
        opacity: 1,
        duration: 100,
        easing: 'easeInOutQuart'
      })
      .add({
        targets: `svg g.${this.id} rect`,
        height: [height + 2 * padding],
        duration: 300,
        easing: 'easeInOutQuart'
      })
      .add({
        targets: `#${this.id} .letter`,
        opacity: 1,
        duration: 750,
        delay: anime.stagger(50, { easing: 'linear' }),
        easing: 'easeOutQuad',
        complete: () => {
          dialogBubbles.push(svgGroup)
          dialogBubbles.push(textDiv)
        }
      })
  }

  createBubbleCommand () {
    return new AnimeCommand(this.animation)
  }

  createSvgShape ({ x, y, width, height, side, id }) {
    const g = document.createElementNS(SVGNS, 'g')
    g.setAttribute('transform', `translate(${x - padding}, ${y + height + 1 - padding})`)
    g.setAttribute('fill', 'white')
    g.setAttribute('opacity', '0')
    g.setAttribute('class', id)

    const rect = document.createElementNS(SVGNS, 'rect')
    rect.setAttribute('width', `${width + 2 * padding}`)
    // Set by an animation.
    rect.setAttribute('height', `${0}`)

    const path = document.createElementNS(SVGNS, 'path')
    path.setAttribute('d', 'M -20 20 l 21 -10 0 20 z')
    if (side === 'right') {
      path.setAttribute('transform', `translate(${width + 2 * padding},0) scale(-1, 1)`)
    }
    g.appendChild(rect)
    g.appendChild(path)
    this.svg.appendChild(g)
    return g
  }
}

/**
 * From the stackoverflow answer: https://stackoverflow.com/a/20693791/6421793
 */
function wrapText (htmlString) {
  // better to abstract the process and create a generic method "replaceHtmlContent"
  // which could be used in multiple contexts
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
    return replaceHtmlContent(src, match, function (str) {
      return (
        '<span class="letter" style="display: inline-block; opacity:0">' +
        str +
        '</span>'
      )
    })
  }

  // and create another method specific to our use case
  function wrapWord (src, match) {
    return replaceHtmlContent(src, match, function (str) {
      let result = ''
      if (str[0] === ' ') {
        result += ' '
      }
      result += wrapLetter(
        '<span class="word" style="display: inline-block; whites-space: nowrap">' +
          str +
          '</span>',
        /[^ ]/
      )
      if (str.substr(-1) === ' ') {
        result += ' '
      }
      return result
    })
  }

  // so later we can use it like this
  return wrapWord(htmlString, / ?([^ ])+ ?/)
}
