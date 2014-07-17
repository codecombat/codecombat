ModalView = require 'views/kinds/ModalView'
template = require 'templates/account/job_profile_code_modal'
LevelSessionCodeView = require 'views/common/LevelSessionCodeView'
console.log 'template', template

module.exports = class JobProfileCodeModal extends ModalView
  id: 'job_profile_code_modal'
  template: template
  
  constructor: (options) ->
    super(arguments...)
    @session = options.session

  afterRender: ->
    super()
    return unless @session.loaded
    codeView = new LevelSessionCodeView({session:@session})
    @insertSubView(codeView)
    