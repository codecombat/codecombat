PaymentsView = require 'views/account/PaymentsView'
Payments = require 'collections/Payments'
factories = require 'test/app/factories'

describe 'PaymentsView', ->
  
  it 'displays the payment "description" if the payment\'s productID is "custom"', ->
    view = new PaymentsView()
    payment = factories.makePayment({productID: 'custom', description: 'Custom Description' })
    view.payments.fakeRequests[0].respondWith({
      status: 200
      responseText: new Payments([payment]).stringify()
    })
    view.render()
    expect(_.contains(view.$el.text(), 'Custom Description')).toBe(true)
    jasmine.demoEl(view.$('#site-content-area'))
