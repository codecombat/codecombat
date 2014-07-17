View = require 'views/kinds/RootView'
template = require 'templates/admin/clas'

module.exports = class CLAsView extends View
  id: 'admin-clas-view'
  template: template
  startsLoading: true

  constructor: (options) ->
    super options
    @getCLAs()

  getCLAs: ->
    CLACollection = Backbone.Collection.extend({
      url: '/db/cla.submissions'
    })
    @clas = new CLACollection()
    @clas.fetch()
    @listenTo(@clas, 'sync', @onCLAsLoaded)

  onCLAsLoaded: ->
    @startsLoading = false
    @render()

  getRenderData: ->
    c = super()
    c.clas = []
    unless @startsLoading
      c.clas = _.uniq (_.sortBy (cla.attributes for cla in @clas.models), (m) -> m.githubUsername?.toLowerCase()), 'githubUsername'
    c
