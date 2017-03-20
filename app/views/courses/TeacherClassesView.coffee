RootView = require 'views/core/RootView'
template = require 'templates/courses/teacher-classes-view'
Classroom = require 'models/Classroom'
Classrooms = require 'collections/Classrooms'
Courses = require 'collections/Courses'
Campaign = require 'models/Campaign'
Campaigns = require 'collections/Campaigns'
LevelSessions = require 'collections/LevelSessions'
CourseInstance = require 'models/CourseInstance'
CourseInstances = require 'collections/CourseInstances'
ClassroomSettingsModal = require 'views/courses/ClassroomSettingsModal'
CourseNagSubview = require 'views/teachers/CourseNagSubview'
InviteToClassroomModal = require 'views/courses/InviteToClassroomModal'
User = require 'models/User'
utils = require 'core/utils'
helper = require 'lib/coursesHelper'

module.exports = class TeacherClassesView extends RootView
  id: 'teacher-classes-view'
  template: template
  helper: helper

  # TODO: where to track/save this data?
  teacherQuestData:
    'create_classroom':
      title: $.i18n.t('teacher.teacher_quest_create_classroom')
      complete: false
    'add_students':
      title: $.i18n.t('teacher.teacher_quest_add_students')
      complete: false
    'teach_methods':
      title: $.i18n.t('teacher.teacher_quest_teach_methods')
      complete: false
      steps: [
        $.i18n.t('teacher.teacher_quest_teach_methods_step1')
      ]
    'teach_strings':
      title: $.i18n.t('teacher.teacher_quest_teach_strings')
      complete: false
      steps: [
        $.i18n.t('teacher.teacher_quest_teach_strings_step1')
      ]
    'teach_loops':
      title: $.i18n.t('teacher.teacher_quest_teach_loops')
      complete: false
      steps: [
        $.i18n.t('teacher.teacher_quest_teach_loops_step1')
      ]
    'teach_variables':
      title: $.i18n.t('teacher.teacher_quest_teach_variables')
      complete: false
      steps: [
        $.i18n.t('teacher.teacher_quest_teach_variables_step1')
      ]
    'kithgard_gates_100':
      title: $.i18n.t('teacher.teacher_quest_kithgard_gates_100')
      complete: false
      steps: [
        $.i18n.t('teacher.teacher_quest_kithgard_gates_100_step1')
      ]
    'wakka_maul_100':
      title: $.i18n.t('teacher.teacher_quest_wakka_maul_100')
      complete: false
      steps: [
        $.i18n.t('teacher.teacher_quest_wakka_maul_100_step1')
      ]
    'reach_gamedev':
      title: $.i18n.t('teacher.teacher_quest_reach_gamedev')
      complete: false
      steps: [
        $.i18n.t('teacher.teacher_quest_reach_gamedev_step1')
      ]

  events:
    'click .edit-classroom': 'onClickEditClassroom'
    'click .archive-classroom': 'onClickArchiveClassroom'
    'click .unarchive-classroom': 'onClickUnarchiveClassroom'
    'click .add-students-btn': 'onClickAddStudentsButton'
    'click .create-classroom-btn': 'onClickCreateClassroomButton'
    'click .create-teacher-btn': 'onClickCreateTeacherButton'
    'click .update-teacher-btn': 'onClickUpdateTeacherButton'
    'click .view-class-btn': 'onClickViewClassButton'
    'click .see-all-quests': 'onClickSeeAllQuests'

  getTitle: -> return $.i18n.t('teacher.my_classes')

  initialize: (options) ->
    super(options)
    @teacherID = (me.isAdmin() and utils.getQueryVariable('teacherID')) or me.id
    @classrooms = new Classrooms()
    @classrooms.comparator = (a, b) -> b.id.localeCompare(a.id)
    @classrooms.fetchByOwner(@teacherID)
    @supermodel.trackCollection(@classrooms)
    @listenTo @classrooms, 'sync', ->
      for classroom in @classrooms.models
        classroom.sessions = new LevelSessions()
        jqxhrs = classroom.sessions.fetchForAllClassroomMembers(classroom)
        if jqxhrs.length > 0
          @supermodel.trackRequests(jqxhrs)
    window.tracker?.trackEvent 'Teachers Classes Loaded', category: 'Teachers', ['Mixpanel']

    @courses = new Courses()
    @courses.fetch()
    @supermodel.trackCollection(@courses)

    @courseInstances = new CourseInstances()
    @courseInstances.fetchByOwner(@teacherID)
    @supermodel.trackCollection(@courseInstances)
    @progressDotTemplate = require 'templates/teachers/hovers/progress-dot-whole-course'

    # Level Sessions loaded after onLoaded to prevent race condition in calculateDots

  afterRender: ->
    super()
    @courseNagSubview = new CourseNagSubview()
    @insertSubView(@courseNagSubview)
    $('.progress-dot').each (i, el) ->
      dot = $(el)
      dot.tooltip({
        html: true
        container: dot
      })

  onLoaded: ->
    helper.calculateDots(@classrooms, @courses, @courseInstances)

    @teacherQuestData['create_classroom'].complete = @classrooms.length > 0
    for classroom in @classrooms.models
      continue unless classroom.get('members')?.length > 0
      @teacherQuestData['add_students'].complete = true
      kithgardGatesCompletes = 0
      wakkaMaulCompletes = 0
      for session in classroom.sessions.models
        if session.get('level')?.original is '541c9a30c6362edfb0f34479' # kithgard-gates
          kithgardGatesCompletes++
        continue unless session.get('state')?.complete
        if session.get('level')?.original is '5411cb3769152f1707be029c' # dungeons-of-kithgard
          @teacherQuestData['teach_methods'].complete = true
        if session.get('level')?.original is '541875da4c16460000ab990f' # true-names
          @teacherQuestData['teach_strings'].complete = true
        if session.get('level')?.original is '55ca293b9bc1892c835b0136' # fire-dancing
          @teacherQuestData['teach_loops'].complete = true
        if session.get('level')?.original is '5452adea57e83800009730ee' # known-enemy
          @teacherQuestData['teach_variables'].complete = true
        if session.get('level')?.original is '5630eab0c0fcbd86057cc2f8' # wakka-maul
          wakkaMaulCompletes++
      if kithgardGatesCompletes is classroom.get('members')?.length
        @teacherQuestData['kithgard_gates_100'].complete = true
      if wakkaMaulCompletes is classroom.get('members')?.length
        @teacherQuestData['wakka_maul_100'].complete = true
    # TODO: sort teacher quest data to be completes followed incompletes

    super()

  onClickEditClassroom: (e) ->
    classroomID = $(e.target).data('classroom-id')
    window.tracker?.trackEvent $(e.target).data('event-action'), category: 'Teachers', classroomID: classroomID, ['Mixpanel']
    classroom = @classrooms.get(classroomID)
    modal = new ClassroomSettingsModal({ classroom: classroom })
    @openModalView(modal)
    @listenToOnce modal, 'hide', @render

  onClickCreateClassroomButton: (e) ->
    return unless me.id is @teacherID # Viewing page as admin
    window.tracker?.trackEvent 'Teachers Classes Create New Class Started', category: 'Teachers', ['Mixpanel']
    classroom = new Classroom({ ownerID: me.id })
    modal = new ClassroomSettingsModal({ classroom: classroom })
    @openModalView(modal)
    @listenToOnce modal.classroom, 'sync', ->
      window.tracker?.trackEvent 'Teachers Classes Create New Class Finished', category: 'Teachers', ['Mixpanel']
      @classrooms.add(modal.classroom)
      @addFreeCourseInstances()
      @render()

  onClickCreateTeacherButton: (e) ->
    window.tracker?.trackEvent $(e.target).data('event-action'), category: 'Teachers', ['Mixpanel']
    application.router.navigate("/teachers/signup", { trigger: true })

  onClickUpdateTeacherButton: (e) ->
    window.tracker?.trackEvent $(e.target).data('event-action'), category: 'Teachers', ['Mixpanel']
    application.router.navigate("/teachers/update-account", { trigger: true })

  onClickAddStudentsButton: (e) ->
    window.tracker?.trackEvent 'Teachers Classes Add Students Started', category: 'Teachers', ['Mixpanel']
    classroomID = $(e.currentTarget).data('classroom-id')
    classroom = @classrooms.get(classroomID)
    modal = new InviteToClassroomModal({ classroom: classroom })
    @openModalView(modal)
    @listenToOnce modal, 'hide', @render

  onClickArchiveClassroom: (e) ->
    return unless me.id is @teacherID # Viewing page as admin
    classroomID = $(e.currentTarget).data('classroom-id')
    classroom = @classrooms.get(classroomID)
    classroom.set('archived', true)
    classroom.save {}, {
      success: =>
        window.tracker?.trackEvent 'Teachers Classes Archived Class', category: 'Teachers', ['Mixpanel']
        @render()
    }

  onClickUnarchiveClassroom: (e) ->
    return unless me.id is @teacherID # Viewing page as admin
    classroomID = $(e.currentTarget).data('classroom-id')
    classroom = @classrooms.get(classroomID)
    classroom.set('archived', false)
    classroom.save {}, {
      success: =>
        window.tracker?.trackEvent 'Teachers Classes Unarchived Class', category: 'Teachers', ['Mixpanel']
        @render()
    }

  onClickViewClassButton: (e) ->
    classroomID = $(e.target).data('classroom-id')
    window.tracker?.trackEvent $(e.target).data('event-action'), category: 'Teachers', classroomID: classroomID, ['Mixpanel']
    application.router.navigate("/teachers/classes/#{classroomID}", { trigger: true })

  addFreeCourseInstances: ->
    # so that when students join the classroom, they can automatically get free courses
    # non-free courses are generated when the teacher first adds a student to them
    for classroom in @classrooms.models
      for course in @courses.models
        continue if not course.get('free')
        courseInstance = @courseInstances.findWhere({classroomID: classroom.id, courseID: course.id})
        if not courseInstance
          courseInstance = new CourseInstance({
            classroomID: classroom.id
            courseID: course.id
          })
          # TODO: figure out a better way to get around triggering validation errors for properties
          # that the server will end up filling in, like an empty members array, ownerID
          courseInstance.save(null, {validate: false})
          @courseInstances.add(courseInstance)
          @listenToOnce courseInstance, 'sync', @addFreeCourseInstances
          return

  onClickSeeAllQuests: (e) ->
    $(e.target).addClass('hide')
    $('.quest-complete,.quest-incomplete').removeClass('hide')
