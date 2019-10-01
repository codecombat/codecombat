ModalComponent = require 'views/core/ModalComponent'
HoCInterstitialComponent = require('./HoC2018InterstitialModal.vue').default

module.exports = class HoC2018InterstitialModal extends ModalComponent
  id: 'hoc-interstitial-modal'
  template: require 'templates/core/modal-base-flat'
  closeButton: true
  VueComponent: HoCInterstitialComponent

  # Runs before the constructor is called.
  initialize: ->
    @propsData = {
      clickStudent: () => @hide(),
      clickTeacher: () => application.router.navigate('/teachers/hour-of-code', { trigger: true }),
      showVideo: false
    }
  constructor: (options) ->
    super(options)
    @propsData.showVideo = options?.showVideo or false
    @onDestroy = options?.onDestroy

  destroy: ->
    @onDestroy?()
    super()
