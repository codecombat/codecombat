import ModalComponent from 'app/views/core/ModalComponent'
import LevelIntroComponent from './LevelIntroComponent.vue'
import { internationalizeConfig } from 'ozaria/site/common/ozariaUtils'

class LevelIntroModal extends ModalComponent {
  // Runs before the constructor is called.
  initialize () {
    this.propsData = {
      levelName: null,
      levelType: null,
      narrative: null,
      learningGoals: null,
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
        narrativeText = internationalizeConfig(narrative).body
      }
      if (learningGoals) {
        learningGoalsText = internationalizeConfig(learningGoals).body
      }
      this.propsData = {
        levelName: options.level.get('name'),
        levelType: options.level.get('ozariaType') || 'Practice',
        narrative: narrativeText,
        learningGoals: learningGoalsText
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
  }
}

LevelIntroModal.prototype.id = 'level-intro-modal'
LevelIntroModal.prototype.template = require('ozaria/site/templates/core/modal-base-flat')
LevelIntroModal.prototype.VueComponent = LevelIntroComponent
LevelIntroModal.prototype.propsData = null
LevelIntroModal.prototype.closesOnClickOutside = false
LevelIntroModal.prototype.closesOnEscape = false

export default LevelIntroModal
