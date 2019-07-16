require('app/styles/teachers/teacher-course-solution-view.sass')
utils = require 'core/utils'
RootView = require 'views/core/RootView'
Course = require 'models/Course'
Level = require 'models/Level'
Prepaids = require 'collections/Prepaids'
Levels = require 'collections/Levels'
utils = require 'core/utils'
ace = require('lib/aceContainer')
aceUtils = require 'core/aceUtils'

module.exports = class TeacherCourseSolutionView extends RootView
  id: 'teacher-course-solution-view'
  template: require 'templates/teachers/teacher-course-solution-view'

  events:
    'click .nav-link': 'onClickSolutionTab'
  
  onClickSolutionTab: (e) ->
    link = $(e.target).closest('a')
    levelSlug = link.data('level-slug')
    solutionIndex = link.data('solution-index')
    tracker.trackEvent('Click Teacher Course Solution Tab', {levelSlug, solutionIndex})

  getTitle: ->
    title = $.i18n.t('teacher.course_solution')
    title += " " + @course.acronym()
    if @language != "html"
      title +=  " " + utils.capitalLanguages[@language]
    title

  initialize: (options, @courseID, @language) ->
    if me.isTeacher() or me.isAdmin()
      @prettyLanguage = @camelCaseLanguage(@language)
      @course = new Course(_id: @courseID)
      @supermodel.trackRequest(@course.fetch())
      @levels = new Levels([], { url: "/db/course/#{@courseID}/level-solutions"})
      @supermodel.loadCollection(@levels, 'levels', {cache: false})
      @levelNumberMap = {}
      @prepaids = new Prepaids()
      @supermodel.trackRequest @prepaids.fetchMineAndShared()
    @paidTeacher = me.isAdmin() or me.isPaidTeacher()
    me.getClientCreatorPermissions()?.then(() => @render?())
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
    @paidTeacher = @paidTeacher or @prepaids.find((p) => p.get('type') in ['course', 'starter_license'] and p.get('maxRedeemers') > 0)?
    @listenTo me, 'change:preferredLanguage', @updateLevelData
    @updateLevelData()

  updateLevelData: ->
    @levelSolutionsMap = @levels.getSolutionsMap([@language])
    for level in @levels?.models
      articles = level.get('documentation')?.specificArticles
      if articles
        guide = articles.filter((x) => x.name == "Overview").pop()
        level.set 'guide', marked(@hideWrongLanguage(utils.i18n(guide, 'body'))) if guide
        intro = articles.filter((x) => x.name == "Intro").pop()
        level.set 'intro', marked(@hideWrongLanguage(utils.i18n(intro, 'body'))) if intro
      heroPlaceholder = level.get('thangs').filter((x) => x.id == 'Hero Placeholder').pop()
      comp = heroPlaceholder?.components.filter((x) => x.original.toString() == '524b7b5a7fc0f6d51900000e' ).pop()
      programmableMethod = comp?.config.programmableMethods.plan
      if programmableMethod
        try
          translatedDefaultCode = _.template(programmableMethod.languages[level.get('primerLanguage') or @language] or programmableMethod.source)(utils.i18n(programmableMethod, 'context'))
        catch e
          console.error('Broken solution for level:', level.get('name'))
          continue
        # See if it has <playercode> tags, extract them
        playerCodeTag = utils.extractPlayerCodeTag(translatedDefaultCode)
        finalDefaultCode = if playerCodeTag then playerCodeTag else translatedDefaultCode
        level.set 'begin', finalDefaultCode
    levels = []
    for level in @levels?.models when level.get('original')
      continue if @language? and level.get('primerLanguage') is @language
      levels.push({
        key: level.get('original'),
        practice: level.get('practice') ? false,
        assessment: level.get('assessment') ? false
      })
    @levelNumberMap = utils.createLevelNumberMap(levels)
    if @course?.id == utils.courseIDs.WEB_DEVELOPMENT_2
      # Filter out non numbered levels.
      @levels.models = @levels.models.filter((l) => l.get('original') of @levelNumberMap)
    @render?()

  afterRender: ->
    super()
    @$el.find('pre:has(code[class*="lang-"])').each ->
      codeElem = $(@).first().children().first()
      lang = mode for mode of aceUtils.aceEditModes when codeElem?.hasClass('lang-' + mode)
      aceEditor = aceUtils.initializeACE(@, lang or 'python')
      aceEditor.setShowInvisibles false
      aceEditor.setBehavioursEnabled false
      aceEditor.setAnimatedScroll false
      aceEditor.$blockScrolling = Infinity
