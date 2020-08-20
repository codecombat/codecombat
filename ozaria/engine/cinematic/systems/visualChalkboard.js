import store from 'core/store'
import {
  getVisualChalkBoardData,
  getShowVisualChalkboard
} from '../../../../app/schemas/models/selectors/cinematic'
import { SyncFunction } from '../commands/commands'
import _ from 'lodash'
import { defaultWidth, defaultHeight, defaultXoffset, defaultYoffset } from '../../../site/components/cinematic/common/visualChalkboardModule'
import { QuillDeltaToHtmlConverter } from 'quill-delta-to-html'
import { QUILL_CONFIG } from '../constants'
import marked from 'marked'

export default class VisualChalkboard {
  constructor () {
    this.lastChalkboardData = null
    // Assume the chalkboard always starts off the screen.
    this.lastShownStateBool = false
  }

  parseDialogNode (dialogNode) {
    const commands = []
    const visualChalkboardData = getVisualChalkBoardData(dialogNode) || {}
    const { chalkboardContent, width, height, xOffset, yOffset } = visualChalkboardData
    if (chalkboardContent || width || height || xOffset || yOffset) {
      let priorChalkboard = null
      if (this.lastChalkboardData !== null) {
        priorChalkboard = _.cloneDeep(this.lastChalkboardData)
      } else {
        // Ensures we can undo to default values.
        this.lastChalkboardData = {
          width: defaultWidth,
          height: defaultHeight,
          xOffset: defaultXoffset,
          yOffset: defaultYoffset
        }
      }
      this.lastChalkboardData = _.merge(this.lastChalkboardData, visualChalkboardData)

      // Convert to HTML, assume strings are markdown and non-strings are quill-json
      // TODO: better way to deliberately detect data schema here?
      let html = ''
      if (typeof chalkboardContent === 'string') {
        html = marked(chalkboardContent)
        this.lastChalkboardData.html = html
      } else if (typeof chalkboardContent === 'object') {
        html = new QuillDeltaToHtmlConverter(chalkboardContent.ops, QUILL_CONFIG).convert()
        html = `<div class="rich-text-content">${html}</div>`
        this.lastChalkboardData.html = html
      }
      const commandDataChalkboard = new SyncFunction(() =>
        store.dispatch('visualChalkboard/changeChalkboardContents', {
          html,
          width,
          height,
          xOffset,
          yOffset
        })
      )
      if (priorChalkboard) {
        this.storePriorChalkboard(commandDataChalkboard, priorChalkboard)
      }
      commands.push(commandDataChalkboard)
    }

    const show = getShowVisualChalkboard(dialogNode)
    if (typeof show === 'boolean') {
      const lastShownState = this.lastShownStateBool
      this.lastShownStateBool = show

      const mutationCommand = new SyncFunction(() =>
        store.dispatch('visualChalkboard/showVisualChalkboard', show)
      )

      mutationCommand.undoCommandFactory = () => {
        return new SyncFunction(() =>
          store.dispatch(
            'visualChalkboard/instantShowVisualChalkboard',
            lastShownState
          )
        )
      }

      commands.push(mutationCommand)
    }

    return commands
  }

  storePriorChalkboard (commandDataChalkboard, priorChalkboard) {
    commandDataChalkboard.undoCommandFactory = () => {
      const {
        html,
        width,
        height,
        xOffset,
        yOffset
      } = priorChalkboard
      return new SyncFunction(() => {
        if (html || width || height) {
          store.dispatch('visualChalkboard/changeChalkboardContents', {
            html,
            width,
            height
          })
        }
        store.dispatch('visualChalkboard/instantVisualChalkboardMove', {
          xOffset,
          yOffset
        })
      })
    }
  }
}
