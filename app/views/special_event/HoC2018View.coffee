RootComponent = require 'views/core/RootComponent'
template = require 'templates/base-flat'
HoC2018 = require('./HoC2018Component.vue').default
CreateAccountModal = require 'views/core/CreateAccountModal/CreateAccountModal'

module.exports = class HoC2018View extends RootComponent
  id: 'hoc-2018'
  template: template
  VueComponent: HoC2018
  skipMetaBinding: true

  constructor: (options) ->
    super(options)
    @propsData = {
      onGetCS1Free: (teacherEmail) =>
        return if _.isEmpty(teacherEmail)
        @openModalView(new CreateAccountModal({startOnPath: 'teacher', email: teacherEmail}))
    }
