SearchView = require 'views/common/SearchView'

module.exports = class LevelSearchView extends SearchView
  id: 'editor-course-home-view'
  modelLabel: 'Course'
  model: require 'models/Course'
  modelURL: '/db/course'
  tableTemplate: require 'templates/editor/course/table'
  projection: ['slug', 'name', 'description', 'watchers', 'creator']
  page: 'course'
  canMakeNew: false

  getRenderData: ->
    context = super()
    context.currentEditor = 'editor.course_title'
    context.currentNew = 'editor.new_course_title'
    context.currentNewSignup = 'editor.new_course_title_login'
    context.currentSearch = 'editor.course_search_title'
    @$el.i18n()
    @applyRTLIfNeeded()
    context
