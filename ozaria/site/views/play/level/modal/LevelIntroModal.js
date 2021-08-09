import ModalComponent from 'app/views/core/ModalComponent'
import LevelIntroComponent from './LevelIntroComponent.vue'
import { internationalizeLevelType } from 'ozaria/site/common/ozariaUtils'
import utils from 'core/utils'

class LevelIntroModal extends ModalComponent {
  // Runs before the constructor is called.
  initialize () {
    this.propsData = {
      levelName: null,
      levelType: null,
      narrative: null,
      learningGoals: null,
      characterPortrait: null,
      onStart: function () {}
    }
  }

  constructor (options) {
    super(options)
    if (options.level) {
      const specificArticles = (options.level.get('documentation') || {}).specificArticles || []
      const narrative = _.find(specificArticles, { name: 'Intro' })
      const learningGoals = _.find(specificArticles, { name: 'Learning Goals' })
      let narrativeText = 'Placeholder narrative text'
      let learningGoalsText = 'Placeholder learning goals'
      if (narrative) {
        narrativeText = utils.i18n(narrative, 'body')
      }
      if (learningGoals) {
        learningGoalsText = utils.i18n(learningGoals, 'body')
      }
      let levelTypeText = internationalizeLevelType(options.level.get('ozariaType'), true)
      let levelName = utils.i18n(options.level.attributes, 'displayName') || utils.i18n(options.level.attributes, 'name')
      this.propsData = {
        levelName: levelName,
        levelType: levelTypeText,
        narrative: narrativeText,
        learningGoals: learningGoalsText,
        characterPortrait: options.level.get('characterPortrait') || 'vega'
      }
    }
    if (options.onStart) {
      this.propsData.onStart = options.onStart
    }
  }

  destroy () {
    if (this.onDestroy) {
      this.onDestroy()
    }
    super.destroy()
  }
}

LevelIntroModal.prototype.id = 'level-intro-modal'
LevelIntroModal.prototype.template = require('ozaria/site/templates/core/modal-base-flat')
LevelIntroModal.prototype.VueComponent = LevelIntroComponent
LevelIntroModal.prototype.propsData = null
LevelIntroModal.prototype.closesOnClickOutside = false
LevelIntroModal.prototype.closesOnEscape = false

export default LevelIntroModal
