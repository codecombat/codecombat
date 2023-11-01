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
