import anime from 'animejs/lib/anime.es.js'
import { AnimeCommand, SyncFunction } from '../commands/commands'
import {
  getClearText,
  getTextPosition,
  getSpeaker,
  getTextAnimationLength,
  getCamera,
  getTextWidth
} from '../../../../app/schemas/models/selectors/cinematic'
import { processText, getDefaultTextPosition } from './helper'
import { WIDTH, HEIGHT, LETTER_ANIMATE_TIME } from '../constants'

const BUBBLE_PADDING = 10
const SPEECH_BUBBLE_MAX_WIDTH = `37vmin`
const SPEECH_BUBBLE_ZOOMED_MAX_WIDTH = `68vmin`
import store from 'app/core/store'

/**
 * This system coordinates drawing HTML and SVG to the screen.
 * It is also responsible for localization and interpolation of the speech bubbles.
 */

let _id = 0;
const idTextMap = {};
const getIdFromElementId = (id) => {
  return parseInt(id.split('-').pop(), 10);
}

export default class DialogSystem {
  constructor ({ canvasDiv }) {
    const div = this.div = document.createElement('div')

    div.style.position = `absolute`
    div.style.width = `100%`
    div.style.height = `100%`
    div.style.zIndex = `20`
    div.style.pointerEvents = `none`

    canvasDiv.appendChild(div)

    this.shownDialogBubbles = []
    this._templateDataParameters = {}
    _id = 0;
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
      const width = getTextWidth(dialogNode)
      const id = ++_id;
      idTextMap[id] = this.getHashFromText(dialogNode.text);
      commands.push((new SpeechBubble({
        div: this.div,
        htmlString: text,
        x,
        y,
        shownDialogBubbles: this.shownDialogBubbles,
        side,
        textDuration: getTextAnimationLength(dialogNode),
        zoom,
        width,
        id,
      })).createBubbleCommand())
    }
    return commands
  }

  /**
   * Creates a command that clears prior text bubbles.
   * The bubbles cleared are tracked so we can undo the command
   * thus supporting navigating backwards.
   * @returns {AbstractCommand}
   */
  clearShownDialogBubbles () {
    let scopedArrayOfHiddenElements = null
    const hideDialogueBubbleCommand = new SyncFunction(() => {
      scopedArrayOfHiddenElements = []
      this.shownDialogBubbles.forEach(el => {
        if (el.style.display === `inline-block`) {
          scopedArrayOfHiddenElements.push(el)
          el.style.display = 'none'
        }
      })
    })

    hideDialogueBubbleCommand.undoCommandFactory = () => {
      return new SyncFunction(() => {
        scopedArrayOfHiddenElements.forEach(el => {
          el.style.display = 'inline-block'
          const numericalId = getIdFromElementId(el.id);
          store.dispatch('cinematicActionLog/changeCurrentPrompt', idTextMap[numericalId]);
        })
      })
    }

    return hideDialogueBubbleCommand
  }

  // since prompts dont have unique id - hashing the text to create a sort of uniqueId
  getHashFromText(text) {
    return Buffer.from(text || '').toString('base64').slice(0, 20);
  }
}

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
    textDuration,
    zoom,
    width,
    id
  }) {
    this.id = `speech-${id}`
    const parser = new DOMParser()
    const html = parser.parseFromString(htmlString, 'text/html')

    const textDiv = html.body.firstChild
    const speechBubbleDiv = document.createElement('div')

    speechBubbleDiv.style.display = 'inline-block'
    speechBubbleDiv.style.position = 'absolute'

    if (typeof width === 'number') {
      speechBubbleDiv.style.maxWidth = `${width}vmin`
    } else {
      speechBubbleDiv.style.maxWidth = zoom === 2 ? SPEECH_BUBBLE_ZOOMED_MAX_WIDTH : SPEECH_BUBBLE_MAX_WIDTH
    }

    speechBubbleDiv.id = this.id
    speechBubbleDiv.className = `cinematic-speech-bubble-${side}`

    speechBubbleDiv.appendChild(textDiv)
    div.appendChild(speechBubbleDiv)

    // Calculate bounding box
    const bbox = speechBubbleDiv.getBoundingClientRect()
    const height = (bbox.bottom - bbox.top) + 2 * BUBBLE_PADDING

    // Set the origin for the left character speech bubble on the bottom left.
    // Set the origin for the right character speech bubble on the bottom right.
    y -= (height - BUBBLE_PADDING)
    if (side === 'right') {
      speechBubbleDiv.style.right = `${(WIDTH - x) / WIDTH * 100}%`
    }else if(side === 'center'){
      speechBubbleDiv.style.left = `calc( ${x / WIDTH * 100}% - 19vmin)`
    }else {
      speechBubbleDiv.style.left = `${x / WIDTH * 100}%`
    }

    speechBubbleDiv.style.top = `${y / HEIGHT * 100}%`

    const letters = (document.querySelectorAll(`#${this.id} .letter`) || []).length || 1
    if (textDuration === undefined) {
      textDuration = letters * LETTER_ANIMATE_TIME
    }

    this.resetSpeechBubble = () => {
      speechBubbleDiv.style.opacity = 0
      speechBubbleDiv.style.display = 'none'
      document.querySelectorAll(`#${this.id} .letter`)
        .forEach(letter => {
          letter.style.opacity = 0
        })
    }

    // We set up the animation but don't play it yet.
    // On completion we attach html node to the `shownDialogBubbles`
    // array for future cleanup.
    this.resetSpeechBubble()
    this.animationFn = () => {
      const numericalId = getIdFromElementId(this.id);
      store.dispatch('cinematicActionLog/changeCurrentPrompt', idTextMap[numericalId]);
      shownDialogBubbles.push(speechBubbleDiv)
      this.resetSpeechBubble()
      return anime
        .timeline({
          autoplay: false
        })
        .add({
          targets: `#${this.id}`,
          opacity: 1,
          duration: 100,
          easing: 'easeInOutQuart',
          begin: () => {
            speechBubbleDiv.style.display = 'inline-block'
          }
        })
        .add({
          targets: `#${this.id} .letter`,
          opacity: 1,
          duration: 20,
          delay: anime.stagger(textDuration / letters, { easing: 'linear' }),
          easing: 'easeOutQuad'
        })
    }
  }

  /**
   * @returns {AbstractCommand} command to play the animation revealing the speech bubble.
   */
  createBubbleCommand () {
    const animBubbleCommand = new AnimeCommand(this.animationFn)
    animBubbleCommand.undoCommandFactory = () => {
      return new SyncFunction(() => {
        this.resetSpeechBubble()
      })
    }

    return animBubbleCommand
  }
}
