RootComponent = require 'views/core/RootComponent'
template = require 'templates/base-flat'
AdminClassroomLevelsComponent = require('./AdminClassroomLevelsComponent.vue').default

module.exports = class AdminClassroomLevelsView extends RootComponent
  id: 'admin-classroom-levels-view'
  template: template
  VueComponent: AdminClassroomLevelsComponent
