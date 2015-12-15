RootView = require 'views/core/RootView'
template = require 'templates/legal'
Products = require 'collections/Products'

module.exports = class LegalView extends RootView
  id: 'legal-view'
  template: template
  
  initialize: ->
    @products = new Products()
    @supermodel.loadCollection(@products, 'products')
    
  onLoaded: ->
    basicSub = @products.findWhere({name: 'basic_subscription'})
    @price = (basicSub.get('amount') / 100).toFixed(2)
    @gems = basicSub.get('gems')
    super()
    
  afterRender: ->
    super()
    # TODO: Figure out how to use i18n interpolation in this case
    $el = @$('#cost-description')
    f = =>
      $el.text($el.text().replace('{{price}}', @price))
      $el.text($el.text().replace('{{gems}}', @gems))
    _.defer(f) # i18n call gets made immediately after render
