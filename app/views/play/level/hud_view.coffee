View = require 'views/kinds/CocoView'
template = require 'templates/play/level/hud'
prop_template = require 'templates/play/level/hud_prop'
action_template = require 'templates/play/level/hud_action'
DialogueAnimator = require './dialogue_animator'

module.exports = class HUDView extends View
  id: 'thang-hud'
  template: template
  dialogueMode: false

  subscriptions:
    'surface:frame-changed': 'onFrameChanged'
    'level-disable-controls': 'onDisableControls'
    'level-enable-controls': 'onEnableControls'
    'surface:sprite-selected': 'onSpriteSelected'
    'sprite:speech-updated': 'onSpriteDialogue'
    'level-sprite-clear-dialogue': 'onSpriteClearDialogue'
    'level:shift-space-pressed': 'onShiftSpacePressed'
    'level:escape-pressed': 'onEscapePressed'
    'dialogue-sound-completed': 'onDialogueSoundCompleted'
    'thang-began-talking': 'onThangBeganTalking'
    'thang-finished-talking': 'onThangFinishedTalking'

  events:
    'click': -> Backbone.Mediator.publish 'focus-editor'

  afterRender: =>
    super()
    @$el.addClass 'no-selection'

  onFrameChanged: (e) ->
    @timeProgress = e.progress
    @update()

  onDisableControls: (e) ->
    return if e.controls and not ('hud' in e.controls)
    @disabled = true

  onEnableControls: (e) ->
    return if e.controls and not ('hud' in e.controls)
    @disabled = false

  onSpriteSelected: (e) ->
    # TODO: this allows the surface and HUD selection to get out of sync if we select another unit while in dialogue mode
    return if @disabled or @dialogueMode
    @switchToThangElements()
    @setThang e.thang, e.sprite?.thangType

  onSpriteDialogue: (e) ->
    return unless e.message
    spriteID = e.sprite.thang.id
    @setSpeaker e.sprite
    @stage?.startTalking()
    @setMessage(e.message, e.mood, e.responses)
    window.tracker?.trackEvent 'Heard Sprite', {speaker: spriteID, message: e.message, label: e.message}, ['Google Analytics']

  onDialogueSoundCompleted: ->
    @stage?.stopTalking()

  onSpriteClearDialogue: ->
    @clearSpeaker()

  setThang: (thang, thangType) ->
    unless @speaker
      if not thang? and not @thang? then return
      if thang? and @thang? and thang.id is @thang.id then return

    @thang = thang
    @thangType = thangType
    @$el.toggleClass 'no-selection', not @thang?
    clearTimeout @hintNextSelectionTimeout
    @$el.find('.no-selection-message').hide()
    if not @thang
      @hintNextSelectionTimeout = _.delay((=> @$el.find('.no-selection-message').slideDown('slow')), 10000)
      return
    @createAvatar thangType
    @createProperties()
    @createActions()
    @update()
    @speaker = null

  setSpeaker: (speakerSprite) ->
    return if speakerSprite is @speakerSprite
    @speakerSprite = speakerSprite
    @speaker = @speakerSprite.thang.id
    @createAvatar @speakerSprite.thangType
    @$el.removeClass 'no-selection'
    @switchToDialogueElements()

  clearSpeaker: ->
    if not @thang
      @$el.addClass 'no-selection'
    @setThang @thang, @thangType
    @switchToThangElements()
    @speaker = null
    @speakerSprite = null
    @bubble = null
    @update()

  createAvatar: (thangType) ->
    stage = thangType.getPortraitStage()
    wrapper = @$el.find '.thang-canvas-wrapper'
    newCanvas = $(stage.canvas).addClass('thang-canvas')
    wrapper.empty().append(newCanvas)
    team = @thang?.team or @speakerSprite?.thang?.team
    newCanvas.parent().removeClass('team-ogres').removeClass('team-humans').addClass("team-#{team}")
    stage.update()
    @stage?.stopTalking()
    @stage = stage

  onThangBeganTalking: (e) ->
    return unless @stage and @thang is e.thang
    @stage?.startTalking()

  onThangFinishedTalking: (e) ->
    return unless @stage and @thang is e.thang
    @stage?.stopTalking()

  createProperties: ->
    props = @$el.find('.thang-props')
    props.find(":not(.thang-name)").remove()
    props.find('.thang-name').text(if @thang.id is @thang.spriteName then @thang.id else "#{@thang.id} - #{@thang.spriteName}")
    for prop in @thang.hudProperties ? []
      pel = @createPropElement prop
      continue unless pel?
      if pel.find('.bar').is('*') and props.find('.bar').is('*')
        props.find('.bar-prop').last().after pel  # Keep bars together
      else
        props.append pel

  createActions: ->
    actions = @$el.find('.thang-actions tbody').empty()
    return unless @thang.world and not _.isEmpty @thang.actions
    @buildActionTimespans()
    for actionName, action of @thang.actions
      actions.append @createActionElement(actionName)
      @lastActionTimespans[actionName] = {}

  setMessage: (message, mood, responses) ->
    message = marked message
    clearInterval(@messageInterval) if @messageInterval
    @bubble = $('.dialogue-bubble', @$el)
    @bubble.removeClass(@lastMood) if @lastMood
    @lastMood = mood
    @bubble.text('')
    group = $('<div class="enter hide"></div>')
    @bubble.append(group)
    if responses
      @lastResponses = responses
      for response in responses
        button = $('<button class="btn btn-small banner"></button>').text(response.text)
        button.addClass response.buttonClass if response.buttonClass
        group.append(button)
        response.button = $('button:last', group)
    else
      s = $.i18n.t('play_level.hud_continue', defaultValue: "Continue (press shift-space)")
      if @shiftSpacePressed > 4 and not @escapePressed
        group.append('<span class="hud-hint">Press esc to skip dialog</span>')
      group.append($('<button class="btn btn-small banner with-dot">' + s + ' <div class="dot"></div></button>'))
      @lastResponses = null
    @bubble.append($("<h3>#{@speaker ? 'Captain Anya'}</h3>"))
    @animator = new DialogueAnimator(message, @bubble)
    @messageInterval = setInterval(@addMoreMessage, 20)

  addMoreMessage: =>
    if @animator.done()
      clearInterval(@messageInterval)
      @messageInterval = null
      $('.enter', @bubble).removeClass("hide").css('opacity', 0.0).delay(500).animate({opacity:1.0}, 500, @animateEnterButton)
      if @lastResponses
        buttons = $('.enter button')
        for response, i in @lastResponses
          f = (r) => => setTimeout((-> Backbone.Mediator.publish(r.channel, r.event)), 10)
          $(buttons[i]).click(f(response))
      else
        $('.enter', @bubble).click(-> Backbone.Mediator.publish('end-current-script'))
      return
    @animator.tick()

  onShiftSpacePressed: (e) ->
    @shiftSpacePressed = (@shiftSpacePressed || 0) + 1
    # We don't need to handle end-current-script--that's done--but if we do have
    # custom buttons, then we need to trigger the one that should fire (the last one).
    # If we decide that always having the last one fire is bad, we should make it smarter.
    return unless @lastResponses?.length
    r = @lastResponses[@lastResponses.length - 1]
    _.delay (-> Backbone.Mediator.publish(r.channel, r.event)), 10

  onEscapePressed: (e) ->
    @escapePressed = true

  animateEnterButton: =>
    return unless @bubble
    button = $('.enter', @bubble)
    dot = $('.dot', button)
    dot.animate({opacity:0.2}, 300).animate({opacity:1.9}, 600, @animateEnterButton)

  switchToDialogueElements: ->
    @dialogueMode = true
    $('.thang-elem', @$el).addClass('hide')
    @$el.find('.thang-canvas-wrapper').removeClass('hide')
    $('.dialogue-area', @$el)
      .removeClass('hide')
      .animate({opacity:1.0}, 200)
    $('.dialogue-bubble', @$el)
      .css('opacity', 0.0)
      .delay(200)
      .animate({opacity:1.0}, 200)
    clearTimeout @hintNextSelectionTimeout

  switchToThangElements: ->
    @dialogueMode = false
    $('.thang-elem', @$el).removeClass('hide')
    $('.dialogue-area', @$el).addClass('hide')

  update: ->
    return unless @thang and not @speaker
    # Update properties
    @updatePropElement(prop, @thang[prop]) for prop in @thang.hudProperties ? []
    # Update action timeline
    @updateActions()

  createPropElement: (prop) ->
    if prop in ["maxHealth"]
      return null  # included in the bar
    context =
      prop: prop
      hasIcon: prop in ["health", "pos", "target", "inventory"]
      hasBar: prop in ["health"]
    $(prop_template(context))

  updatePropElement: (prop, val) ->
    pel = @$el.find '.thang-props *[name=' + prop + ']'
    if prop in ["health"]
      max = @thang["max" + prop.charAt(0).toUpperCase() + prop.slice(1)]
      regen = @thang[prop + "ReplenishRate"]
      percent = Math.round 100 * val / max
      pel.find('.bar').css 'width', percent + "%"
      labelText = prop + ": " + @formatValue(prop, val) + " / " + @formatValue(prop, max)
      if regen
        labelText += " (+" + @formatValue(prop, regen) + "/s)"
      pel.attr 'title', labelText
    else if prop in ["maxHealth"]
      return
    else
      s = @formatValue(prop, val)
      pel.find('.prop-value').text s
      pel.attr 'title', "#{prop}: #{s}"
    pel

  formatValue: (prop, val) ->
    if prop is "target" and not val
      val = @thang["targetPos"]
      val = null if val?.isZero()
    if prop is "rotation"
      return (val * 180 / Math.PI).toFixed(0) + "˚"
    if typeof val is 'number'
      if Math.round(val) == val then return val.toFixed(0)  # int
      if -10 < val < 10 then return val.toFixed(2)
      if -100 < val < 100 then return val.toFixed(1)
      return val.toFixed(0)
    if val and typeof val is "object"
      if val.id
        return val.id
      else if val.x and val.y
        #return "x: #{val.x.toFixed(0)} y: #{val.y.toFixed(0)}"
        return "x: #{val.x.toFixed(0)} y: #{val.y.toFixed(0)}, z: #{val.z.toFixed(0)}"  # Debugging: include z
    else if not val?
      return "No " + prop
    return val

  updateActions: ->
    return unless @thang.world and not _.isEmpty @thang.actions
    @buildActionTimespans() unless @timespans
    for actionName, action of @thang.actions
      @updateActionElement(actionName, @timespans[actionName], @thang.action.name is actionName)
    tableContainer = @$el.find('.table-container')
    timelineWidth = tableContainer.find('.action-timeline').width()
    right = (1 - (@timeProgress ? 0)) * timelineWidth
    arrow = tableContainer.find('.progress-arrow')
    arrow.css 'right', right - arrow.width() / 2
    tableContainer.find('.progress-line').css 'right', right

  buildActionTimespans: ->
    @lastActionTimespans = {}
    @timespans = {}
    dt = @thang.world.dt
    actionHistory = @thang.world.actionsForThang @thang.id, true
    [lastFrame, lastAction] = [0, 'idle']
    for hist in actionHistory.concat {frame: @thang.world.totalFrames, name: 'END'}
      [newFrame, newAction] = [hist.frame, hist.name]
      continue if newAction is lastAction
      if newFrame > lastFrame
        (@timespans[lastAction] ?= []).push [lastFrame * dt, newFrame * dt]
      [lastFrame, lastAction] = [newFrame, newAction]

  createActionElement: (action) ->
    $(action_template(action: action))

  updateActionElement: (action, timespans, current) ->
    ael = @$el.find '.thang-actions *[name=' + action + ']'
    ael.toggleClass 'current-action', current

    timespans ?= []
    lastTimespans = @lastActionTimespans[action] ? []
    if @lastActionTimespans and timespans.length is lastTimespans.length
      changed = false
      for timespan, i in timespans
        if timespan[0] isnt lastTimespans[i][0] or timespan[1] isnt lastTimespans[i][1]
          changed = true
          break
      return unless changed
    ael.toggleClass 'hidden', not timespans.length
    @lastActionTimespans[action] = timespans
    timeline = ael.find('.action-timeline .timeline-wrapper').empty()
    lifespan = @thang.world.totalFrames / @thang.world.frameRate
    scale = timeline.width() / lifespan
    for [start, end] in timespans
      bar = $('<div></div>').css left: start * scale, right: (lifespan - end) * scale
      timeline.append bar

    ael

  destroy: ->
    super()
    @stage?.stopTalking()
