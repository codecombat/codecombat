RootView = require 'views/kinds/RootView'
template = require 'templates/admin/clas'
CocoCollection = require 'collections/CocoCollection'
CocoModel = require 'models/CocoModel'

class CLASubmission extends CocoModel
  @className: 'CLA'
  @schema: require 'schemas/models/cla_submission'
  urlRoot: '/db/cla.submission'

class CLACollection extends CocoCollection
  url: '/db/cla.submissions'
  model: CLASubmission

module.exports = class CLAsView extends RootView
  id: 'admin-clas-view'
  template: template

  constructor: (options) ->
    super options
    @clas = @supermodel.loadCollection(new CLACollection(), 'clas').model

  getRenderData: ->
    c = super()
    c.clas = []
    if @supermodel.finished()
      c.clas = _.uniq (_.sortBy (cla.attributes for cla in @clas.models), (m) ->
        m.githubUsername?.toLowerCase()), 'githubUsername'
    c
