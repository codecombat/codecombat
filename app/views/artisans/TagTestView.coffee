require('app/styles/artisans/tag-test-view.sass')
RootView = require 'views/core/RootView'
CocoView = require 'views/core/CocoView'
template = require 'templates/artisans/tag-test-view'
tagger = require 'lib/SolutionConceptTagger'
conceptList =require 'schemas/concepts'

ThangType = require 'models/ThangType'

ThangTypes = require 'collections/ThangTypes'
ace = require('lib/aceContainer')

class ActualTagView extends CocoView
  template: require 'templates/artisans/tag-test-tags-view'
  id: 'tag-test-tags-view'

module.exports = class ThangTasksView extends RootView
  template: template
  id: 'tag-test-view'
  events:
    'input input': 'processThangs'
    'change input': 'processThangs'
  
  initialize: () ->
    @tags = []
    console.log "Hello"
    @debouncedUpdateTags = _.debounce @updateTags, 1000
  
  afterRender: () ->
    @insertSubView @tagView = new ActualTagView()
    ta = @$el.find('#tag-test-editor')
    @editor = ace.edit ta[0]
    @editor.resize()
    @editor.getSession().setMode("ace/mode/javascript")
    @editor.getSession().on 'change', () =>
      @tagView.tags = []
      @tagView.error = undefined
      @tagView.render()
      @debouncedUpdateTags()

    @editor.setValue(localStorage.code||'')
    @editor.focus()
    @updateTags()

  updateTags: () =>
    code = @editor.getValue()
    @tagView.tags = []
    @tagView.error = undefined
    localStorage.code = code
    try
      @tagView.tags = _.map tagger(source: code), (t) -> _.find(conceptList, (e) => e.concept is t)?.name
    catch e
      @tagView.error = e.stack
    
    @tagView.render()
    console.log "Update tags"
