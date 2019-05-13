import anime from 'animejs/lib/anime.es.js'
import { AnimeCommand, SyncFunction } from './Command/commands'
import { getClearText, getTextPosition, getSpeaker, getTextAnimationLength } from '../../../schemas/selectors/cinematic'
import { processText } from './dialog-system/dialogSystemHelper'

const SVGNS = 'http://www.w3.org/2000/svg'
const padding = 10

/**
 * This system coordinates drawing HTML and SVG to the screen.
 * It is also responsible for localization and interpolation of the speech bubbles.
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

    this.shownDialogBubbles = []
    this._templateDataParameters = {}
  }

  /**
   * This templateDataParameters object can be accessed from the dialog text templates.
   * E.g. a templateDataParameters object of: `{ name: 'Mary' }` can then be used in the following
   * dialog text:
   *   `Hello, <%=o.name%>`
   * Which then appears as:
   *   `Hello, Mary`
   *
   * @param {Object} templateDataParameters - used for interpolation.
   */
  set templateContext (templateDataParameters) {
    this._templateDataParameters = templateDataParameters
  }

  /**
   * The system method that is run on every dialogNode.
   * @param {import('../../../schemas/selectors/cinematic').DialogNode} dialogNode
   * @returns {AbstractCommand[]}
   */
  parseDialogNode (dialogNode) {
    const commands = []
    const text = processText(dialogNode, this._templateDataParameters)
    const shouldClear = getClearText(dialogNode)
    const { x, y } = getTextPosition(dialogNode) || { x: 200, y: 200 }
    const side = getSpeaker(dialogNode) || 'left'

    if (shouldClear) {
      commands.push(this.clearShownDialogBubbles())
    }

    if (text) {
      commands.push((new SpeechBubble({
        div: this.div,
        svg: this.svg,
        htmlString: text,
        x,
        y,
        shownDialogBubbles: this.shownDialogBubbles,
        side,
        textDuration: getTextAnimationLength(dialogNode)
      })).createBubbleCommand())
    }
    return commands
  }

  /**
   * @returns {AbstractCommand}
   */
  clearShownDialogBubbles () {
    return new SyncFunction(() => {
      this.shownDialogBubbles.forEach(el => el.remove())
    })
  }
}

let _id = 0
/**
 * Creates a speech bubble eagerly.
 * Can return a command to display the speech bubble when called.
 *
 * Attaches itself to the svg canvas and div canvas.
 */
class SpeechBubble {
  constructor ({
    div,
    svg,
    htmlString,
    x,
    y,
    shownDialogBubbles,
    side,
    textDuration
  }) {
    this.id = `speech-${_id++}`
    const parser = new DOMParser()
    const html = parser.parseFromString(htmlString, 'text/html')
    const textDiv = html.body.firstChild
    textDiv.style.display = 'inline-block'
    textDiv.style.position = 'absolute'
    textDiv.style.left = `${x}`
    textDiv.style.top = `${y}`
    textDiv.id = this.id

    div.appendChild(textDiv)

    // We've created and attached the dialog text.
    // Now we can calculate the bounding box and draw the svg shape.
    const bbox = textDiv.getBoundingClientRect()
    const width = (bbox.right - bbox.left) + 2 * padding
    const height = (bbox.bottom - bbox.top) + 2 * padding

    const svgGroup = createSvgShape({
      x,
      y: y - height,
      width,
      height,
      className: this.id,
      side
    })
    svg.appendChild(svgGroup)

    // We set up the animation but don't play it yet.
    // On completion we attach html node and svg node to the `shownDialogBubbles`
    // array for future cleanup.
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
        height: [height],
        duration: 300,
        easing: 'easeInOutQuart'
      })
      .add({
        targets: `#${this.id} .letter`,
        opacity: 1,
        duration: textDuration,
        delay: anime.stagger(50, { easing: 'linear' }),
        easing: 'easeOutQuad',
        complete: () => {
          shownDialogBubbles.push(svgGroup)
          shownDialogBubbles.push(textDiv)
        }
      })
  }

  /**
   * @returns {AbstractCommand} command to play the animation revealing the speech bubble.
   */
  createBubbleCommand () {
    return new AnimeCommand(this.animation)
  }
}

/**
 * @typedef {Object} SvgBubbleOptions
 * @property {number} x - x position of the bubble.
 * @property {number} y - y position
 * @property {number} width
 * @property {number} height
 * @property {'left'|'right'} side
 * @property {string} class - the unique class for this bubble
 */

/**
 * Returns a svg speech bubble that can be attached to an svg canvas.
 * @param {SvgBubbleOptions} svgOptions - Svg options for generating the svg shape.
 * @returns {SVGGElement} the group element of the svg bubble.
 */
function createSvgShape ({ x, y, width, height, side, className }) {
  const g = document.createElementNS(SVGNS, 'g')
  g.setAttribute('transform', `translate(${x - padding}, ${y + height + 1 - padding})`)
  g.setAttribute('fill', 'white')
  // Animation will reveal this svg.
  g.setAttribute('opacity', '0')
  g.setAttribute('class', className)

  const rect = document.createElementNS(SVGNS, 'rect')
  rect.setAttribute('width', `${width}`)

  // Animation will add the future height.
  rect.setAttribute('height', `${0}`)

  const path = document.createElementNS(SVGNS, 'path')
  path.setAttribute('d', 'M -20 20 l 21 -10 0 20 z')
  if (side === 'right') {
    path.setAttribute('transform', `translate(${width},0) scale(-1, 1)`)
  }
  g.appendChild(rect)
  g.appendChild(path)
  return g
}
