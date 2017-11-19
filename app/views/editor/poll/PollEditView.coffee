require('app/styles/editor/poll/poll-edit-view.sass')
RootView = require 'views/core/RootView'
template = require 'templates/editor/poll/poll-edit-view'
Poll = require 'models/Poll'
UserPollsRecord = require 'models/UserPollsRecord'
PollModal = require 'views/play/modal/PollModal'
ConfirmModal = require 'views/core/ConfirmModal'
PatchesView = require 'views/editor/PatchesView'
errors = require 'core/errors'

require 'lib/game-libraries'

module.exports = class PollEditView extends RootView
  id: 'editor-poll-edit-view'
  template: template

  events:
    'click #save-button': 'savePoll'
    'click #delete-button': 'confirmDeletion'

  constructor: (options, @pollID) ->
    super options
    @loadPoll()
    @loadUserPollsRecord()
    @pushChangesToPreview = _.throttle(@pushChangesToPreview, 500)

  loadPoll: ->
    @poll = new Poll _id: @pollID
    @poll.saveBackups = true
    @supermodel.loadModel @poll

  loadUserPollsRecord: ->
    url = "/db/user.polls.record/-/user/#{me.id}"
    @userPollsRecord = new UserPollsRecord().setURL url
    onRecordSync = ->
      return if @destroyed
      @userPollsRecord.url = -> '/db/user.polls.record/' + @id
    @listenToOnce @userPollsRecord, 'sync', onRecordSync
    @userPollsRecord = @supermodel.loadModel(@userPollsRecord).model
    onRecordSync.call @ if @userPollsRecord.loaded

  onLoaded: ->
    super()
    @buildTreema()
    @listenTo @poll, 'change', =>
      @poll.updateI18NCoverage()
      @treema.set('/', @poll.attributes)

  buildTreema: ->
    return if @treema? or (not @poll.loaded) or (not me.isAdmin())
    data = $.extend(true, {}, @poll.attributes)
    options =
      data: data
      filePath: "db/poll/#{@poll.get('_id')}"
      schema: Poll.schema
      readOnly: me.get('anonymous')
      callbacks:
        change: => @pushChangesToPreview() unless @hush
    @treema = @$el.find('#poll-treema').treema(options)
    @treema.build()
    @treema.childrenTreemas.answers?.open 1
    @pushChangesToPreview()

  afterRender: ->
    super()
    return unless @supermodel.finished()
    @pushChangesToPreview()
    @patchesView = @insertSubView(new PatchesView(@poll), @$el.find('.patches-view'))
    @patchesView.load()

  pushChangesToPreview: =>
    return unless @treema
    @$el.find('#poll-view').empty()
    for key, value of @treema.data
      @poll.set key, value
    @pollModal?.destroy()
    @pollModal = new PollModal supermodel: @supermodel, poll: @poll, userPollsRecord: @userPollsRecord
    @pollModal.render()
    $('#poll-view').empty().append @pollModal.el
    #pollModal.afterInsert()  # This blurs the active input; don't do it
    @pollModal.$el.removeClass('modal fade').show()
    @pollModal.on 'vote-updated', =>
      @hush = true
      @treema.set '/answers', @pollModal.poll.get('answers')
      @hush = false

  savePoll: (e) ->
    @treema.endExistingEdits()
    for key, value of @treema.data
      @poll.set(key, value)

    res = @poll.save()

    res.error (collection, response, options) =>
      console.error response

    res.success =>
      url = "/editor/poll/#{@poll.get('slug') or @poll.id}"
      document.location.href = url

  confirmDeletion: ->
    renderData =
      title: 'Are you really sure?'
      body: 'This will completely delete the poll, potentially breaking a lot of stuff you don\'t want breaking. Are you entirely sure?'
      decline: 'Not really'
      confirm: 'Definitely'

    confirmModal = new ConfirmModal renderData
    confirmModal.on 'confirm', @deletePoll
    @openModalView confirmModal

  deletePoll: =>
    console.debug 'deleting'
    $.ajax
      type: 'DELETE'
      success: ->
        noty
          timeout: 5000
          text: 'Aaaand it\'s gone.'
          type: 'success'
          layout: 'topCenter'
        _.delay ->
          application.router.navigate '/editor/poll', trigger: true
        , 500
      error: (jqXHR, status, error) ->
        console.error jqXHR
        timeout: 5000
        text: "Deleting poll failed with error code #{jqXHR.status}"
        type: 'error'
        layout: 'topCenter'
      url: "/db/poll/#{@poll.id}"
