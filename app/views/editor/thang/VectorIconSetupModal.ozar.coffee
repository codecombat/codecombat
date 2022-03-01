require('app/styles/editor/thang/vector-icon-setup-modal.sass')
ModalView = require 'views/core/ModalView'
template = require 'templates/editor/thang/vector-icon-setup-modal'

module.exports = class VectorIconSetupModal extends ModalView
  id: "vector-icon-setup-modal"
  template: template
  demoSize: 400
  plain: true

  events:
    'change #container-select': 'onChangeContainer'
    'click #center': 'onClickCenter'
    'click #zero-bounds': 'onClickZeroBounds'
    'click #done-button': 'onClickDone'

  shortcuts:
    'shift+-': -> @incrScale(-0.02)
    'shift+=': -> @incrScale(0.02)
    'up': -> @incrRegY(1)
    'down': -> @incrRegY(-1)
    'left': -> @incrRegX(1)
    'right': -> @incrRegX(-1)

  constructor: (options, @thangType) ->
    portrait = @thangType.get('actions')?.portrait
    @containers = _.keys(@thangType.get('raw')?.containers or {})
    @container = portrait?.container or _.last @containers
    @scale = portrait?.scale or 1
    @regX = portrait?.positions?.registration?.x or 0
    @regY = portrait?.positions?.registration?.y or 0
    @saveChanges()
    super(options)

  saveChanges: ->
    actions = _.cloneDeep (@thangType.get('actions') ? {})
    actions.portrait ?= {}
    actions.portrait.scale = @scale
    actions.portrait.positions ?= {}
    actions.portrait.positions.registration = { x: @regX, y: @regY }
    actions.portrait.container = @container
    @thangType.set('actions', actions)
    @thangType.buildActions()

  afterRender: ->
    @initStage()
    super()

  initStage: ->
    return unless @containers and @container
    @stage = @thangType.getVectorPortraitStage(@demoSize)
    @sprite = @stage.children[0]
    canvas = $(@stage.canvas)
    canvas.attr('id', 'resulting-icon')
    @$el.find('#resulting-icon').replaceWith(canvas)
    @updateSpriteProperties()

  onChangeContainer: (e) ->
    @container = $(e.target).val()
    @saveChanges()
    @initStage()

  refreshSprite: ->
    return unless @stage
    stage = @thangType.getVectorPortraitStage(@demoSize)
    @stage.removeAllChildren()
    @stage.addChild(@sprite = stage.children[0])
    @updateSpriteProperties()
    @stage.update()

  updateSpriteProperties: ->
    @sprite.scaleX = @sprite.scaleY = @scale * @demoSize / 100
    @sprite.regX = @regX / @scale
    @sprite.regY = @regY / @scale
    console.log 'set to', @scale, @regX, @regY

  onClickCenter: ->
    containerInfo = @thangType.get('raw').containers[@container]
    b = containerInfo.b
    @regX = b[0]
    @regY = b[1]
    maxDimension = Math.max(b[2], b[3])
    @scale = 100 / maxDimension
    if b[2] > b[3]
      @regY += (b[3] - b[2]) / 2
    else
      @regX += (b[2] - b[3]) / 2
    @regX *= @scale
    @regY *= @scale
    @updateSpriteProperties()
    @stage.update()

  incrScale: (amount) ->
    @scale += amount
    @updateSpriteProperties()
    @stage.update()

  incrRegX: (amount) ->
    @regX += amount
    @updateSpriteProperties()
    @stage.update()

  incrRegY: (amount) ->
    @regY += amount
    @updateSpriteProperties()
    @stage.update()

  onClickDone: ->
    @saveChanges()
    @trigger 'done'
    @hide()