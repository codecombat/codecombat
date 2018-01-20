require('app/styles/play/level/hud.sass')
CocoView = require 'views/core/CocoView'
template = require 'templates/play/level/hud'
prop_template = require 'templates/play/level/hud_prop'
utils = require 'core/utils'

module.exports = class LevelHUDView extends CocoView
  id: 'thang-hud'
  template: template

  subscriptions:
    'surface:frame-changed': 'onFrameChanged'
    'level:disable-controls': 'onDisableControls'
    'level:enable-controls': 'onEnableControls'
    'surface:sprite-selected': 'onSpriteSelected'
    'sprite:thang-began-talking': 'onThangBeganTalking'
    'sprite:thang-finished-talking': 'onThangFinishedTalking'
    'god:new-world-created': 'onNewWorld'

  events:
    'click': 'onClick'

  constructor: ->
    if features.codePlay
      classNames = (@className or '').split(' ')
      classNames.push 'code-play'
      @className = classNames.join(' ')
    super(arguments...)

  afterRender: ->
    super()
    @$el.addClass 'no-selection'
    if @options.level.get('hidesHUD')
      @hidesHUD = true
      @$el.addClass 'hide-hud-properties'

  onClick: (e) ->
    Backbone.Mediator.publish 'tome:focus-editor', {} unless $(e.target).parents('.thang-props').length

  onFrameChanged: (e) ->
    @timeProgress = e.progress
    @update()

  onDisableControls: (e) ->
    return if e.controls and not ('hud' in e.controls)
    @disabled = true
    @$el.addClass 'controls-disabled'

  onEnableControls: (e) ->
    return if e.controls and not ('hud' in e.controls)
    @disabled = false
    @$el.removeClass 'controls-disabled'

  onSpriteSelected: (e) ->
    return if @disabled
    @setThang e.thang, e.sprite?.thangType

  onNewWorld: (e) ->
    hadThang = @thang
    @thang = e.world.thangMap[@thang.id] if @thang
    if hadThang and not @thang
      @setThang null, null

  setThang: (thang, thangType) ->
    if not thang? and not @thang? then return
    if thang? and @thang? and thang.id is @thang.id then return
    if thang? and @hidesHUD and thang.id isnt 'Hero Placeholder' then return  # Don't let them find the names of their opponents this way
    return unless thang  # Don't let them deselect anything, ever.
    @thang = thang
    @thangType = thangType
    return unless @thang
    @createAvatar thangType, @thang
    @createProperties()
    @update()

  createAvatar: (thangType, thang, colorConfig) ->
    unless thangType.isFullyLoaded()
      args = arguments
      unless @listeningToCreateAvatar
        @listenToOnce thangType, 'sync', -> @createAvatar(args...)
        @listeningToCreateAvatar = true
      return
    @listeningToCreateAvatar = false
    options = thang.getLankOptions() or {}
    options.async = false
    options.colorConfig = colorConfig if colorConfig
    wrapper = @$el.find '.thang-canvas-wrapper'
    team = @thang?.team
    wrapper.removeClass 'hide'
    wrapper.removeClass (i, css) -> (css.match(/\bteam-\S+/g) or []).join ' '
    wrapper.addClass "team-#{team}"
    if thangType.get('raster')
      wrapper.empty().append($('<img draggable="false"/>').addClass('avatar').attr('src', '/file/'+thangType.get('raster')))
    else
      return unless stage = thangType.getPortraitStage options, 100
      newCanvas = $(stage.canvas).addClass('thang-canvas avatar')
      wrapper.empty().append(newCanvas)
      stage.update()
      @stage?.stopTalking()
      @stage = stage
    wrapper.append($('<img draggable="false" />').addClass('avatar-frame').attr('src', '/images/level/thang_avatar_frame.png'))

  onThangBeganTalking: (e) ->
    return unless @stage and @thang is e.thang
    @stage?.startTalking()

  onThangFinishedTalking: (e) ->
    return unless @stage and @thang is e.thang
    @stage?.stopTalking()

  createProperties: ->
    if @options.level.isType('game-dev')
      name = 'Game'  # TODO: we don't need the HUD at all
    else if @thang.id in ['Hero Placeholder', 'Hero Placeholder 1']
      name = @thangType?.getHeroShortName() or 'Hero'
    else
      name = @thang.hudName or (if @thang.type then "#{@thang.id} - #{@thang.type}" else @thang.id)
    utils.replaceText @$el.find('.thang-name'), name
    props = @$el.find('.thang-props')
    props.find('.prop').remove()
    #propNames = _.without @thang.hudProperties ? [], 'action'
    propNames = @thang.hudProperties
    for prop, i in propNames ? []
      pel = @createPropElement prop
      continue unless pel?
      if pel.find('.bar').is('*') and props.find('.bar').is('*')
        props.find('.bar-prop').last().after pel  # Keep bars together
      else
        props.append pel
    null

  update: ->
    return unless @thang
    @$el.find('.thang-props-column').toggleClass 'nonexistent', not @thang.exists
    if @thang.exists
      @updatePropElement(prop, @thang[prop]) for prop in @thang.hudProperties ? []

  createPropElement: (prop) ->
    if prop in ['maxHealth']
      return null  # included in the bar
    context =
      prop: prop
      hasIcon: prop in ['health', 'pos', 'target', 'collectedThangIDs', 'gold', 'bountyGold', 'value', 'visualRange', 'attackDamage', 'attackRange', 'maxSpeed', 'attackNearbyEnemyRange']
      hasBar: prop in ['health']
    $(prop_template(context))

  updatePropElement: (prop, val) ->
    pel = @$el.find '.thang-props *[name=' + prop + ']'
    if prop in ['maxHealth']
      return  # Don't show maxes--they're built into bar labels.
    if prop in ['health']
      max = @thang['max' + prop.charAt(0).toUpperCase() + prop.slice(1)]
      regen = @thang[prop + 'ReplenishRate']
      percent = Math.round 100 * val / max
      pel.find('.bar').css 'width', percent + '%'
      labelText = prop + ': ' + @formatValue(prop, val) + ' / ' + @formatValue(prop, max)
      if regen
        labelText += ' (+' + @formatValue(prop, regen) + '/s)'
      utils.replaceText pel.find('.bar-prop-value'), Math.round(val)
    else
      s = @formatValue(prop, val)
      labelText = "#{prop}: #{s}"
      if prop is 'attackDamage'
        cooldown = @thang.actions.attack.cooldown
        dps = @thang.attackDamage / cooldown
        labelText += " / #{cooldown.toFixed(2)}s (DPS: #{dps.toFixed(2)})"
      utils.replaceText pel.find('.prop-value'), s
    pel.attr 'title', labelText
    pel

  formatValue: (prop, val) ->
    if prop is 'target' and not val
      val = @thang['targetPos']
      val = null if val?.isZero()
    if prop is 'rotation'
      return (val * 180 / Math.PI).toFixed(0) + '˚'
    if prop.search(/Range$/) isnt -1
      return val + 'm'
    if typeof val is 'number'
      if Math.round(val) == val or prop is 'gold' then return val.toFixed(0)  # int
      if -10 < val < 10 then return val.toFixed(2)
      if -100 < val < 100 then return val.toFixed(1)
      return val.toFixed(0)
    if val and typeof val is 'object'
      if val.id
        return val.id
      else if val.x and val.y
        return "x: #{val.x.toFixed(0)} y: #{val.y.toFixed(0)}"
        #return "x: #{val.x.toFixed(0)} y: #{val.y.toFixed(0)}, z: #{val.z.toFixed(0)}"  # Debugging: include z
    else if not val?
      return 'No ' + prop
    return val

  destroy: ->
    @stage?.stopTalking()
    super()
