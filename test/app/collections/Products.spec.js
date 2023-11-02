/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
// TODO: unreliable test case, product data doesn't change often.
xdescribe('ProductModel', function() {
  // Temporarily turn ajax back on for a real call to /db/products
  beforeEach(() => jasmine.Ajax.uninstall());
  afterEach(() => jasmine.Ajax.install());
  return it('basic_subscription products have payPalBillingPlanID set', done => $.ajax("/db/products")
  .done((data, textStatus, jqXHR) => {
    for (var product of Array.from(data)) {
      if (!/basic_subscription/.test(product.name)) { continue; }
      expect(product.payPalBillingPlanID).toBeDefined();
    }
    return done();
}).fail((jqXHR, textStatus, errorThrown) => {
    console.error(jqXHR, textStatus, errorThrown);
    return done(textStatus);
  }));
});
