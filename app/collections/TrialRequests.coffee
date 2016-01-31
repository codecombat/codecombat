CocoCollection = require 'collections/CocoCollection'
TrialRequest = require 'models/TrialRequest'

module.exports = class TrialRequestCollection extends CocoCollection
  url: '/db/trial.request'
  model: TrialRequest

  fetchOwn: (options) ->
    options = _.extend({data: {}}, options)
    options.url = _.result(@, 'url') + '/-/own'
    @fetch(options)
