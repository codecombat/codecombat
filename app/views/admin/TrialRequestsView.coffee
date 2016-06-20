RootView = require 'views/core/RootView'
template = require 'templates/admin/trial-requests'
CocoCollection = require 'collections/CocoCollection'
TrialRequest = require 'models/TrialRequest'

module.exports = class TrialRequestsView extends RootView
  id: 'admin-trial-requests-view'
  template: template

  events:
    'click .btn-approve': 'onClickApprove'
    'click .btn-deny': 'onClickDeny'

  constructor: (options) ->
    super options
    if me.isAdmin()
      sortRequests = (a, b) ->
        statusA = a.get('status')
        statusB = b.get('status')
        if statusA is 'submitted' and statusB is 'submitted'
          if a.get('created') < b.get('created')
            -1
          else
            1
        else if statusA is 'submitted'
          -1
        else if statusB is 'submitted'
          1
        else if not b.get('reviewDate') or a.get('reviewDate') > b.get('reviewDate')
          -1
        else
          1
      @trialRequests = new CocoCollection([], { url: '/db/trial.request?conditions[sort]="-created"&conditions[limit]=1000', model: TrialRequest, comparator: sortRequests })
      @supermodel.loadCollection(@trialRequests, 'trial-requests', {cache: false})

  getRenderData: ->
    context = super()
    context.trialRequests = @trialRequests?.models ? []
    context

  onClickApprove: (e) ->
    trialRequestID = $(e.target).data('trial-request-id')
    trialRequest = _.find @trialRequests.models, (a) -> a.id is trialRequestID
    unless trialRequest
      console.error 'Could not find trial request model for', trialRequestData
      return
    trialRequest.set('status', 'approved')
    trialRequest.patch
      error: (model, response, options) =>
        console.error 'Error patching trial request', response
      success: (model, response, options) =>
        @render?()

  onClickDeny: (e) ->
    trialRequestID = $(e.target).data('trial-request-id')
    trialRequest = _.find @trialRequests.models, (a) -> a.id is trialRequestID
    unless trialRequest
      console.error 'Could not find trial request model for', trialRequestData
      return
    return unless window.confirm("Deny #{trialRequest.get('properties').email}?")
    trialRequest.set('status', 'denied')
    trialRequest.patch
      error: (model, response, options) =>
        console.error 'Error patching trial request', response
      success: (model, response, options) =>
        @render?()
