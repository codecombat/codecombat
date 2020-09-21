ModalComponent = require 'views/core/ModalComponent'
HoCVictoryComponent = require('./HoCVictoryModal.vue').default

module.exports = class HoCVictoryModal extends ModalComponent
  id: 'hoc-victory-modal'
  template: require 'templates/core/modal-base-flat'
  closeButton: true
  VueComponent: HoCVictoryComponent

  constructor: (options) ->
    super(options)
    if not options.shareURL
      throw new Error("HoCVictoryModal requires shareURL value.")
    if not options.campaign
      throw new Error("HoCVictoryModal requires campaign slug.")
    @propsData = {
      navigateCertificate: (name, teacherEmail, shareURL) =>
        url = "/certificates/#{me.id}/anon?campaign=#{options.campaign}&username=#{name}"
        application.router.navigate(url, { trigger: true })
        if teacherEmail
          # Old event name: HoC2018
          window.tracker?.trackEvent('HoC2020 completed', {
            name: name,
            teacherEmail: teacherEmail,
            shareURL: shareURL,
            certificateURL: url,
            userId: me.id
          })
      ,
      shareURL: options.shareURL,
      fullName: if me.isAnonymous() then "" else me.broadName()
    }
