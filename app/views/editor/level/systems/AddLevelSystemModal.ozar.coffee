require('app/styles/editor/level/system/add.sass')
ModalView = require 'views/core/ModalView'
template = require 'templates/editor/level/system/add'
availableSystemTemplate = require 'templates/editor/level/system/available_system'
LevelSystem = require 'models/LevelSystem'
CocoCollection = require 'collections/CocoCollection'

class LevelSystemSearchCollection extends CocoCollection
  url: '/db/level.system'
  model: LevelSystem

module.exports = class AddLevelSystemModal extends ModalView
  id: 'editor-level-system-add-modal'
  template: template
  instant: true

  events:
    'click .available-systems-list li': 'onAddSystem'

  constructor: (options) ->
    super options
    @extantSystems = options.extantSystems ? []
    @systems = @supermodel.loadCollection(new LevelSystemSearchCollection(), 'systems').model

  afterRender: ->
    super()
    return unless @supermodel.finished()
    @renderAvailableSystems()

  renderAvailableSystems: ->
    ul = @$el.find('ul.available-systems-list').empty()
    systems = (m.attributes for m in @systems.models)
    _.remove systems, (system) =>
      _.find @extantSystems, {original: system.original}  # already have this one added
    systems = _.sortBy systems, 'name'
    for system in systems
      ul.append $(availableSystemTemplate(system: system))

  onAddSystem: (e) ->
    id = $(e.currentTarget).data('system-id')
    system = _.find @systems.models, id: id
    unless system
      return console.error 'Couldn\'t find system for id', id, 'out of', @systems.models
    # Add all dependencies, recursively, unless we already have them
    toAdd = system.getDependencies(@systems.models)
    _.remove toAdd, (s1) =>
      _.find @extantSystems, original: s1.get('original')
    for s in toAdd.concat [system]
      levelSystem =
        original: s.get('original') ? id
        majorVersion: s.get('version').major ? 0
      @extantSystems.push levelSystem
      Backbone.Mediator.publish 'editor:level-system-added', system: levelSystem
    @renderAvailableSystems()
