RootView = require 'views/core/RootView'
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
  comparator: (claSubmission) -> return (claSubmission.get('githubUsername') or 'zzzzz').toLowerCase()

module.exports = class CLAsView extends RootView
  id: 'admin-clas-view'
  template: template

  constructor: (options) ->
    super options
    @clas = @supermodel.loadCollection(new CLACollection(), 'clas', {cache: false}).model
