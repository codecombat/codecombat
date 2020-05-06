import store from 'core/store'
import {
  getVisualChalkBoardData,
  getShowVisualChalkboard
} from '../../../../app/schemas/models/selectors/cinematic'
import { SyncFunction } from '../commands/commands'
import _ from 'lodash'
import { defaultWidth, defaultHeight, defaultXoffset, defaultYoffset } from '../../../site/components/cinematic/common/visualChalkboardModule'

export default class VisualChalkboard {
  constructor () {
    this.lastChalkboardData = null
    // Assume the chalkboard always starts off the screen.
    this.lastShownStateBool = false
  }

  parseDialogNode (dialogNode) {
    const commands = []
    const visualChalboardData = getVisualChalkBoardData(dialogNode) || {}
    const { chalkboardContent, width, height, xOffset, yOffset } = visualChalboardData
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
      this.lastChalkboardData = _.merge(this.lastChalkboardData, visualChalboardData)
      const commandDataChalkboard = new SyncFunction(() =>
        store.dispatch('visualChalkboard/changeChalkboardContents', {
          markdown: chalkboardContent,
          width,
          height,
          xOffset,
          yOffset
        })
      )
      if (priorChalkboard) {
        commandDataChalkboard.undoCommandFactory = () => {
          const {
            chalkboardContent,
            width,
            height,
            xOffset,
            yOffset
          } = priorChalkboard
          return new SyncFunction(() => {
            if (chalkboardContent || width || height) {
              store.dispatch('visualChalkboard/changeChalkboardContents', {
                markdown: chalkboardContent,
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
}
