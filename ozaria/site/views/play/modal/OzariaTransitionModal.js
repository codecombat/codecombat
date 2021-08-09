import ModalComponent from 'app/views/core/ModalComponent'
import ModalTransition from 'ozaria/site/components/common/ModalTransition'

class OzariaTransitionModal extends ModalComponent {
  // Runs before the constructor is called.
  initialize () {
    this.propsData = {
      campaignHandle: null,
      currentLevel: null,
      capstoneStage: null,
      courseId: null,
      courseInstanceId: null,
      goToNextDirectly: null,
      showShareModal: null,
      supermodel: null
    }
  }

  constructor (options) {
    super(options)
    this.propsData.currentLevel = options.level
    this.propsData.capstoneStage = options.capstoneStage
    this.propsData.courseId = options.courseId
    this.propsData.courseInstanceId = options.courseInstanceId
    this.propsData.goToNextDirectly = options.goToNextDirectly
    this.propsData.showShareModal = options.showShareModal
    this.propsData.supermodel = options.supermodel
  }

  destroy () {
    if (this.onDestroy) {
      this.onDestroy()
    }
    super.destroy()
  }
}

OzariaTransitionModal.prototype.id = 'ozaria-transition-modal'
OzariaTransitionModal.prototype.template = require('ozaria/site/templates/core/modal-empty')
OzariaTransitionModal.prototype.VueComponent = ModalTransition
OzariaTransitionModal.prototype.propsData = null
OzariaTransitionModal.prototype.closesOnClickOutside = false
OzariaTransitionModal.prototype.closesOnEscape = false

export default OzariaTransitionModal
