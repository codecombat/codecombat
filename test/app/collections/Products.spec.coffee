# TODO: unreliable test case, product data doesn't change often.
xdescribe 'ProductModel', ->
  # Temporarily turn ajax back on for a real call to /db/products
  beforeEach -> jasmine.Ajax.uninstall()
  afterEach -> jasmine.Ajax.install()
  it 'basic_subscription products have payPalBillingPlanID set', (done) ->
    $.ajax("/db/products")
    .done (data, textStatus, jqXHR) =>
      for product in data
        continue unless /basic_subscription/.test(product.name)
        expect(product.payPalBillingPlanID).toBeDefined()
      done()
    .fail (jqXHR, textStatus, errorThrown) =>
      console.error(jqXHR, textStatus, errorThrown)
      done(textStatus)
