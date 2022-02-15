require('app/styles/teachers/resource-hub-view.sass')
RootView = require 'views/core/RootView'
utils = require 'core/utils'

module.exports = class ResourceHubView extends RootView
  id: 'resource-hub-view'
  template: require 'templates/teachers/resource-hub-view'

  events:
    'click .resource-link': 'onClickResourceLink'

  getTitle: -> return $.i18n.t('teacher.resource_hub')

  initialize: ->
    @organizeLessonSlides()
    me.getClientCreatorPermissions()?.then(() => @render?())

  onClickResourceLink: (e) ->
    link = $(e.target).closest('a')?.attr('href')
    window.tracker?.trackEvent 'Teachers Click Resource Hub Link', { category: 'Teachers', label: link }

  organizeLessonSlides: ->
    courseLessonSlidesURLs = utils.courseLessonSlidesURLs
    @lessonSlidesURLsByCourse = {}
    for courseID, acronym of utils.courseAcronyms
      if url = utils.courseLessonSlidesURLs[courseID]
        @lessonSlidesURLsByCourse[acronym.toLowerCase()] = url
