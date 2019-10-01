require('app/styles/courses/project-gallery.sass')
RootComponent = require 'views/core/RootComponent'
FlatLayout = require 'core/components/FlatLayout'
api = require 'core/api'
User = require 'models/User'
Level = require 'models/Level'
utils = require 'core/utils'

ProjectGalleryComponent = Vue.extend
  name: 'project-gallery-component'
  template: require('templates/courses/project-gallery-view')()
  components:
    'flat-layout': FlatLayout
  props:
    courseInstanceID:
      type: String
      default: -> null
  data: ->
    levelSessions: []
    users: []
    classroom: null
    levels: null
    level: null
    course: null
    courseInstance: null
    amSchoolAdministratorOfGallery: null
    amTeacherOfGallery: null
  computed:
    levelName: -> @level and utils.i18n(@level, 'name')
    courseName: -> @course and utils.i18n(@course, 'name')
    teacherBackUrl: -> @classroom and "/teachers/classes/#{@classroom?._id}"
    schoolAdministratorBackUrl: -> @classroom and "/school-administrator/teacher/#{@classroom?.ownerID}/classroom/#{@classroom?._id}"
  created: ->
    Promise.all([
      api.courseInstances.getProjectGallery({ @courseInstanceID }).then((@levelSessions) =>)
      api.courseInstances.get({@courseInstanceID}).then (@courseInstance) =>
        Promise.all([
          api.classrooms.get({classroomID: @courseInstance.classroomID}).then((@classroom) =>).then =>
            api.classrooms.getMembers({@classroom}, removeDeleted: true).then((@users) =>)
          api.courses.get({ courseID: @courseInstance.courseID }).then((@course) =>)
          api.classrooms.getCourseLevels({ classroomID: @courseInstance.classroomID, courseID: @courseInstance.courseID }).then((@levels) =>)
        ])
    ]).then =>
      me.isSchoolAdminOf({ classroomId: @courseInstance.classroomID }).then((res) => @amSchoolAdministratorOfGallery = res)
      me.isTeacherOf({ classroomId: @courseInstance.classroomID }).then((res) => @amTeacherOfGallery = res)
      @level = _.find(@levels, Level.isProject)
      @users.forEach (user) =>
        Vue.set(user, 'broadName', User.broadName(user))
  methods:
    getProjectViewUrl: (session) ->
      return "/play/#{@level?.type}-level/#{@level?.slug}/#{session._id}"
    getProjectEditUrl: (session) ->
      return "/play/level/#{@level?.slug}?course=#{@course?._id}&course-instance=#{@courseInstance?._id}"
    isMyProject: (session) ->
      session.creator is me.id
    creatorOfSession: (session) ->
      _.find(@users, { _id: session.creator })

module.exports = class ProjectGalleryView extends RootComponent
  id: 'project-gallery-view'
  template: require 'templates/base-flat'
  VueComponent: ProjectGalleryComponent
  constructor: (options, @courseInstanceID) ->
    @propsData = { @courseInstanceID }
    super options
