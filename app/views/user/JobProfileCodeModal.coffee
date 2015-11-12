ModalView = require 'views/core/ModalView'
template = require 'templates/account/job-profile-code-modal'
LevelSessionCodeView = require 'views/common/LevelSessionCodeView'

module.exports = class JobProfileCodeModal extends ModalView
  id: 'job-profile-code-modal'
  template: template
  modalWidthPercent: 90
  plain: true

  constructor: (options) ->
    super(arguments...)
    @session = options.session

  afterRender: ->
    super()
    codeView = new LevelSessionCodeView({session:@session})
    @insertSubView(codeView, @$el.find('.level-session-code-view'))

