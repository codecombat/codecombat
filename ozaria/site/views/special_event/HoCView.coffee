RootComponent = require 'views/core/RootComponent'
template = require 'templates/base-flat'
HoCComponent = require('./HoCComponent.vue').default
CreateAccountModal = require 'views/core/CreateAccountModal/CreateAccountModal'

module.exports = class HoCView extends RootComponent
  id: 'hoc-'
  template: template
  VueComponent: HoCComponent
  skipMetaBinding: true

  constructor: (options) ->
    super(options)
    @propsData = {
      onGetCS1Free: (teacherEmail) =>
        return if _.isEmpty(teacherEmail)
        @openModalView(new CreateAccountModal({startOnPath: 'teacher', email: teacherEmail}))
    }
