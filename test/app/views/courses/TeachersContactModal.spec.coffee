TeachersContactModal = require 'views/teachers/TeachersContactModal'
TrialRequests = require 'collections/TrialRequests'
factories = require 'test/app/factories'

describe 'TeachersContactModal', ->
  beforeEach (done) ->
    @modal = new TeachersContactModal()
    @modal.render()
    trialRequests = new TrialRequests([factories.makeTrialRequest()])
    @modal.trialRequests.fakeRequests[0].respondWith({ status: 200, responseText: trialRequests.stringify() })
    @modal.supermodel.once('loaded-all', done)
    jasmine.demoModal(@modal)

  it 'shows an error when the name is empty and the form is submitted', ->
    @modal.$('input[name="name"]').val('')
    @modal.$('form').submit()
    expect(@modal.$('input[name="name"]').closest('.form-group').hasClass('has-error')).toBe(true)

  it 'shows an error when the email is invalid and the form is submitted', ->
    @modal.$('input[name="email"]').val('not an email')
    @modal.$('form').submit()
    expect(@modal.$('input[name="email"]').closest('.form-group').hasClass('has-error')).toBe(true)

  it 'shows an error when licensesNeeded is not > 0 and the form is submitted', ->
    @modal.$('input[name="licensesNeeded"]').val('')
    @modal.$('form').submit()
    expect(@modal.$('input[name="licensesNeeded"]').closest('.form-group').hasClass('has-error')).toBe(true)

  it 'shows an error when the message is empty and the form is submitted', ->
    @modal.$('textarea[name="message"]').val('')
    @modal.$('form').submit()
    expect(@modal.$('textarea[name="message"]').closest('.form-group').hasClass('has-error')).toBe(true)

  describe 'submit form', ->
    beforeEach ->
      @modal.$('input[name="licensesNeeded"]').val(777)
      @modal.$('form').submit()

    it 'disables inputs', ->
      for el in @modal.$('button, input, textarea')
        expect($(el).is(':disabled')).toBe(true)

    describe 'failed contact', ->
      beforeEach ->
        request = jasmine.Ajax.requests.mostRecent()
        request.respondWith({status: 500})

      it 'shows an error', ->
        expect(@modal.$('.alert-danger').length).toBe(1)

    describe 'successful contact', ->
      beforeEach ->
        request = jasmine.Ajax.requests.mostRecent()
        request.respondWith({status: 200, responseText: '{}'})

      it 'shows a success message', ->
        expect(@modal.$('.alert-success').length).toBe(1)

      it 'disables the submit button', ->
        expect(@modal.$('#submit-btn').is(':disabled')).toBe(true)

