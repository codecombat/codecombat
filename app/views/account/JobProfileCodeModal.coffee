ModalView = require 'views/kinds/ModalView'
template = require 'templates/account/job_profile_code_modal'
LevelSessionCodeView = require 'views/common/LevelSessionCodeView'

module.exports = class JobProfileCodeModal extends ModalView
  id: 'job_profile_code_modal'
  template: template
  modalWidthPercent: 90
  plain: true
  
  constructor: (options) ->
    super(arguments...)
    @session = options.session
    
  getRenderData: ->
    c = super()
    c.session = @session
    c

  afterRender: ->
    super()
    codeView = new LevelSessionCodeView({session:@session})
    @insertSubView(codeView, @$el.find('.level-session-code-view'))
    