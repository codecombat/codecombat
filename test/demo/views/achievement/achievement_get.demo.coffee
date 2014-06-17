CocoModel = require 'models/CocoModel'
RootView = require 'views/kinds/RootView'

module.exports = ->
  console.log jasmine.Ajax.requests.mostRecent()
  -> console.log 'herp'
