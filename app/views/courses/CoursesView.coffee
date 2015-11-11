app = require 'core/application'
AuthModal = require 'views/core/AuthModal'
RootView = require 'views/core/RootView'
template = require 'templates/courses/courses-view'

module.exports = class CoursesView extends RootView
  id: 'courses-view'
  template: template
