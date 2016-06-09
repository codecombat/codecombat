CocoView = require 'views/core/CocoView'
template = require 'templates/editor/level/thang/level-thang-edit-view'
ThangComponentsEditView = require 'views/editor/component/ThangComponentsEditView'
ThangType = require 'models/ThangType'

module.exports = class LevelThangEditView extends CocoView
  ###
  In the level editor, is the bar at the top when editing a single thang.
  Everything below is part of the ThangComponentsEditView, which is shared with the
  ThangType editor view.
  ###

  id: 'level-thang-edit-view'
  template: template

  events:
    'click #all-thangs-link': 'navigateToAllThangs'
    'click #thang-name-link span': 'toggleNameEdit'
    'click #thang-type-link span': 'toggleTypeEdit'
    'blur #thang-name-link input': 'toggleNameEdit'
    'blur #thang-type-link input': 'toggleTypeEdit'
    'keydown #thang-name-link input': 'toggleNameEditIfReturn'
    'keydown #thang-type-link input': 'toggleTypeEditIfReturn'

  constructor: (options) ->
    options ?= {}
    super options
    @world = options.world
    @thangData = $.extend true, {}, options.thangData ? {}
    @level = options.level
    @oldPath = options.oldPath
    @reportChanges = _.debounce @reportChanges, 1000

  onLoaded: -> @render()
  afterRender: ->
    super()
    thangType = @supermodel.getModelByOriginal(ThangType, @thangData.thangType)
    options =
      components: @thangData.components
      supermodel: @supermodel
      level: @level
      world: @world

    if @level.get('type', true) in ['hero', 'hero-ladder', 'hero-coop', 'course', 'course-ladder', 'game-dev'] then options.thangType = thangType

    @thangComponentEditView = new ThangComponentsEditView options
    @listenTo @thangComponentEditView, 'components-changed', @onComponentsChanged
    @insertSubView @thangComponentEditView
    thangTypeNames = (m.get('name') for m in @supermodel.getModels ThangType)
    input = @$el.find('#thang-type-link input').autocomplete(source: thangTypeNames, minLength: 0, delay: 0, autoFocus: true)
    thangType = _.find @supermodel.getModels(ThangType), (m) => m.get('original') is @thangData.thangType
    thangTypeName = thangType?.get('name') or 'None'
    input.val(thangTypeName)
    @$el.find('#thang-type-link span').text(thangTypeName)
    @hideLoading()

  navigateToAllThangs: ->
    Backbone.Mediator.publish 'editor:level-thang-done-editing', {thangData: $.extend(true, {}, @thangData), oldPath: @oldPath}

  toggleNameEdit: ->
    link = @$el.find '#thang-name-link'
    wasEditing = link.find('input:visible').length
    span = link.find('span')
    input = link.find('input')
    if wasEditing then span.text(input.val()) else input.val(span.text())
    link.find('span, input').toggle()
    input.select() unless wasEditing
    @thangData.id = span.text()

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

  toggleNameEditIfReturn: (e) ->
    @$el.find('#thang-name-link input').blur() if e.which is 13

  toggleTypeEditIfReturn: (e) ->
    @$el.find('#thang-type-link input').blur() if e.which is 13

  onComponentsChanged: (components) =>
    @thangData.components = components
    @reportChanges()

  reportChanges: =>
    return if @destroyed
    Backbone.Mediator.publish 'editor:level-thang-edited', {thangData: $.extend(true, {}, @thangData), oldPath: @oldPath}
