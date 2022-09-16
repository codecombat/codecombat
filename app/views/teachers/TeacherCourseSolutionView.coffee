require('app/styles/teachers/teacher-course-solution-view.sass')
utils = require 'core/utils'
RootView = require 'views/core/RootView'
Course = require 'models/Course'
Campaign = require 'models/Campaign'
Level = require 'models/Level'
LevelComponent = require 'models/LevelComponent'
Prepaids = require 'collections/Prepaids'
Levels = require 'collections/Levels'
utils = require 'core/utils'
ace = require('lib/aceContainer')
aceUtils = require 'core/aceUtils'
aetherUtils = require 'lib/aether_utils'

module.exports = class TeacherCourseSolutionView extends RootView
  id: 'teacher-course-solution-view'
  template: require 'app/templates/teachers/teacher-course-solution-view'

  events:
    'click .nav-link': 'onClickSolutionTab'
    'click .print-btn': 'onClickPrint'

  onClickSolutionTab: (e) ->
    link = $(e.target).closest('a')
    levelSlug = link.data('level-slug')
    solutionIndex = link.data('solution-index')
    tracker.trackEvent('Click Teacher Course Solution Tab', {levelSlug, solutionIndex})

  onClickPrint: ->
    window.tracker?.trackEvent 'Teachers Click Print Solution', { category: 'Teachers', label: @courseID + "/" + @language }

  getTitle: ->
    title = $.i18n.t('teacher.course_solution')
    title += " " + @course.acronym() if @course
    if @language != "html"
      title +=  " " + utils.capitalLanguages[@language]
    title

  showTeacherLegacyNav: ->
    # HACK: Hack to support legacy solution page with page from new teacher dashboard.
    #       Once new dashboard is released we can remove this check.
    if utils.getQueryVariables()?['from-new-dashboard']
      return false
    return true

  initialize: (options, @courseID, @language) ->
    @isWebDev = @courseID in [utils.courseIDs.WEB_DEVELOPMENT_2]
    if me.isTeacher() or me.isAdmin()
      @prettyLanguage = @camelCaseLanguage(@language)
      if options.campaignMode
        campaignSlug = @courseID
        @campaign = new Campaign(_id: campaignSlug)
        @supermodel.trackRequest(@campaign.fetch())
        @levels = new Levels([], { url: "/db/campaign/#{campaignSlug}/level-solutions"})
      else
        @course = new Course(_id: @courseID)
        @supermodel.trackRequest(@course.fetch())
        @levels = new Levels([], { url: "/db/course/#{@courseID}/level-solutions"})
      @supermodel.loadCollection(@levels, 'levels', {cache: false})

      @levelNumberMap = {}
      @prepaids = new Prepaids()
      @supermodel.trackRequest @prepaids.fetchMineAndShared()
    @paidTeacher = me.isAdmin() or me.isPaidTeacher()
    @courseLessonSlidesURLs = utils.courseLessonSlidesURLs
    me.getClientCreatorPermissions()?.then(() => @render?())
    super(options)

  camelCaseLanguage: (language) ->
    return language if _.isEmpty(language)
    return 'JavaScript' if language is 'javascript'
    return 'C++' if language is 'cpp'
    language.charAt(0).toUpperCase() + language.slice(1)

  hideWrongLanguage: (s) ->
    return '' unless s
    s.replace /```([a-z]+)[^`]+```/gm, (a, l) =>
      return """```#{@language}
       #{aetherUtils.translateJS(a[13..a.length-4], @language, false)}
       ```""" if @language in ['cpp', 'java', 'python', 'lua', 'coffeescript'] and l is 'javascript' and not ///```#{@language}///.test(s)
      return '' if l isnt @language
      a

  onLoaded: ->
    @paidTeacher = @paidTeacher or @prepaids.find((p) => p.get('type') in ['course', 'starter_license'] and p.get('maxRedeemers') > 0)?
    @listenTo me, 'change:preferredLanguage', @updateLevelData
    @updateLevelData()

  updateLevelData: ->
    if utils.isCodeCombat
      solutionLanguages = [@language]
      solutionLanguages.push 'html' if @language isnt 'html' and @isWebDev
      @levelSolutionsMap = @levels.getSolutionsMap(solutionLanguages)
    else # Ozaria
      @levelSolutionsMap = @levels.getSolutionsMap([@language])
      # TODO: When we have a property in the course like `modulesReleased`, we can limit and loop over that number here:
      @levels.models = @levels.models.filter((level) =>
  # Intro types don't have solutions yet, so don't show them for now:
        if level.get('type') == 'intro'
          return false
        # Without a solution, guide or default code, there's nothing to show:
        solution = @levelSolutionsMap[level.get('original')] || []
        if solution.length == 0 && !level.get('guide') && !level.get('begin')
          return false

        return true
      )
    for level in @levels?.models
      articles = level.get('documentation')?.specificArticles
      if articles
        guide = articles.filter((x) => x.name == "Overview").pop()
        level.set 'guide', marked(@hideWrongLanguage(utils.i18n(guide, 'body'))) if guide
        intro = articles.filter((x) => x.name == "Intro").pop()
        level.set 'intro', marked(@hideWrongLanguage(utils.i18n(intro, 'body'))) if intro
      heroPlaceholder = level.get('thangs').filter((x) => x.id == 'Hero Placeholder').pop()
      if utils.isCodeCombat
        comp = heroPlaceholder?.components.filter((x) => x.original.toString() == '524b7b5a7fc0f6d51900000e' ).pop()
      else
        comp = heroPlaceholder?.components.filter((x) => LevelComponent.ProgrammableIDs.includes(x.original.toString())).pop()
      programmableMethod = comp?.config.programmableMethods.plan
      if programmableMethod
        if utils.isCodeCombat
          solutionLanguage = level.get('primerLanguage') or @language
          solutionLanguage = 'html' if @isWebDev and not level.get('primerLanguage')
        try
          if utils.isCodeCombat
            defaultCode = programmableMethod.languages[solutionLanguage] or (@language == 'cpp' and aetherUtils.translateJS(programmableMethod.source, 'cpp')) or programmableMethod.source
          else
            defaultCode = programmableMethod.languages[level.get('primerLanguage') or @language] or (@language == 'cpp' and aetherUtils.translateJS(programmableMethod.source, 'cpp')) or programmableMethod.source
          translatedDefaultCode = _.template(defaultCode)(utils.i18n(programmableMethod, 'context'))
        catch e
          console.error('Broken solution for level:', level.get('name'))
          console.log(e)
          console.log(defaultCode)
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
    if utils.isCodeCombat and @course?.id == utils.courseIDs.WEB_DEVELOPMENT_2
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
      if utils.isOzaria
        aceEditor.renderer.setShowGutter(true)

  getLearningGoalsForLevel: (level) ->
    documentation = level.get('documentation')
    if !documentation
      return

    specificArticles = documentation.specificArticles
    if !specificArticles
      return

    learningGoals = _.find(specificArticles, { name: 'Learning Goals' })
    if !learningGoals
      return

    return learningGoals.body
