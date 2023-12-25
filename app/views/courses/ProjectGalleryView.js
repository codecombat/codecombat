// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let ProjectGalleryView
require('app/styles/courses/project-gallery.sass')
const RootComponent = require('views/core/RootComponent')
const FlatLayout = require('core/components/FlatLayout')
const api = require('core/api')
const User = require('models/User')
const Level = require('models/Level')
const utils = require('core/utils')
const userClassroomHelper = require('../../lib/user-classroom-helper')

const ProjectGalleryComponent = Vue.extend({
  name: 'ProjectGalleryComponent',
  template: require('app/templates/courses/project-gallery-view')(),
  components: {
    'flat-layout': FlatLayout
  },
  props: {
    courseInstanceID: {
      type: String,
      default () { return null }
    }
  },
  data () {
    return {
      levelSessions: [],
      users: [],
      classroom: null,
      levels: null,
      level: null,
      course: null,
      courseInstance: null,
      amSchoolAdministratorOfGallery: null,
      amTeacherOfGallery: null,
      product: utils.isOzaria ? 'ozar' : 'coco'
    }
  },
  computed: {
    levelName () { return this.level && (utils.i18n(this.level, 'displayName') || utils.i18n(this.level, 'name')) },
    courseName () { return this.course && utils.i18n(this.course, 'name') },
    teacherBackUrl () { return this.classroom && `/teachers/classes/${(this.classroom != null ? this.classroom._id : undefined)}` },
    schoolAdministratorBackUrl () { return this.classroom && `/school-administrator/teacher/${(this.classroom != null ? this.classroom.ownerID : undefined)}/classroom/${(this.classroom != null ? this.classroom._id : undefined)}` }
  },
  created () {
    return Promise.all([
      api.courseInstances.getProjectGallery({ courseInstanceID: this.courseInstanceID }).then(levelSessions => {
        this.levelSessions = levelSessions
      }),
      api.courseInstances.get({ courseInstanceID: this.courseInstanceID }).then(courseInstance => {
        this.courseInstance = courseInstance
        return Promise.all([
          api.classrooms.get({ classroomID: this.courseInstance.classroomID }).then(classroom => {
            this.classroom = classroom
          }).then(() => {
            return api.classrooms.getMembers({ classroom: this.classroom }, { removeDeleted: true }).then(users => {
              this.users = users
            })
          }),
          api.courses.get({ courseID: this.courseInstance.courseID }).then(course => {
            this.course = course
          }),
          api.classrooms.getCourseLevels({ classroomID: this.courseInstance.classroomID, courseID: this.courseInstance.courseID }).then(levels => {
            this.levels = levels
          })
        ])
      })
    ]).then(() => {
      userClassroomHelper.isSchoolAdminOf({ user: me, classroomId: this.courseInstance.classroomID }).then(res => { return this.amSchoolAdministratorOfGallery = res })
      userClassroomHelper.isTeacherOf({ user: me, classroomId: this.courseInstance.classroomID }).then(res => { return this.amTeacherOfGallery = res })
      this.level = _.find(this.levels, Level.isProject)
      return this.users.forEach(user => {
        return Vue.set(user, 'broadName', User.broadName(user))
      })
    })
  },
  methods: {
    getProjectViewUrl (session) {
      return `/play/${(this.level != null ? this.level.type : undefined)}-level/${(this.level != null ? this.level.slug : undefined)}/${session._id}`
    },
    getProjectEditUrl (session) {
      return `/play/level/${(this.level != null ? this.level.slug : undefined)}?course=${(this.course != null ? this.course._id : undefined)}&course-instance=${(this.courseInstance != null ? this.courseInstance._id : undefined)}`
    },
    isMyProject (session) {
      return session.creator === me.id
    },
    creatorOfSession (session) {
      return _.find(this.users, { _id: session.creator })
    }
  }
})

module.exports = (ProjectGalleryView = (function () {
  ProjectGalleryView = class ProjectGalleryView extends RootComponent {
    static initClass () {
      this.prototype.id = 'project-gallery-view'
      this.prototype.template = require('app/templates/base-flat')
      this.prototype.VueComponent = ProjectGalleryComponent
    }

    constructor (options, courseInstanceID) {
      super(options)
      this.courseInstanceID = courseInstanceID
      this.propsData = { courseInstanceID: this.courseInstanceID }
    }
  }
  ProjectGalleryView.initClass()
  return ProjectGalleryView
})())
