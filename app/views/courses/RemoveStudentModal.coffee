ModalView = require 'views/core/ModalView'
template = require 'templates/courses/remove-student-modal'

module.exports = class RemoveStudentModal extends ModalView
  id: 'remove-student-modal'
  template: template

  events:
    'click #remove-student-btn': 'onClickRemoveStudentButton'

  initialize: (options) ->
    @classroom = options.classroom
    @user = options.user
    @courseInstances = options.courseInstances

  onClickRemoveStudentButton: ->
    @$('#remove-student-buttons').addClass('hide')
    @$('#remove-student-progress').removeClass('hide')
    userID = @user.id
    @toRemove = @courseInstances.filter (courseInstance) -> _.contains(courseInstance.get('members'), userID)
    @toRemove.push @classroom
    @totalJobs = _.size(@toRemove)
    @removeStudent()

  removeStudent: ->
    model = @toRemove.shift()
    if not model
      @trigger 'remove-student', { user: @user }
      @hide()
      return

    model.removeMember(@user.id)
    pct = (100 * (@totalJobs - @toRemove.length) / @totalJobs).toFixed(1) + '%'
    @$('#remove-student-progress .progress-bar').css('width', pct)
    @listenToOnce model, 'sync', ->
      @removeStudent()
