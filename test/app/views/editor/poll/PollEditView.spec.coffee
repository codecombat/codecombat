PollEditView = require 'views/editor/poll/PollEditView'
User = require 'models/User'
Poll = require 'models/Poll'




describe 'PollEditView ', ->


  it 'doesnt show error when admin permissions', ->

    @pollId = _.uniqueId('poll_')
    attrs =  _.extend({}, {
      _id: @pollId,
      properties: {
      name: 'poll test',
      answers: []}
    }, attrs)
    @poll = new Poll(attrs)

    me.clear
    me.set({
      _id: '1234'
      anonymous: false
      email: 'some@email.com'
      name: 'Existing User',
      permissions: ['admin']
    })

    view = new PollEditView({}, @poll.id)
    view.render()
    console.log(view.$el.find('#modal-error'))
    expect(view.$el.find('.alert').length).toBe(0)
    expect(view.$el.find('[class^="noty-"]').length).toBe(0)

  it 'shows error when no admin permissions',  (done) ->

    @pollId = _.uniqueId('poll_')
    attrs =  _.extend({}, {
      _id: @pollId,
      properties: {
      name: 'poll test',
      answers: []}
    }, attrs)
    @poll = new Poll(attrs)

    #permissions array is empty on purpose
    me.clear
    me.set({
      _id: '1235'
      anonymous: false
      email: 'some@email.com'
      name: 'Existing User',
      permissions: []
    })

    console.log("before spy")

    #spyOn(window, 'noty').and.callFake(done)
    spyOn(window, 'noty').and.callFake()  =>
      console.log("callFake")
    view = new PollEditView({}, @poll.id)

    