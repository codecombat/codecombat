RootComponent = require 'views/core/RootComponent'
template = require 'templates/base-flat'
co = require('co')
api = require 'core/api'

CLAsComponent = Vue.extend({
  data: ->
    clas: []
    
  template: require('templates/admin/clas')()
  
  methods:
    dateFormat: (s) -> moment(s).format('llll')
    
  created: co.wrap ->
    clas = yield api.clas.getAll()
    clas = _.sortBy(clas, (cla) -> (cla.githubUsername || 'zzzzzz').toLowerCase())
    clas = _.uniq(clas, true, 'githubUsername')
    @clas = clas
})

module.exports = class CLAsView extends RootComponent
  id: 'admin-clas-view'
  template: template
  VueComponent: CLAsComponent
