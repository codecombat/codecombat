ModalView = require 'views/core/ModalView'
template = require 'templates/courses/join-class-modal'
Classroom = require 'models/Classroom'
User = require 'models/User'

module.exports = class JoinClassModal extends ModalView
  id: 'join-class-modal'
  template: template

  events:
    'click .join-class-btn': 'onClickJoinClassButton'

  initialize: ({ @classCode }) ->
    @classroom = new Classroom()
    @teacher = new User()
    jqxhr = @supermodel.trackRequest @classroom.fetchByCode(@classCode)
    unless me.get('emailVerified')
      @supermodel.trackRequest $.post("/db/user/#{me.id}/request-verify-email")
    @listenTo @classroom, 'error', ->
      @trigger('error')
    @listenTo @classroom, 'sync', ->
      @render
    @listenTo @classroom, 'join:success', ->
      @trigger('join:success', @classroom)
    @listenTo @classroom, 'join:error', ->
      @trigger('join:error', @classroom, jqxhr)
      # @close()

  onClickJoinClassButton: ->
    @classroom.joinWithCode(@classCode)
