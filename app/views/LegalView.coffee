require('app/styles/legal.sass')
RootView = require 'views/core/RootView'
template = require 'templates/legal'
Products = require 'collections/Products'

module.exports = class LegalView extends RootView
  id: 'legal-view'
  template: template

  initialize: ->
    @products = new Products()
    @supermodel.loadCollection(@products, 'products')

  afterRender: ->
    super()
    basicSub = @products.findWhere({name: 'basic_subscription'})
    return unless basicSub
    text = $.i18n.t('legal.cost_description')
    text = text.replace('{{price}}', (basicSub.get('amount') / 100).toFixed(2))
    text = text.replace('{{gems}}', basicSub.get('gems'))
    @$('#cost-description').text(text)
