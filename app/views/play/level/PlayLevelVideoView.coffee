RootComponent = require 'views/core/RootComponent'
PlayLevelVideoComponent = require('./PlayLevelVideoComponent.vue').default
utils = require 'core/utils'

module.exports = class PlayLevelVideoView extends RootComponent
  id: 'play-level-video-view'
  template: require 'templates/base-flat'
  VueComponent: PlayLevelVideoComponent
  skipMetaBinding: true

  initialize: (options, @levelID) ->
    @propsData ?= {}
    @propsData.levelSlug = @levelID
    @propsData.courseID = utils.getQueryVariable 'course'
    @propsData.courseInstanceID = utils.getQueryVariable 'course-instance'
    @propsData.codeLanguage = utils.getQueryVariable 'codeLanguage'
    @propsData.levelOriginalID = utils.getQueryVariable 'level'
    super(options)

  destroy: ->
    @onDestroy?()
    super()
