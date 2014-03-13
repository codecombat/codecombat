View = require 'views/kinds/ModalView'
template = require 'templates/play/level/modal/editor_config'
{me} = require('lib/auth')

module.exports = class EditorConfigModal extends View
  id: 'level-editor-config-modal'
  template: template

  events:
    'click textarea': 'onClickLink'
    'change #invisibles': 'updateInvisiblesSelection'
    'change #keyBindings': 'updateKeyBindingsSelection'
    'change #indentGuides': 'updateIndentGuides'

  constructor: (options) ->
    super(options)

  getRenderData: ->
    c = super()
    c.keyBindings = 'vim'
    c.invisibles = false
    c.indentGuides = true
    c

  afterRender: ->
    super()

  destroy: ->
    super()
