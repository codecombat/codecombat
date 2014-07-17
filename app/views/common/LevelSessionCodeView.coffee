CocoView = require 'views/kinds/CocoView'
template = require 'templates/common/level_session_code'

Level = require 'models/Level'
LevelSession = require 'models/LevelSession'

module.exports = class LevelSessionCodeView extends CocoView
  className: 'level-session-code-view'
  template: template
  modalWidthPercent: 80
  plain: true

  constructor: (options) ->
    super(options)
    @session = options.session
    @level = LevelSession.getReferencedModel(@session.get('level'), LevelSession.schema.properties.level)
    @level.setProjection ['employerDescription', 'name', 'icon']
    @supermodel.loadModel @level, 'level'

  getRenderData: ->
    c = super()
    c.levelIcon = @level.get('icon')
    c.levelName = @level.get('name')
    c.levelDescription = marked(@level.get('employerDescription') or '')
    c.levelSpells = @organizeCode()
    c
    
  afterRender: ->
    super()
    @$el.find('.code').each (index, codeEl) ->
      editor = ace.edit codeEl
      editor.setReadOnly true
      aceSession = editor.getSession()
      aceSession.setMode 'ace/mode/javascript'
    
  organizeCode: ->
    team = @session.get('team') or 'humans'
    teamSpells = @session.get('teamSpells')[team] or []
    filteredSpells = []
    for spell in teamSpells
      code = @session.getSourceFor(spell)
      filteredSpells.push {
        code: code
        name: spell.split('/')[1]
      }
    filteredSpells 