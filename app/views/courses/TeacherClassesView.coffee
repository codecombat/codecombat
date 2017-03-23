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
Prepaids = require 'collections/Prepaids'
User = require 'models/User'
utils = require 'core/utils'

helper = require 'lib/coursesHelper'

translateWithMarkdown = (label) ->
  marked.inlineLexer $.i18n.t(label), []

module.exports = class TeacherClassesView extends RootView
  id: 'teacher-classes-view'
  template: template
  helper: helper
  translateWithMarkdown: translateWithMarkdown

  # TODO: where to track/save this data?
  teacherQuestData:
    'create_classroom':
      title: translateWithMarkdown('teacher.teacher_quest_create_classroom')
    'add_students':
      title: translateWithMarkdown('teacher.teacher_quest_add_students')
    'teach_methods':
      title: translateWithMarkdown('teacher.teacher_quest_teach_methods')
      steps: [
        translateWithMarkdown('teacher.teacher_quest_teach_methods_step1')
        translateWithMarkdown('teacher.teacher_quest_teach_methods_step2')
      ]
    'teach_strings':
      title: translateWithMarkdown('teacher.teacher_quest_teach_strings')
      steps: [
        translateWithMarkdown('teacher.teacher_quest_teach_strings_step1')
        translateWithMarkdown('teacher.teacher_quest_teach_strings_step2')
      ]
    'teach_loops':
      title: translateWithMarkdown('teacher.teacher_quest_teach_loops')
      steps: [
        translateWithMarkdown('teacher.teacher_quest_teach_loops_step1')
        translateWithMarkdown('teacher.teacher_quest_teach_loops_step2')
      ]
    'teach_variables':
      title: translateWithMarkdown('teacher.teacher_quest_teach_variables')
      steps: [
        translateWithMarkdown('teacher.teacher_quest_teach_variables_step1')
        translateWithMarkdown('teacher.teacher_quest_teach_variables_step2')
      ]
    'kithgard_gates_100':
      title: translateWithMarkdown('teacher.teacher_quest_kithgard_gates_100')
      steps: [
        translateWithMarkdown('teacher.teacher_quest_kithgard_gates_100_step1')
        translateWithMarkdown('teacher.teacher_quest_kithgard_gates_100_step2')
      ]
    'wakka_maul_100':
      title: translateWithMarkdown('teacher.teacher_quest_wakka_maul_100')
      steps: [
        translateWithMarkdown('teacher.teacher_quest_wakka_maul_100_step1')
        translateWithMarkdown('teacher.teacher_quest_wakka_maul_100_step2')
      ]
    'reach_gamedev':
      title: translateWithMarkdown('teacher.teacher_quest_reach_gamedev')
      steps: [
        translateWithMarkdown('teacher.teacher_quest_reach_gamedev_step1')
      ]

  events:
    'click .edit-classroom': 'onClickEditClassroom'
    'click .archive-classroom': 'onClickArchiveClassroom'
    'click .unarchive-classroom': 'onClickUnarchiveClassroom'
    'click .add-students-btn': 'onClickAddStudentsButton'
    'click .create-classroom-btn': 'openNewClassroomModal'
    'click .create-teacher-btn': 'onClickCreateTeacherButton'
    'click .update-teacher-btn': 'onClickUpdateTeacherButton'
    'click .view-class-btn': 'onClickViewClassButton'
    'click .see-all-quests': 'onClickSeeAllQuests'
    'click .see-less-quests': 'onClickSeeLessQuests'

  getTitle: -> $.i18n.t 'teacher.my_classes'

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
    @prepaids = new Prepaids()
    @supermodel.trackRequest @prepaids.fetchByCreator(me.id)

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
      classCompletion = {}
      classCompletion[key] = 0 for key in Object.keys(@teacherQuestData)
      students = classroom.get('members')?.length

      
      kithgardGatesCompletes = 0
      wakkaMaulCompletes = 0
      for session in classroom.sessions.models
        if session.get('level')?.original is '541c9a30c6362edfb0f34479' # kithgard-gates
          ++classCompletion['kithgard_gates_100']
        if session.get('level')?.original is '5630eab0c0fcbd86057cc2f8' # wakka-maul
          ++classCompletion['wakka_maul_100']            
        continue unless session.get('state')?.complete
        if session.get('level')?.original is '5411cb3769152f1707be029c' # dungeons-of-kithgard
          ++classCompletion['teach_methods']
        if session.get('level')?.original is '541875da4c16460000ab990f' # true-names
          ++classCompletion['teach_strings']
        if session.get('level')?.original is '55ca293b9bc1892c835b0136' # fire-dancing
          ++classCompletion['teach_loops']
        if session.get('level')?.original is '5452adea57e83800009730ee' # known-enemy
          ++classCompletion['teach_variables']

      classCompletion[k] /= students for k of classCompletion
        


      classCompletion['add_students'] = if students > 0 then 1.0 else 0.0
      if me.get('enrollmentRequestSent') or @prepaids.length > 0
        classCompletion['reach_gamedev'] = 1.0
      else
        classCompletion['reach_gamedev'] = 0.0

      @teacherQuestData[k].complete ||= v > 0.74 for k,v of classCompletion
      @teacherQuestData[k].best = Math.max(@teacherQuestData[k].best||0,v) for k,v of classCompletion


    if me.isTeacher() and not @classrooms.length
      @openNewClassroomModal()
    super()

  onClickEditClassroom: (e) ->
    classroomID = $(e.target).data('classroom-id')
    window.tracker?.trackEvent $(e.target).data('event-action'), category: 'Teachers', classroomID: classroomID, ['Mixpanel']
    classroom = @classrooms.get(classroomID)
    modal = new ClassroomSettingsModal({ classroom: classroom })
    @openModalView(modal)
    @listenToOnce modal, 'hide', @render

  openNewClassroomModal: ->
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

  onClickSeeAllQuests: (e) =>
    $(e.target).hide()
    @$el.find('.see-less-quests').show()
    @$el.find('.quest.hide').addClass('hide-revealed').removeClass('hide')

  onClickSeeLessQuests: (e) =>
    $(e.target).hide()
    @$el.find('.see-all-quests').show()
    @$el.find('.quest.hide-revealed').addClass('hide').removeClass('hide-revealed')
