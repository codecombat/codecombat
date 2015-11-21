app = require 'core/application'
AuthModal = require 'views/core/AuthModal'
RootView = require 'views/core/RootView'
template = require 'templates/courses/courses-view'
StudentLogInModal = require 'views/courses/StudentLogInModal'
StudentSignUpModal = require 'views/courses/StudentSignUpModal'
CourseInstance = require 'models/CourseInstance'

module.exports = class CoursesView extends RootView
  id: 'courses-view'
  template: template

  events:
    'click #log-in-btn': 'onClickLogInButton'
    'click #start-new-game-btn': 'onClickStartNewGameButton'
    
  onClickStartNewGameButton: ->
    @openSignUpModal()

  onClickLogInButton: ->
    modal = new StudentLogInModal()
    @openModalView(modal)
    modal.on 'want-to-create-account', @openSignUpModal, @

  openSignUpModal: ->
    modal = new StudentSignUpModal({ willPlay: true })
    @openModalView(modal)
    modal.once 'click-skip-link', @startHourOfCodePlay, @

  startHourOfCodePlay: ->
    @$('#main-content').hide()
    @$('#begin-hoc-area').removeClass('hide')
    hocCourseInstance = new CourseInstance()
    hocCourseInstance.upsertForHOC()
    @listenToOnce hocCourseInstance, 'sync', ->
      url = hocCourseInstance.firstLevelURL()
      app.router.navigate(url, { trigger: true })
