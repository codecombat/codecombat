import anime from 'animejs/lib/anime.es.js'
import { AnimeCommand, SyncFunction } from '../commands/commands'
import {
  getClearText,
  getTextPosition,
  getSpeaker,
  getTextAnimationLength,
  getCamera
} from '../../../../app/schemas/models/selectors/cinematic'
import { processText, getDefaultTextPosition } from './helper'
import { WIDTH, HEIGHT, LETTER_ANIMATE_TIME } from '../constants'

const BUBBLE_PADDING = 10
const SPEECH_BUBBLE_MAX_WIDTH = `300px` // Removed 20 px to account for padding.

/**
 * This system coordinates drawing HTML and SVG to the screen.
 * It is also responsible for localization and interpolation of the speech bubbles.
 */
export default class DialogSystem {
  constructor ({ canvasDiv }) {
    const div = this.div = document.createElement('div')

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
   * @param {import('../../../../app/schemas/models/selectors/cinematic').DialogNode} dialogNode
   * @param {Shot} currentShot
   * @returns {AbstractCommand[]}
   */
  parseDialogNode (dialogNode, shot) {
    const commands = []
    const text = processText(dialogNode, this._templateDataParameters)
    const shouldClear = getClearText(dialogNode)
    const side = getSpeaker(dialogNode) || 'left'

    if (shouldClear) {
      commands.push(this.clearShownDialogBubbles())
    }

    if (text) {
      // Use the camera setting from the shotSetup.
      const { zoom } = getCamera(shot)
      const { x, y } = getTextPosition(dialogNode) || getDefaultTextPosition(side, zoom)
      commands.push((new SpeechBubble({
        div: this.div,
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
 * Attaches itself to the div canvas.
 */
class SpeechBubble {
  constructor ({
    div,
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
    textDiv.style.maxWidth = SPEECH_BUBBLE_MAX_WIDTH
    textDiv.style.opacity = 0
    textDiv.id = this.id
    textDiv.className = `cinematic-speech-bubble-${side}`

    div.appendChild(textDiv)

    // Calculate bounding box
    const bbox = textDiv.getBoundingClientRect()
    const width = (bbox.right - bbox.left) + 2 * BUBBLE_PADDING
    const height = (bbox.bottom - bbox.top) + 2 * BUBBLE_PADDING

    // Set the origin for the left character speech bubble on the bottom left.
    // Set the origin for the right character speech bubble on the bottom right.
    y -= (height - BUBBLE_PADDING)
    if (side === 'right') {
      x -= width
    }

    textDiv.style.left = `${x / WIDTH * 100}%`
    textDiv.style.top = `${y / HEIGHT * 100}%`

    const letters = (document.querySelectorAll(`#${this.id} .letter`) || []).length || 1
    if (textDuration === undefined) {
      textDuration = letters * LETTER_ANIMATE_TIME
    }
    // We set up the animation but don't play it yet.
    // On completion we attach html node to the `shownDialogBubbles`
    // array for future cleanup.
    this.animation = anime
      .timeline({
        autoplay: false
      })
      .add({
        targets: `#${this.id}`,
        opacity: 1,
        duration: 100,
        easing: 'easeInOutQuart'
      })
      .add({
        targets: `#${this.id} .letter`,
        opacity: 1,
        duration: 20,
        delay: anime.stagger(textDuration / letters, { easing: 'linear' }),
        easing: 'easeOutQuad',
        complete: () => {
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
