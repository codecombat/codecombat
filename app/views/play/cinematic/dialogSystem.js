import anime from 'animejs/lib/anime.es.js'

const SVGNS = 'http://www.w3.org/2000/svg'
/**
 * This system coordinates drawing HTML and SVG to the screen.
 *
 * It's also responsible for disposing of used elements and
 * playing/ending the various animations of the text.
 *
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
  }

  createBubble ({
    htmlString,
    x,
    y
  }) {
    return new SpeechBubble({
      div: this.div,
      svg: this.svg,
      htmlString: wrapText(htmlString),
      x,
      y
    })
  }
}

let _id = 0
class SpeechBubble {
  constructor ({
    div,
    svg,
    htmlString,
    x,
    y
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

    const rect = this.createRect({
      x, y: y - height, width, height
    })
    return new Promise((resolve, reject) => {
      anime
        .timeline()
        .add({
          targets: `svg rect`,
          height: [height],
          scale: 1,
          duration: 300,
          easing: 'easeInOutQuart'
        })
        .add({
          targets: `#${this.id} .letter`,
          translateY: ['1.1em', 0],
          translateZ: 0,
          opacity: 1,
          duration: 750,
          delay: anime.stagger(100, { easing: 'easeOutQuad' }),
          easing: 'easeInOutBack'
        })
        .add({
          targets: `#${this.id}, svg rect`,
          opacity: 0,
          delay: 200,
          duration: 800,
          easing: 'linear',
          complete: resolve
        })
    }).then(() => {
      // rect.removeChild()
      // textDiv.removeChild()
    })
  }

  createRect ({ x, y, width, height }) {
    const rect = document.createElementNS(SVGNS, 'rect')
    rect.setAttribute('x', `${x}`)
    rect.setAttribute('y', `${y + height + 1}`)
    rect.setAttribute('width', `${width}`)
    rect.setAttribute('height', `${0}`)
    rect.setAttribute('fill', 'white')
    this.svg.appendChild(rect)
    return rect
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
