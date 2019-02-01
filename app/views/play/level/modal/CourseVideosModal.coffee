ModalComponent = require 'views/core/ModalComponent'
CourseVideosModalComponent = require('./CourseVideosModalComponent.vue').default

module.exports = class CourseVideosModal extends ModalComponent
  id: 'course-videos-modal'
  template: require 'templates/core/modal-base-flat'
  VueComponent: CourseVideosModalComponent
  propsData: null

  # Runs before the constructor is called.
  initialize: ->
    @propsData = {
      courseInstanceID: null
      courseID: null
    }
  constructor: (options) ->
    super(options)
    @propsData.courseInstanceID = options?.courseInstanceID or null
    @propsData.courseID = options?.courseID or null

  destroy: ->
    @onDestroy?()
    super()