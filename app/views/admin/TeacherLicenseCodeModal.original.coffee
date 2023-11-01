ModalComponent = require 'views/core/ModalComponent'
TeacherLicenseCodeComponent = require('./components/license/TeacherLicenseCode.vue').default

module.exports = class TeacherLicenseCodeModal extends ModalComponent
  id: 'teacher-license-code'
  template: require('app/templates/core/modal-base-flat')
  VueComponent: TeacherLicenseCodeComponent

  constructor: (options) ->
    super options
    @propsData = {
      hide: () => @hide()
    }

  destroy: ->
    @onDestroy?()
    super()
