RootComponent = require 'views/core/RootComponent'
template = require 'templates/base-flat'
ParentsViewComponent = require('./ParentsViewComponent.vue').default
ParentReferTeacherModal = require('views/core/ParentReferTeacherModal')

# DEPRECATED - this is the old /parents page
module.exports = class ParentView extends RootComponent
  id: 'parents-view'
  template: template
  VueComponent: ParentsViewComponent
  propsData: {}

  initialize: ->
    @propsData = { onReferTeacher: () => @openModalView new ParentReferTeacherModal() }
