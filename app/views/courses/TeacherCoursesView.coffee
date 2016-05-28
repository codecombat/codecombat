ActivateLicensesModal = require 'views/courses/ActivateLicensesModal'
app = require 'core/application'
CocoCollection = require 'collections/CocoCollection'
CocoModel = require 'models/CocoModel'
Course = require 'models/Course'
Campaigns = require 'collections/Campaigns'
Classroom = require 'models/Classroom'
Classrooms = require 'collections/Classrooms'
InviteToClassroomModal = require 'views/courses/InviteToClassroomModal'
User = require 'models/User'
CourseInstance = require 'models/CourseInstance'
RootView = require 'views/core/RootView'
template = require 'templates/courses/teacher-courses-view'
ClassroomSettingsModal = require 'views/courses/ClassroomSettingsModal'

module.exports = class TeacherCoursesView extends RootView
  id: 'teacher-courses-view'
  template: template

  events:
    'click #activate-licenses-btn': 'onClickActivateLicensesButton'
    'click .btn-add-students': 'onClickAddStudents'
    'click .create-new-class': 'onClickCreateNewClassButton'
    'click .edit-classroom-small': 'onClickEditClassroomSmall'
    'click .play-level-button': 'onClickPlayLevel'
    
  guideLinks:
    {
      "560f1a9f22961295f9427742":
        python: 'http://files.codecombat.com/teacherguides/CodeCombat_TeacherGuide_intro_python.pdf'
        javascript: 'http://files.codecombat.com/teacherguides/CodeCombat_TeacherGuide_intro_javascript.pdf'
      "5632661322961295f9428638":
        python: 'http://files.codecombat.com/teacherguides/CodeCombat_TeacherGuide_course-2_python.pdf'
        javascript: 'http://files.codecombat.com/teacherguides/CodeCombat_TeacherGuide_course-2_javascript.pdf'
      "56462f935afde0c6fd30fc8c":
        python: 'http://files.codecombat.com/teacherguides/CodeCombat_TeacherGuide_course-3_python.pdf'
        javascript: 'http://files.codecombat.com/teacherguides/CodeCombat_TeacherGuide_course-3_javascript.pdf'
      "56462f935afde0c6fd30fc8d": null
      "569ed916efa72b0ced971447": null
    }

  getTitle: -> return $.i18n.t('teacher.courses')

  constructor: (options) ->
    super(options)
    @ownedClassrooms = new Classrooms()
    @ownedClassrooms.fetchMine({data: {project: '_id'}})
    @supermodel.trackCollection(@ownedClassrooms)
    @courses = new CocoCollection([], { url: "/db/course", model: Course})
    @supermodel.loadCollection(@courses, 'courses')
    @classrooms = new CocoCollection([], { url: "/db/classroom", model: Classroom })
    @classrooms.comparator = '_id'
    @listenToOnce @classrooms, 'sync', @onceClassroomsSync
    @supermodel.loadCollection(@classrooms, 'classrooms', {data: {ownerID: me.id}})
    @campaigns = new Campaigns()
    @supermodel.trackRequest @campaigns.fetchByType('course', { data: { project: 'levels,levelsUpdated' } })
    @courseInstances = new CocoCollection([], { url: "/db/course_instance", model: CourseInstance })
    @courseInstances.comparator = 'courseID'
    @courseInstances.sliceWithMembers = -> return @filter (courseInstance) -> _.size(courseInstance.get('members')) and courseInstance.get('classroomID')
    @supermodel.loadCollection(@courseInstances, 'course_instances', {data: {ownerID: me.id}})
    @members = new CocoCollection([], { model: User })
    @listenTo @members, 'sync', @render
    @

  onceClassroomsSync: ->
    for classroom in @classrooms.models
      @members.fetch({
        remove: false
        url: "/db/classroom/#{classroom.id}/members"
      })

  onClickActivateLicensesButton: ->
    modal = new ActivateLicensesModal({
      users: @members
    })
    @openModalView(modal)
    modal.once 'redeem-users', -> document.location.reload()
    application.tracker?.trackEvent 'Courses teachers started enroll students', category: 'Courses'

  onClickAddStudents: (e) ->
    classroomID = $(e.target).data('classroom-id')
    classroom = @classrooms.get(classroomID)
    unless classroom
      console.error 'No classroom ID found.'
      return
    modal = new InviteToClassroomModal({classroom: classroom})
    @openModalView(modal)
    application.tracker?.trackEvent 'Classroom started add students', category: 'Courses', classroomID: classroom.id

  onClickCreateNewClassButton: ->
    return application.router.navigate('/teachers/signup', {trigger: true}) if me.get('anonymous')
    modal = new ClassroomSettingsModal({})
    @openModalView(modal)
    @listenToOnce modal, 'hide', =>
      # TODO: how to get new classroom from modal?
      @classrooms.add(modal.classroom)
      # TODO: will this definitely fire after modal saves new classroom?
      @listenToOnce modal.classroom, 'sync', ->
        @addFreeCourseInstances()
        @render()

  onClickEditClassroomSmall: (e) ->
    classroomID = $(e.target).data('classroom-id')
    classroom = @classrooms.get(classroomID)
    modal = new ClassroomSettingsModal({classroom: classroom})
    @openModalView(modal)
    @listenToOnce modal, 'hide', @render
    
  onClickPlayLevel: (e) ->
    form = $(e.currentTarget).closest('.play-level-form')
    levelSlug = form.find('.level-select').val()
    courseID = form.data('course-id')
    language = form.find('.language-select').val()
    url = "/play/level/#{levelSlug}?course=#{courseID}&codeLanguage=#{language}"
    application.router.navigate(url, { trigger: true })

  onLoaded: ->
    super()
    @addFreeCourseInstances()

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
