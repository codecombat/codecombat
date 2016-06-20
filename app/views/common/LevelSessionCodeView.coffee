CocoView = require 'views/core/CocoView'
template = require 'templates/common/level_session_code'

Level = require 'models/Level'
LevelSession = require 'models/LevelSession'

module.exports = class LevelSessionCodeView extends CocoView
  className: 'level-session-code-view'
  template: template

  constructor: (options) ->
    super(options)
    @session = options.session
    @level = LevelSession.getReferencedModel(@session.get('level'), LevelSession.schema.properties.level)
    @level.setProjection ['employerDescription', 'name', 'icon', 'banner', 'slug']
    @supermodel.loadModel @level

  getRenderData: ->
    c = super()
    c.levelIcon = @level.get('banner') or @level.get('icon')
    c.levelName = @level.get('name')
    c.levelDescription = marked(@level.get('employerDescription') or '')
    c.levelSpells = @organizeCode()
    c.sessionLink = "/play/level/" + (@level.get('slug') or @level.id) + "?team=" + (@session.get('team') || 'humans') + "&session=" + @session.id
    c

  afterRender: ->
    super()
    editors = []
    @$el.find('.code').each (index, codeEl) ->
      height = parseInt($(codeEl).data('height'))
      $(codeEl).height(height)
      editor = ace.edit codeEl
      editor.setReadOnly true
      editors.push editor
      aceSession = editor.getSession()
      aceSession.setMode 'ace/mode/javascript'  # TODO: they're not all JS
    @editors = editors

  organizeCode: ->
    team = @session.get('team') or 'humans'
    teamSpells = @session.get('teamSpells')[team] or []
    filteredSpells = []
    for spell in teamSpells
      code = @session.getSourceFor(spell) ? ''
      lines = code.split('\n').length
      height = lines * 16 + 20
      filteredSpells.push {
        code: code
        name: spell
        height: height
      }
    filteredSpells

  destroy: ->
    for editor in @editors
      @editors
