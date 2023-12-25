import { getProgressStatusHelper } from '../helpers/levelCompletionHelper'

export default {
  methods: {
    getProgressStatus (level) {
      return getProgressStatusHelper(this.levelSessions, level)
    }
  }
}
