View = require 'views/kinds/CocoView'
template = require 'templates/editor/level/thang/edit'
ThangComponentEditView = require 'views/editor/components/main'
ThangType = require 'models/ThangType'

module.exports = class LevelThangEditView extends View
  ###
  In the level editor, is the bar at the top when editing a single thang.
  Everything below is part of the ThangComponentEditView, which is shared with the
  ThangType editor view.
  ###

  id: 'editor-level-thang-edit'
  template: template

  events:
    'click #all-thangs-link': 'navigateToAllThangs'
    'click #thang-name-link span': 'toggleNameEdit'
    'click #thang-type-link span': 'toggleTypeEdit'
    'blur #thang-name-link input': 'toggleNameEdit'
    'blur #thang-type-link input': 'toggleTypeEdit'

  constructor: (options) ->
    options ?= {}
    super options
    @world = options.world
    @thangData = options.thangData ? {}
    @level = options.level
    @oldID = @thangData.id

  getRenderData: (context={}) ->
    context = super(context)
    context.thang = @thangData
    context

  onLoaded: -> @render()
  afterRender: ->
    super()
    options =
      components: @thangData.components
      supermodel: @supermodel
      level: @level
      world: @world
      callback: @onComponentsChanged

    @thangComponentEditView = new ThangComponentEditView options
    @insertSubView @thangComponentEditView
    thangTypeNames = (m.get('name') for m in @supermodel.getModels ThangType)
    input = @$el.find('#thang-type-link input').autocomplete(source: thangTypeNames, minLength: 0, delay: 0, autoFocus: true)
    thangType = _.find @supermodel.getModels(ThangType), (m) => m.get('original') is @thangData.thangType
    thangTypeName = thangType?.get('name') or 'None'
    input.val(thangTypeName)
    @$el.find('#thang-type-link span').text(thangTypeName)
    window.input = input
    @hideLoading()

  saveThang: (e) ->
    # Make sure it validates first?
    event =
      thangData: @thangData
      id: @oldID
    Backbone.Mediator.publish 'level-thang-edited', event

  navigateToAllThangs: ->
    Backbone.Mediator.publish 'level-thang-done-editing'

  toggleNameEdit: ->
    link = @$el.find '#thang-name-link'
    wasEditing = link.find('input:visible').length
    span = link.find('span')
    input = link.find('input')
    if wasEditing then span.text(input.val()) else input.val(span.text())
    link.find('span, input').toggle()
    input.select() unless wasEditing
    @thangData.id = span.text()
    @saveThang()

  toggleTypeEdit: ->
    link = @$el.find '#thang-type-link'
    wasEditing = link.find('input:visible').length
    span = link.find('span')
    input = link.find('input')
    span.text(input.val()) if wasEditing
    link.find('span, input').toggle()
    input.select() unless wasEditing
    thangTypeName = input.val()
    thangType = _.find @supermodel.getModels(ThangType), (m) -> m.get('name') is thangTypeName
    if thangType and wasEditing
      @thangData.thangType = thangType.get('original')
    @saveThang()

  onComponentsChanged: (components) =>
    @thangData.components = components
    @saveThang()
