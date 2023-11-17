/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
const PaymentsView = require('views/account/PaymentsView');
const Payments = require('collections/Payments');
const Prepaids = require('collections/Prepaids');
const factories = require('test/app/factories');

describe('PaymentsView', () => it('displays the payment "description" if the payment\'s productID is "custom"', function() {
  const view = new PaymentsView();
  const payment = factories.makePayment({productID: 'custom', description: 'Custom Description' });
  view.payments.fakeRequests[0].respondWith({
    status: 200,
    responseText: new Payments([payment]).stringify()
  });
  const prepaid = factories.makePrepaid({});
  view.prepaids.fakeRequests[0].respondWith({
    status: 200,
    responseText: new Prepaids([prepaid]).stringify()
  });
  view.onLoaded();
  view.render();
  expect(_.contains(view.$el.text(), 'Custom Description')).toBe(true);
  return jasmine.demoEl(view.$('#site-content-area'));
}));
