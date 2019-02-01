RootComponent = require 'views/core/RootComponent'
PlayLevelVideoComponent = require('./PlayLevelVideoComponent.vue').default
utils = require 'core/utils'

module.exports = class PlayLevelVideoView extends RootComponent
  id: 'play-level-video-view'
  template: require 'templates/base-flat'
  VueComponent: PlayLevelVideoComponent

  constructor: (options, @levelID) ->
    @propsData = { @levelID }
    @propsData.courseID = utils.getQueryVariable 'course' or null
    @propsData.courseInstanceID = utils.getQueryVariable 'course-instance' or null
    @propsData.codeLanguage = utils.getQueryVariable 'codeLanguage' or null
    @propsData.level = utils.getQueryVariable 'level' or null
    super(options)

  destroy: ->
    @onDestroy?()
    console.log("view destroy")
    console.log($('#main-nav'))
    super()
