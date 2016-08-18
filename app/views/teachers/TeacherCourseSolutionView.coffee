RootView = require 'views/core/RootView'
CocoCollection = require 'collections/CocoCollection'
Course = require 'models/Course'
Level = require 'models/Level'

module.exports = class TeacherCourseSolutionView extends RootView
  id: 'teacher-course-solution-view'
  template: require 'templates/teachers/teacher-course-solution-view'

  getTitle: -> $.i18n.t('teacher.course_solution')

  initialize: (options, @courseID, @language) ->
    if me.isTeacher() or me.isAdmin()
      @prettyLanguage = @camelCaseLanguage(@language)
      @course = new Course(_id: @courseID)
      @supermodel.trackRequest(@course.fetch())
      @levels = new CocoCollection([], { url: "/db/course/#{@courseID}/level-solutions", model: Level})
      @supermodel.loadCollection(@levels, 'levels', {cache: false})
    super(options)

  camelCaseLanguage: (language) ->
    return language if _.isEmpty(language)
    return 'JavaScript' if language is 'javascript'
    language.charAt(0).toUpperCase() + language.slice(1)

  hideWrongLanguage: (s) ->
    return '' unless s
    s.replace /```([a-z]+)[^`]+```/gm, (a, l) =>
      return '' if l isnt @language
      a

  onLoaded: ->
    for level in @levels?.models
      articles = level.get('documentation')?.specificArticles
      if articles
        guide = articles.filter((x) => x.name == "Overview").pop()
        level.set 'guide', marked(@hideWrongLanguage(guide.body)) if guide
        intro = articles.filter((x) => x.name == "Intro").pop()
        level.set 'intro', marked(@hideWrongLanguage(intro.body)) if intro
      heroPlaceholder = level.get('thangs').filter((x) => x.id == 'Hero Placeholder').pop()
      comp = heroPlaceholder?.components.filter((x) => x.original.toString() == '524b7b5a7fc0f6d51900000e' ).pop()
      programmableMethod = comp?.config.programmableMethods.plan
      if programmableMethod
        level.set 'begin',  _.template(programmableMethod.languages[@language] or programmableMethod.source)(programmableMethod.context)
        solution = programmableMethod.solutions?.find (x) => x.language is @language
        level.set 'solution',  _.template(solution?.source)(programmableMethod.context)
    @render?()
