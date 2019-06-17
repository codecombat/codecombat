import ModalComponent from 'app/views/core/ModalComponent'
import CapstoneProgressComponent from './CapstoneProgressComponent.vue'

class CapstoneProgressModal extends ModalComponent {
  // Runs before the constructor is called.
  initialize () {
    this.propsData = {
      levelSlug: null,
      capstoneStage: null,
      remainingGoals: null
    }
  }

  constructor (options) {
    super(options)
    if (options) {
      this.propsData = {
        levelSlug: options.levelSlug,
        capstoneStage: options.capstoneStage,
        remainingGoals: options.remainingGoals
      }
    }
  }

  destroy () {
    if (this.onDestroy) {
      this.onDestroy()
    }

    this.goToCinematic()
  }

  goToCinematic () {
    application.router.navigate(`/cinematicplaceholder/${this.propsData.levelSlug}`, { trigger: true })
  }
}

CapstoneProgressModal.prototype.id = 'capstone-progress-modal'
CapstoneProgressModal.prototype.template = require('app/templates/core/modal-base-flat')
CapstoneProgressModal.prototype.VueComponent = CapstoneProgressComponent
CapstoneProgressModal.prototype.propsData = null

export default CapstoneProgressModal
