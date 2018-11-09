ModalComponent = require 'views/core/ModalComponent'
HoCInterstitialComponent = require('./HoC2018InterstitialModal.vue').default

module.exports = class HoC2018InterstitialModal extends ModalComponent
  id: 'hoc-interstitial-modal'
  template: require 'templates/core/modal-base-flat'
  closeButton: true
  VueComponent: HoCInterstitialComponent

  initialize: ->
    @propsData = {
      clickStudent: () => @hide(),
      clickTeacher: () => alert("Clicked teacher")
    }