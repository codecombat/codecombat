require('app/styles/courses/courses-view.sass')
RootView = require 'views/core/RootView'
template = require 'templates/courses/courses-view'
AuthModal = require 'views/core/AuthModal'
CreateAccountModal = require 'views/core/CreateAccountModal'
ChangeCourseLanguageModal = require 'views/courses/ChangeCourseLanguageModal'
HeroSelectModal = require 'views/courses/HeroSelectModal'
ChooseLanguageModal = require 'views/courses/ChooseLanguageModal'
ClassroomAnnouncementModal = require 'views/courses/ClassroomAnnouncementModal'
JoinClassModal = require 'views/courses/JoinClassModal'
CourseInstance = require 'models/CourseInstance'
CocoCollection = require 'collections/CocoCollection'
Course = require 'models/Course'
Classroom = require 'models/Classroom'
Tournament = require 'models/Tournament'
Classrooms = require 'collections/Classrooms'
Courses = require 'collections/Courses'
CourseInstances = require 'collections/CourseInstances'
LevelSession = require 'models/LevelSession'
LevelSessions = require 'collections/LevelSessions'
Levels = require 'collections/Levels'
NameLoader = require 'core/NameLoader'
Campaign = require 'models/Campaign'
ThangType = require 'models/ThangType'
utils = require 'core/utils'
store = require 'core/store'
leaderboardApi = require 'core/api/leaderboard'
clansApi = require 'core/api/clans'

module.exports = class CoursesView extends RootView
  id: 'courses-view'
  template: template

  events:
    'click #log-in-btn': 'onClickLogInButton'
    'click #start-new-game-btn': 'openSignUpModal'
    'click .current-hero': 'onClickChangeHeroButton'
    'click #join-class-btn': 'onClickJoinClassButton'
    'submit #join-class-form': 'onSubmitJoinClassForm'
    'click .play-btn': 'onClickPlay'
    'click .play-next-level-btn': 'onClickPlayNextLevel'
    'click .view-class-btn': 'onClickViewClass'
    'click .view-levels-btn': 'onClickViewLevels'
    'click .view-project-gallery-link': 'onClickViewProjectGalleryLink'
    'click .view-challenges-link': 'onClickViewChallengesLink'
    'click .view-videos-link': 'onClickViewVideosLink'
    'click .view-announcement-link': 'onClickAnnouncementLink'

  getMeta: ->
    return {
      title: $.i18n.t('courses.students')
      links: [
        { vmid: 'rel-canonical', rel: 'canonical', href: '/students'}
      ]
    }

  initialize: ->
    super()

    @classCodeQueryVar = utils.getQueryVariable('_cc', false)
    @courseInstances = new CocoCollection([], { url: "/db/user/#{me.id}/course_instances", model: CourseInstance})
    @courseInstances.comparator = (ci) -> return parseInt(ci.get('classroomID'), 16) + utils.orderedCourseIDs.indexOf ci.get('courseID')
    @listenToOnce @courseInstances, 'sync', @onCourseInstancesLoaded
    @supermodel.loadCollection(@courseInstances, { cache: false })
    @classrooms = new CocoCollection([], { url: "/db/classroom", model: Classroom})
    @classrooms.comparator = (a, b) -> b.id.localeCompare(a.id)
    @supermodel.loadCollection(@classrooms, { data: {memberID: me.id}, cache: false })
    @ownedClassrooms = new Classrooms()
    @ownedClassrooms.fetchMine({data: {project: '_id'}})
    @supermodel.trackCollection(@ownedClassrooms)
    @supermodel.addPromiseResource(store.dispatch('courses/fetch'))
    @store = store
    @originalLevelMap = {}
    @urls = require('core/urls')

    if me.get('role') is 'student'
      @hasActiveTournaments = false
      tournaments = new CocoCollection([], { url: "/db/tournaments?memberId=#{me.id}", model: Tournament})
      @listenToOnce tournaments, 'sync', =>
        tournamentsByClass = (t.toJSON() for t in tournaments.models)[0]
        tournaments = _.flatten _.values tournamentsByClass
        @hasActiveTournaments = _.some tournaments, (t) =>
          t.state in ['starting', 'active']
        @renderSelectors('#tournament-btn')
      @supermodel.loadCollection(tournaments, 'tournaments', {cache: false})

    # TODO: Trim this section for only what's necessary
    @hero = new ThangType
    defaultHeroOriginal = ThangType.heroes.captain
    heroOriginal = me.get('heroConfig')?.thangType or defaultHeroOriginal
    @hero.url = "/db/thang.type/#{heroOriginal}/version"
    # @hero.setProjection ['name','slug','soundTriggers','featureImages','gems','heroClass','description','components','extendedName','shortName','unlockLevelName','i18n']
    @supermodel.loadModel(@hero, 'hero')
    @listenTo @hero, 'change', -> @renderSelectors('.current-hero') if @supermodel.finished()
    @loadAILeagueStats()

  loadAILeagueStats: ->
    @randomAILeagueBannerHero = _.sample ['anya', 'ida', 'okar']
    @aiLeagueStats ?= {}
    age = utils.ageToBracket me.age()
    @ageBracketDisplay = $.i18n.t "ladder.bracket_#{(age ? 'open').replace(/-/g, '_')}"

    fetches = []
    if me.get('clans')?.length
      fetches.push clansApi.getMyClans()

    myArenaSessionsCollections = {}
    @activeArenas = utils.activeArenas()
    for arena in @activeArenas
      arena.ended = new Date() > arena.end
      myArenaSessionsCollections[arena.levelOriginal] = sessions = new LevelSessions()
      fetches.push sessions.fetchForLevelSlug arena.slug

    Promise.all(fetches).then (results) =>
      return if @destroyed
      if me.get('clans')?.length
        @myClans = @removeRedundantClans results.shift()  # Generic Objects, not Clan models
        for clan in @myClans when clan.displayName and not /a-z/.test(clan.displayName)
          clan.displayName = utils.titleize clan.displayName  # Convert any all-uppercase clan names to title-case
      else
        @myClans = []
      @myArenaSessions = {}
      for levelOriginal, sessionsCollection of myArenaSessionsCollections
        if session = sessionsCollection.models[0]  # Should only be zero or one; pick first one if multiple
          @myArenaSessions[levelOriginal] = session

      for clan in [null].concat @myClans
        continue if clan and clan.members?.length <= 1  # Skip one-person clans to reduce fetches and useless data.
        do (clan) =>
          # TODO: differentiate codePoints by age once more users have age set
          leaderboardApi.getCodePointsPlayerCount(clan?._id, {}).then (count) =>
            return if @destroyed
            @setAILeagueStat 'codePoints', clan?._id ? '_global', 'playerCount', count
            @sortMyClans()
          if me.get('stats')?.codePoints
            leaderboardApi.getCodePointsRankForUser(clan?._id, me.get('_id'), {}).then (rank) =>
              return if @destroyed
              @setAILeagueStat 'codePoints', clan?._id ? '_global', 'rank', rank
          for arena in @activeArenas
            session = @myArenaSessions[arena.levelOriginal]
            do (arena, session) =>
              leaderboardApi.getLeaderboardPlayerCount(arena.levelOriginal, {'leagues.leagueID': clan?._id, age}).then (count) =>
                return if @destroyed
                @setAILeagueStat 'arenas', arena.levelOriginal, clan?._id ? '_global', 'playerCount', count
              if session?.get('totalScore')?
                if clan
                  @setAILeagueStat 'arenas', arena.levelOriginal, clan._id, 'score', _.find(session.get('leagues'), (l) -> l.leagueID is clan._id)?.stats?.totalScore
                else
                  @setAILeagueStat 'arenas', arena.levelOriginal, '_global', 'score', session.get('totalScore')
                leaderboardApi.getMyRank(arena.levelOriginal, session.get('_id'), {'leagues.leagueID': clan?._id, age}).then (rank) =>
                  return if @destroyed
                  @setAILeagueStat 'arenas', arena.levelOriginal, clan?._id ? '_global', 'rank', rank

  setAILeagueStat: (keys..., val) ->
    # Convenience method for setting nested properties even if intermediate objects haven't been initialized
    object = @aiLeagueStats
    finalKey = keys.pop()
    for key in keys
      object[key] ?= {}
      object = object[key]
    if finalKey in ['rank', 'playerCount']
      val = if val is 'unknown' then null else parseInt val, 10
    object[finalKey] = val
    (@renderStatsDebounced ?= _.debounce @renderStats, 250)()
    val

  getAILeagueStat: (keys...) ->
    val = @aiLeagueStats
    for key in keys
      val = val?[key]
      return null unless val?
    val

  renderStats: =>
    return if @destroyed
    @renderSelectors('.student-stats', '.school-stats')

  removeRedundantClans: (clans) ->
    # Don't show low-level clans that have same members as higher-level clans (ex.: the class for a teacher with one class)
    relevantClans = []
    clansByMembers = _.groupBy clans, (c) -> (c.members ? []).sort().join(',')
    kindHierarchy = ['school-network', 'school-subnetwork', 'district', 'school', 'teacher', 'class']
    for members, clans of clansByMembers
      relevantClans.push _.sortBy(clans, (c) -> kindHierarchy.indexOf(c.kind))[0]
    relevantClans

  sortMyClans: ->
    @myClans = _.sortBy @myClans, (clan) =>
      playerCount = @getAILeagueStat('codePoints', clan._id, 'playerCount') ? 0
      -playerCount

  shouldEmphasizeAILeague: ->
    return true if _.size @myArenaSessions
    return true if me.isRegisteredForAILeague()
    return true if me.get('stats')?.gamesCompleted >= 6
    return true if (me.get('courseInstances') ? []).length is 0
    return true if @nextLevelInfo?.locked
    false

  afterInsert: ->
    super()
    unless me.isStudent() or (@classCodeQueryVar and not me.isTeacher())
      @onClassLoadError()

  onCourseInstancesLoaded: ->
    # HoC 2015 used special single player course instances
    @courseInstances.remove(@courseInstances.where({hourOfCode: true}))

    for courseInstance in @courseInstances.models
      continue if not courseInstance.get('classroomID')
      courseID = courseInstance.get('courseID')
      courseInstance.sessions = new CocoCollection([], {
        url: courseInstance.url() + '/course-level-sessions/' + me.id,
        model: LevelSession
      })
      courseInstance.sessions.comparator = 'changed'
      @supermodel.loadCollection(courseInstance.sessions, { data: { project: 'state.complete,level.original,playtime,changed' }})

  onLoaded: ->
    super()
    if @classCodeQueryVar and not me.isAnonymous()
      window.tracker?.trackEvent 'Students Join Class Link', category: 'Students', classCode: @classCodeQueryVar, ['Mixpanel']
      @joinClass()
    else if @classCodeQueryVar and me.isAnonymous()
      @openModalView(new CreateAccountModal())
    ownerIDs = _.map(@classrooms.models, (c) -> c.get('ownerID')) ? []
    Promise.resolve($.ajax(NameLoader.loadNames(ownerIDs)))
    .then(=>
      @ownerNameMap = {}
      @ownerNameMap[ownerID] = NameLoader.getName(ownerID) for ownerID in ownerIDs
      @render?()
    )

    if not @classrooms.models.length
      @nextLevelInfo = courseAcronym: 'CS1'  # Don't both trying to figure out the next level for edge case of student with no classrooms
      @allCompleted = false
      return

    @allCompleted = not _.some @classrooms.models, ((classroom) ->
      _.some @courseInstances.where({classroomID: classroom.id}), ((courseInstance) ->
        course = @store.state.courses.byId[courseInstance.get('courseID')]
        stats = classroom.statsForSessions(courseInstance.sessions, course._id)
        if stats.levels?.next
          # This could be made smarter than just picking the next level from the first incomplete course
          # It will suggest redoing a course arena level, like Wakka Maul, if all courses are complete
          @nextLevelInfo =
            level: stats.levels.next
            courseInstance: courseInstance
            course: course
            courseAcronym: utils.courseAcronyms[course._id]
            number: stats.levels.nextNumber
          if startLockedLevelSlug = courseInstance.get 'startLockedLevel'
            courseLevels = classroom.getLevels courseID: course._id
            hasLocked = false
            for level in courseLevels.models
              if level.get('slug') is startLockedLevelSlug
                hasLocked = true
              if level.get('slug') is @nextLevelInfo.level.get('slug')
                @nextLevelInfo.locked = true if hasLocked
                break
        not stats.courseComplete
        ), this
      ), this

    _.forEach _.unique(_.pluck(@classrooms.models, 'id')), (classroomID) =>
      levels = new Levels()
      @listenTo levels, 'sync', =>
        return if @destroyed
        @originalLevelMap[level.get('original')] = level for level in levels.models
        @render()
      @supermodel.trackRequest(levels.fetchForClassroom(classroomID, { data: { project: "original,primerLanguage,slug,name,i18n.#{me.get('preferredLanguage', true)}" }}))

  courseInstanceHasProject: (courseInstance) ->
    classroom = @classrooms.get(courseInstance.get('classroomID'))
    versionedCourse = _.find(classroom.get('courses'), {_id: courseInstance.get('courseID')})
    levels = versionedCourse.levels
    _.any(levels, { shareable: 'project' })

  showVideosLinkForCourse: (courseId) ->
    courseId == utils.courseIDs.INTRODUCTION_TO_COMPUTER_SCIENCE

  onClickLogInButton: ->
    modal = new AuthModal()
    @openModalView(modal)
    window.tracker?.trackEvent 'Students Login Started', category: 'Students', ['Mixpanel']

  openSignUpModal: ->
    window.tracker?.trackEvent 'Students Signup Started', category: 'Students', ['Mixpanel']
    modal = new CreateAccountModal({ initialValues: { classCode: utils.getQueryVariable('_cc', "") } })
    @openModalView(modal)

  onClickChangeHeroButton: ->
    window.tracker?.trackEvent 'Students Change Hero Started', category: 'Students', ['Mixpanel']
    modal = new HeroSelectModal({ currentHeroID: @hero.id })
    @openModalView(modal)
    @listenTo modal, 'hero-select:success', (newHero) =>
      # @hero.url = "/db/thang.type/#{me.get('heroConfig').thangType}/version"
      # @hero.fetch()
      @hero.set(newHero.attributes)
    @listenTo modal, 'hide', ->
      @stopListening modal

  onSubmitJoinClassForm: (e) ->
    e.preventDefault()
    classCode = @$('#class-code-input').val() or @classCodeQueryVar
    window.tracker?.trackEvent 'Students Join Class With Code', category: 'Students', classCode: classCode, ['Mixpanel']
    @joinClass()

  onClickJoinClassButton: (e) ->
    classCode = @$('#class-code-input').val() or @classCodeQueryVar
    window.tracker?.trackEvent 'Students Join Class With Code', category: 'Students', classCode: classCode, ['Mixpanel']
    @joinClass()

  joinClass: ->
    return if @state
    @state = 'enrolling'
    @errorMessage = null
    @classCode = @$('#class-code-input').val() or @classCodeQueryVar
    if not @classCode
      @state = null
      @errorMessage = 'Please enter a code.'
      @renderSelectors '#join-class-form'
      return
    @renderSelectors '#join-class-form'
    if me.get('emailVerified') or me.isStudent()
      newClassroom = new Classroom()
      jqxhr = newClassroom.joinWithCode(@classCode)
      @listenTo newClassroom, 'join:success', -> @onJoinClassroomSuccess(newClassroom)
      @listenTo newClassroom, 'join:error', -> @onJoinClassroomError(newClassroom, jqxhr)
    else
      modal = new JoinClassModal({ @classCode })
      @openModalView modal
      @listenTo modal, 'error', @onClassLoadError
      @listenTo modal, 'join:success', @onJoinClassroomSuccess
      @listenTo modal, 'join:error', @onJoinClassroomError
      @listenToOnce modal, 'hidden', ->
        unless me.isStudent()
          @onClassLoadError()
      @listenTo modal, 'hidden', ->
        @state = null
        @renderSelectors '#join-class-form'

  # Super hacky way to patch users being able to join class while hiding /students from others
  onClassLoadError: ->
    _.defer ->
      application.router.routeDirectly('courses/RestrictedToStudentsView')

  onJoinClassroomError: (classroom, jqxhr, options) ->
    @state = null
    if jqxhr.status is 422
      @errorMessage = 'Please enter a code.'
    else if jqxhr.status is 404
      @errorMessage = $.t('signup.classroom_not_found')
    else
      @errorMessage = "#{jqxhr.responseText}"
    @renderSelectors '#join-class-form'

  onJoinClassroomSuccess: (newClassroom, data, options) ->
    @state = null
    application.tracker?.trackEvent 'Joined classroom', {
      category: 'Courses'
      classCode: @classCode
      classroomID: newClassroom.id
      classroomName: newClassroom.get('name')
      ownerID: newClassroom.get('ownerID')
    }
    @classrooms.add(newClassroom)
    @render()
    @classroomJustAdded = newClassroom.id

    classroomCourseInstances = new CocoCollection([], { url: "/db/course_instance", model: CourseInstance })
    classroomCourseInstances.fetch({ data: {classroomID: newClassroom.id} })
    @listenToOnce classroomCourseInstances, 'sync', ->
      # TODO: Smoother system for joining a classroom and course instances, without requiring page reload,
      # and showing which class was just joined.
      document.location.search = '' # Using document.location.reload() causes an infinite loop of reloading

  nextLevelUrl: ->
    return null unless @nextLevelInfo
    return '/play/intro' unless @nextLevelInfo.level
    urlFn = if @nextLevelInfo.level.isLadder() then @urls.courseArenaLadder else @urls.courseLevel
    urlFn level: @originalLevelMap[@nextLevelInfo.level.get('original')] or @nextLevelInfo.level, courseInstance: @nextLevelInfo.courseInstance

  onClickPlayNextLevel: (e) ->
    if @nextLevelInfo?.locked
      return noty text: $.i18n.t('courses.ask_teacher_to_unlock_instructions'), timeout: 5000, type: 'warning', layout: 'topCenter', killer: true
    url = @nextLevelUrl()
    window.tracker?.trackEvent 'Students Play Next Level', category: 'Students', levelSlug: @nextLevelInfo.level?.get('slug'), ['Mixpanel']
    application.router.navigate(url, { trigger: true })

  onClickPlay: (e) ->
    levelSlug = $(e.currentTarget).data('level-slug')
    window.tracker?.trackEvent $(e.currentTarget).data('event-action'), category: 'Students', levelSlug: levelSlug, ['Mixpanel']
    application.router.navigate($(e.currentTarget).data('href'), { trigger: true })

  onClickViewClass: (e) ->
    classroomID = $(e.target).data('classroom-id')
    window.tracker?.trackEvent 'Students View Class', category: 'Students', classroomID: classroomID, ['Mixpanel']
    application.router.navigate("/students/#{classroomID}", { trigger: true })

  onClickViewLevels: (e) ->
    courseID = $(e.target).data('course-id')
    courseInstanceID = $(e.target).data('courseinstance-id')
    window.tracker?.trackEvent 'Students View Levels', category: 'Students', courseID: courseID, courseInstanceID: courseInstanceID, ['Mixpanel']
    course = store.state.courses.byId[courseID]
    courseInstance = @courseInstances.get(courseInstanceID)
    levelsUrl = @urls.courseWorldMap({course, courseInstance})
    application.router.navigate(levelsUrl, { trigger: true })

  onClickViewProjectGalleryLink: (e) ->
    courseID = $(e.target).data('course-id')
    courseInstanceID = $(e.target).data('courseinstance-id')
    window.tracker?.trackEvent 'Students View To Project Gallery View', category: 'Students', courseID: courseID, courseInstanceID: courseInstanceID, ['Mixpanel']
    application.router.navigate("/students/project-gallery/#{courseInstanceID}", { trigger: true })

  onClickViewChallengesLink: (e) ->
    classroomID = $(e.target).data('classroom-id')
    courseID = $(e.target).data('course-id')
    window.tracker?.trackEvent 'Students View To Student Assessments View', category: 'Students', classroomID: classroomID, ['Mixpanel']
    application.router.navigate("/students/assessments/#{classroomID}##{courseID}", { trigger: true })

  onClickViewVideosLink: (e) ->
    classroomID = $(e.target).data('classroom-id')
    courseID = $(e.target).data('course-id')
    courseName = $(e.target).data('course-name')
    window.tracker?.trackEvent 'Students View To Videos View', category: 'Students', courseID: courseID, classroomID: classroomID, ['Mixpanel']
    application.router.navigate("/students/videos/#{courseID}/#{courseName}", { trigger: true })

  onClickAnnouncementLink: (e) ->
    classroomId = $(e.target).data('classroom-id')
    classroom = _.find @classrooms.models, { 'id': classroomId }
    modal = new ClassroomAnnouncementModal({ announcement: classroom.get('description')})
    @openModalView modal

  nextLevelImage: ->
    # Prioritize first by level-specific, then course-specific and hero-specific together
    return @_nextLevelImage if @_nextLevelImage
    return unless course = @nextLevelInfo?.courseAcronym
    return unless hero = @hero.get('slug')
    level = @nextLevelInfo?.level?.get 'slug'
    levelChoices = []
    courseChoices = []
    heroChoices = []
    for image, criteria of nextLevelBannerImages
      levelChoices.push image if level in (criteria.levels ? [])
      courseChoices.push image if course in (criteria.courses ? [])
      heroChoices.push image if hero in (criteria.heroes ? [])
    image = _.sample(levelChoices) or _.sample(heroChoices.concat(courseChoices))
    @_nextLevelImage = '/images/pages/courses/banners/' + image

nextLevelBannerImages = {
  'arena-ace-of-coders.png': {heroes: ['goliath'], courses: ['CS5', 'CS6']}
  'arena-cavern-survival.png': {heroes: ['knight', 'master-wizard'], courses: ['CS1']}
  'arena-dueling-grounds.png': {heroes: ['raider', 'necromancer'], courses: ['CS2', 'CS3', 'GD1', 'GD2']}
  'arena-gold-rush.png': {heroes: ['knight'], courses: ['CS2', 'CS3', 'GD1', 'GD2']}
  'arena-greed.png': {courses: ['CS2', 'CS3', 'GD1', 'GD2']}
  'arena-harrowlands.png': {heroes: ['ninja', 'forest-archer'], courses: ['CS3', 'CS4', 'GD3']}
  'arena-sky-span.png': {courses: ['CS4', 'CS5', 'CS6']}
  'arena-summation-summit.png': {levels: ['summation-summit']}
  'arena-treasure-grove.png': {heroes: ['samurai', 'trapper'], courses: ['CS2', 'CS3', 'GD1', 'GD2']}
  'arena-wakka-maul-dynamic.png': {levels: ['wakka-maul']}
  #'arena-wakka-maul.png': {levels: ['wakka-maul']}
  'battle-anya.png': {heroes: ['captain']}
  'battle-tharin-ogre.png': {heroes: ['knight']}
  'battle-tharin.png': {heroes: ['knight']}
  'contributor-adventurer.png': {courses: ['CS1']}
  'contributor-ambassador.png': {courses: ['CS2', 'CS3', 'CS4', 'CS5', 'CS6', 'GD1', 'GD2', 'GD3']}
  'contributor-archmage.png': {courses: ['CS2', 'CS3', 'CS4', 'CS5', 'CS6', 'GD1', 'GD2', 'GD3']}
  'contributor-artisan.png': {courses: ['CS2', 'CS3', 'GD1', 'GD2', 'WD1', 'WD2']}
  'contributor-diplomat.png': {courses: ['WD1', 'WD2']}
  'contributor-scribe.png': {courses: ['WD1', 'WD2']}
  'desert-omarn.png': {heroes: ['potion-master'], courses: ['CS3', 'CS4', 'GD3']}
  'dungeon-heroes.png': {heroes: ['samurai', 'ninja', 'librarian'], courses: ['CS1']}
  'forest-alejandro.png': {heroes: ['duelist'], courses: ['CS2', 'CS3', 'GD1', 'GD2']}
  'forest-anya.png': {heroes: ['captain'], courses: ['CS2', 'CS3', 'GD1', 'GD2']}
  'forest-heroes.png': {heroes: ['trapper', 'potion-master', 'forest-archer'], courses: ['CS2', 'CS3', 'GD1', 'GD2']}
  'forest-hunting.png': {heroes: ['forest-archer'], courses: ['CS2', 'CS3', 'GD1', 'GD2']}
  'forest-pets.png': {courses: ['CS2', 'CS3', 'GD1', 'GD2'], levels: ['backwoods-buddy', 'buddys-name', 'buddys-name-a', 'buddys-name-b', 'phd-kitty', 'pet-quiz', 'timely-word', 'go-fetch', 'guard-dog', 'fast-and-furry-ous', 'chain-of-command', 'pet-engineer', 'pet-translator', 'pet-adjutant', 'alchemic-power', 'dangerous-key']}
  'game-dev.png': {courses: ['GD1', 'GD2', 'GD3']}
  'heroes-vs-ogres.png': {heroes: ['raider', 'champion', 'captain', 'ninja'], courses: ['CS1', 'CS2', 'CS3', 'CS4', 'CS5', 'CS6', 'GD1', 'GD2', 'GD3']}
  'mountain-heroes.png': {heroes: ['goliath', 'guardian', 'knight', 'stalwart', 'duelist'], courses: ['CS4', 'CS5', 'CS6']}
  'wizard-heroes.png': {heroes: ['potion-master', 'master-wizard', 'librarian', 'sorcerer', 'necromancer'], courses: ['CS1'], levels: ['the-wizards-door', 'the-wizards-haunt', 'the-wizards-plane']}
}
