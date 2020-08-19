const store = require('core/store')
const utils = require('core/utils')
import { internationalizeLevelType } from 'ozaria/site/common/ozariaUtils'
import RootComponent from 'views/core/RootComponent'
import template from 'templates/base-flat'
import TutorialPlayComponent from './TutorialPlayComponent'

class TutorialPlayView extends RootComponent {
  constructor (props = {}) {
    super(props)

    const { level } = props
    if (!level) {
      console.error('Could not create TutorialPlayView without level')
    }

    this.propsData = {
      characterPortrait: level.get('characterPortrait'),
      isTeacher: me.isTeacher()
    }

    const specificArticles = (level.get('documentation') || {}).specificArticles || []
    const narrative = _.find(specificArticles, { name: 'Intro' })
    let narrativeText = narrative ? utils.i18n(narrative, 'body') : undefined
    if (!narrativeText) {
      console.error('Could not look up utils.i18n(narrative, \'body\') for narrative text for intro modal')
      narrativeText = 'Narrative text'
    }
    const learningGoals = _.find(specificArticles, { name: 'Learning Goals' })

    store.dispatch('game/addTutorialStep', {
      message: narrativeText,
      intro: {
        levelType: internationalizeLevelType(level.get('ozariaType'), true),
        learningGoals: learningGoals ? utils.i18n(learningGoals, 'body') : 'Learning goals'
      }
    })

  }
}

TutorialPlayView.prototype.id = 'tutorial-play-view'
TutorialPlayView.prototype.template = template
TutorialPlayView.prototype.VueComponent = TutorialPlayComponent

export default TutorialPlayView
