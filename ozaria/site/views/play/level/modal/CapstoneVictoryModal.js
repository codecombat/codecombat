import ModalComponent from 'app/views/core/ModalComponent'
import CapstoneVictoryComponent from './CapstoneVictoryComponent.vue'

class CapstoneVictoryModal extends ModalComponent {
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

CapstoneVictoryModal.prototype.id = 'capstone-victory-modal'
CapstoneVictoryModal.prototype.template = require('app/templates/core/modal-base-flat')
CapstoneVictoryModal.prototype.VueComponent = CapstoneVictoryComponent
CapstoneVictoryModal.prototype.propsData = null

export default CapstoneVictoryModal
