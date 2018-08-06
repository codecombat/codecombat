RootComponent = require 'views/core/RootComponent'
template = require 'templates/base-flat'
ParentsViewComponent = require('./ParentsViewComponent.vue').default
ReferTeacherModal = require('views/core/ReferTeacherModal')

module.exports = class ParentView extends RootComponent
  id: 'parents-view'
  template: template
  VueComponent: ParentsViewComponent
    
  afterRender: ->
    super()
    if (@vueComponent)
      @vueComponent.$on('referTeacher', => @onReferTeacher())
    
  onReferTeacher: () ->
    @openModalView new ReferTeacherModal()
