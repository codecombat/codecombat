import ModalComponent from 'app/views/core/ModalComponent'
import ModalVictory from 'ozaria/site/components/common/ModalVictory'

class OzariaVictoryModal extends ModalComponent {
  // Runs before the constructor is called.
  initialize () {
    this.propsData = {
      campaignHandle: null,
      currentLevel: null,
      capstoneStage: null,
      courseId: null,
      courseInstanceId: null,
      goToNextDirectly: null
    }
  }

  constructor (options) {
    super(options)
    this.propsData.campaignHandle = options.level.get('campaign')
    this.propsData.currentLevel = options.level
    this.propsData.capstoneStage = options.capstoneStage
    this.propsData.courseId = options.courseID
    this.propsData.courseInstanceId = options.courseInstanceId
    this.propsData.goToNextDirectly = options.goToNextDirectly
  }

  destroy () {
    if (this.onDestroy) {
      this.onDestroy()
    }
  }
}

OzariaVictoryModal.prototype.id = 'ozaria-victory-modal'
OzariaVictoryModal.prototype.template = require('ozaria/site/templates/core/modal-base-flat')
OzariaVictoryModal.prototype.VueComponent = ModalVictory
OzariaVictoryModal.prototype.propsData = null
OzariaVictoryModal.prototype.closesOnClickOutside = false
OzariaVictoryModal.prototype.closesOnEscape = false

export default OzariaVictoryModal
