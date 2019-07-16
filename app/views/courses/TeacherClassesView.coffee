require('app/styles/courses/teacher-classes-view.sass')
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
Prepaids = require 'collections/Prepaids'
Users = require 'collections/Users'
User = require 'models/User'
utils = require 'core/utils'
storage = require 'core/storage'
GoogleClassroomHandler = require('core/social-handlers/GoogleClassroomHandler')
co = require('co')

helper = require 'lib/coursesHelper'

translateWithMarkdown = (label) ->
  marked.inlineLexer $.i18n.t(label), []

# TODO: if this proves useful, make a simple admin page with a Treema for editing office hours in db
officeHours = [
  {time: moment('2018-02-28 12:00-08').toDate(), link: 'https://zoom.us/meeting/register/307c335ddb1ee6ef7510d14dfea9e911', host: 'David', name: 'CodeCombat for Beginner Teachers'}
  {time: moment('2018-03-07 12:00-08').toDate(), link: 'https://zoom.us/meeting/register/a1a6f5f4eb7a0a387c24e00bf0acd2b8', host: 'Nolan', name: 'CodeCombat: Beyond Block-Based Coding'}
  {time: moment('2018-03-15 12:30-08').toDate(), link: 'https://zoom.us/meeting/register/16f0a6b4122087667c24e00bf0acd2b8', host: 'Sean', name: 'Building Student Engagement with CodeCombat'}
  {time: moment('2018-03-21 12:00-08').toDate(), link: 'https://zoom.us/meeting/register/4e7eb093f8689e21c5b9141539e44ee6', host: 'Liz', name: 'CodeCombat for Beginner Teachers'}
]

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
    'click .create-classroom-btn': 'openNewClassroomModal'
    'click .create-teacher-btn': 'onClickCreateTeacherButton'
    'click .update-teacher-btn': 'onClickUpdateTeacherButton'
    'click .view-class-btn': 'onClickViewClassButton'
    'click .see-all-quests': 'onClickSeeAllQuests'
    'click .see-less-quests': 'onClickSeeLessQuests'
    'click .see-all-office-hours': 'onClickSeeAllOfficeHours'
    'click .see-less-office-hours': 'onClickSeeLessOfficeHours'
    'click .see-no-office-hours': 'onClickSeeNoOfficeHours'

  getMeta: ->
    {
      title: $.i18n.t 'teacher.my_classes'
    }

  initialize: (options) ->
    super(options)
    @teacherID = (me.isAdmin() and utils.getQueryVariable('teacherID')) or me.id
    @classrooms = new Classrooms()
    @classrooms.comparator = (a, b) -> b.id.localeCompare(a.id)
    @classrooms.fetchByOwner(@teacherID)
    @supermodel.trackCollection(@classrooms)
    @listenTo @classrooms, 'sync', ->
      for classroom in @classrooms.models
        continue if classroom.get('archived')
        classroom.sessions = new LevelSessions()
        Promise.all(classroom.sessions.fetchForAllClassroomMembers(
          classroom,
          {
            data: {
              project: 'state.complete,level,creator,changed,created,dateFirstCompleted,submitted,codeConcepts'
            }
          }
        ))
        .then (results) =>
          return if @destroyed
          helper.calculateDots(@classrooms, @courses, @courseInstances)
          @calculateQuestCompletion()
          @render()

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

    earliestHourTime = new Date() - 60 * 60 * 1000
    latestHourTime = new Date() - -21 * 24 * 60 * 60 * 1000
    @upcomingOfficeHours = _.sortBy (oh for oh in officeHours when earliestHourTime < oh.time < latestHourTime), 'time'
    @howManyOfficeHours = if storage.load('hide-office-hours') then 'none' else 'some'
    me.getClientCreatorPermissions()?.then(() =>
      @calculateQuestCompletion()
      @render?()
    )

    administratingTeacherIds = me.get('administratingTeachers') || []

    @administratingTeachers = new Users()
    if administratingTeacherIds.length > 0
      req = @administratingTeachers.fetchByIds(administratingTeacherIds)
      @supermodel.trackRequest req

    # TODO: Any reference to paidTeacher can be cleaned up post Teacher Appreciation week (after 2019-05-03)
    @paidTeacher = me.isAdmin() or me.isPaidTeacher()

    # Level Sessions loaded after onLoaded to prevent race condition in calculateDots

  afterRender: ->
    super()
    unless @courseNagSubview
      @courseNagSubview = new CourseNagSubview()
      @insertSubView(@courseNagSubview)
    $('.progress-dot').each (i, el) ->
      dot = $(el)
      dot.tooltip({
        html: true
        container: dot
      })

  calculateQuestCompletion: ->
    @teacherQuestData['create_classroom'].complete = @classrooms.length > 0
    for classroom in @classrooms.models
      continue unless classroom.get('members')?.length > 0 and classroom.sessions
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
      if @prepaids.length > 0 or !me.canManageLicensesViaUI()
        classCompletion['reach_gamedev'] = 1.0
      else
        classCompletion['reach_gamedev'] = 0.0

      @teacherQuestData[k].complete ||= v > 0.74 for k,v of classCompletion
      @teacherQuestData[k].best = Math.max(@teacherQuestData[k].best||0,v) for k,v of classCompletion

  onLoaded: ->
    helper.calculateDots(@classrooms, @courses, @courseInstances)
    @calculateQuestCompletion()
    @paidTeacher = @paidTeacher or @prepaids.find((p) => p.get('type') in ['course', 'starter_license'] and p.get('maxRedeemers') > 0)?

    if me.isTeacher() and not @classrooms.length
      @openNewClassroomModal()
    super()

  onClickEditClassroom: (e) ->
    classroomID = $(e.target).data('classroom-id')
    window.tracker?.trackEvent $(e.target).data('event-action'), category: 'Teachers', classroomID: classroomID, ['Mixpanel']
    classroom = @classrooms.get(classroomID)
    modal = new ClassroomSettingsModal({ classroom: classroom })
    @openModalView(modal)
    @listenToOnce modal, 'hide', ->
      @calculateQuestCompletion()
      @render()

  openNewClassroomModal: ->
    return unless me.id is @teacherID # Viewing page as admin
    window.tracker?.trackEvent 'Teachers Classes Create New Class Started', category: 'Teachers', ['Mixpanel']
    classroom = new Classroom({ ownerID: me.id })
    modal = new ClassroomSettingsModal({ classroom: classroom })
    @openModalView(modal)
    @listenToOnce modal.classroom, 'sync', ->
      window.tracker?.trackEvent 'Teachers Classes Create New Class Finished', category: 'Teachers', ['Mixpanel']
      @classrooms.add(modal.classroom)
      if modal.classroom.isGoogleClassroom()
        GoogleClassroomHandler.markAsImported(classroom.get("googleClassroomId")).then(() => @render()).catch((e) => console.error(e))
      classroom = modal.classroom
      @addFreeCourseInstances()
      .then(() =>
        if classroom.isGoogleClassroom()
          @importStudents(classroom)
          .then (importedStudents) =>
            @addImportedStudents(classroom, importedStudents)
          , (_e) => {}
      , (err) =>
        if classroom.isGoogleClassroom()
          noty text: 'Could not import students', layout: 'topCenter', timeout: 3000, type: 'error'
      )
      .then () =>
        @calculateQuestCompletion()
        @render()

  importStudents: (classroom) ->
    GoogleClassroomHandler.importStudentsToClassroom(classroom)
    .then (importedStudents) =>
      if importedStudents.length > 0
        console.debug("Students imported to classroom:", importedStudents)
        return Promise.resolve(importedStudents)
      else
        noty text: 'No new students imported', layout: 'topCenter', timeout: 3000, type: 'error'
        return Promise.reject()
    .catch (err) =>
      noty text: err or 'Error in importing students', layout: 'topCenter', timeout: 3000, type: 'error'
      return Promise.reject()

  # Add imported students to @classrooms and @courseInstances so that they are rendered on the screen
  addImportedStudents: (classroom, importedStudents) ->
    cl = @classrooms.models.find((c) => c.get("_id") == classroom.get("_id"))
    importedStudents.forEach((i) => cl.get("members").push(i._id))
    for course in @courses.models
      continue if not course.get('free')
      courseInstance = @courseInstances.findWhere({classroomID: classroom.id, courseID: course.id})
      if courseInstance
        importedStudents.forEach((i) => courseInstance.get("members").push(i._id))

  onClickCreateTeacherButton: (e) ->
    window.tracker?.trackEvent $(e.target).data('event-action'), category: 'Teachers', ['Mixpanel']
    application.router.navigate("/teachers/signup", { trigger: true })

  onClickUpdateTeacherButton: (e) ->
    window.tracker?.trackEvent $(e.target).data('event-action'), category: 'Teachers', ['Mixpanel']
    application.router.navigate("/teachers/update-account", { trigger: true })

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

  addFreeCourseInstances: co.wrap ->
    # so that when students join the classroom, they can automatically get free courses
    # non-free courses are generated when the teacher first adds a student to them
    try
      promises = []
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
            promises.push(new Promise(courseInstance.save(null, {validate: false}).then))
      if (promises.length > 0)
        courseInstances = yield Promise.all(promises)
        @courseInstances.add(courseInstances) if courseInstances.length > 0
      return
    catch e
      console.error("Error in adding free course instances")
      return Promise.reject()


  onClickSeeAllQuests: (e) =>
    $(e.target).hide()
    @$el.find('.see-less-quests').show()
    @$el.find('.quest.hide').addClass('hide-revealed').removeClass('hide')

  onClickSeeLessQuests: (e) =>
    $(e.target).hide()
    @$el.find('.see-all-quests').show()
    @$el.find('.quest.hide-revealed').addClass('hide').removeClass('hide-revealed')

  onClickSeeAllOfficeHours: (e) ->
    @howManyOfficeHours = 'all'
    @renderSelectors '#office-hours'

  onClickSeeLessOfficeHours: (e) ->
    @howManyOfficeHours = 'some'
    @renderSelectors '#office-hours'

  onClickSeeNoOfficeHours: (e) ->
    @howManyOfficeHours = 'none'
    @renderSelectors '#office-hours'
    storage.save 'hide-office-hours', true
