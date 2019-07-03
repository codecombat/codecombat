import { getWaitUserInput } from '../../../../app/schemas/models/selectors/cinematic'
import { SyncFunction } from '../commands/commands'

export default class Autoplay {
  constructor () {
    this.autoplay = false
  }

  parseDialogNode (dialogNode) {
    if (!getWaitUserInput(dialogNode)) {
      return [new SyncFunction(() => {
        this.autoplay = true
      })]
    }
    return []
  }
}
