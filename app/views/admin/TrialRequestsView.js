// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let TrialRequestsView
require('app/styles/admin/trial-requests.sass')
const RootView = require('views/core/RootView')
const template = require('app/templates/admin/trial-requests')
const CocoCollection = require('collections/CocoCollection')
const TrialRequest = require('models/TrialRequest')

module.exports = (TrialRequestsView = (function () {
  TrialRequestsView = class TrialRequestsView extends RootView {
    static initClass () {
      this.prototype.id = 'admin-trial-requests-view'
      this.prototype.template = template

      this.prototype.events = {
        'click .btn-approve': 'onClickApprove',
        'click .btn-deny': 'onClickDeny'
      }
    }

    constructor (options) {
      super(options)
      if (me.isAdmin()) {
        const sortRequests = function (a, b) {
          const statusA = a.get('status')
          const statusB = b.get('status')
          if ((statusA === 'submitted') && (statusB === 'submitted')) {
            if (a.get('created') < b.get('created')) {
              return -1
            } else {
              return 1
            }
          } else if (statusA === 'submitted') {
            return -1
          } else if (statusB === 'submitted') {
            return 1
          } else if (!b.get('reviewDate') || (a.get('reviewDate') > b.get('reviewDate'))) {
            return -1
          } else {
            return 1
          }
        }
        this.trialRequests = new CocoCollection([], { url: '/db/trial.request?conditions[sort]="-created"&conditions[limit]=1000', model: TrialRequest, comparator: sortRequests })
        this.supermodel.loadCollection(this.trialRequests, 'trial-requests', { cache: false })
      }
    }

    getRenderData () {
      const context = super.getRenderData()
      context.trialRequests = (this.trialRequests != null ? this.trialRequests.models : undefined) != null ? (this.trialRequests != null ? this.trialRequests.models : undefined) : []
      return context
    }

    onClickApprove (e) {
      const trialRequestID = $(e.target).data('trial-request-id')
      const trialRequest = _.find(this.trialRequests.models, a => a.id === trialRequestID)
      if (!trialRequest) {
        console.error('Could not find trial request model for', trialRequestID)
        return
      }
      trialRequest.set('status', 'approved')
      return trialRequest.patch({
        error: (model, response, options) => {
          return console.error('Error patching trial request', response)
        },
        success: (model, response, options) => {
          return (typeof this.render === 'function' ? this.render() : undefined)
        }
      })
    }

    onClickDeny (e) {
      const trialRequestID = $(e.target).data('trial-request-id')
      const trialRequest = _.find(this.trialRequests.models, a => a.id === trialRequestID)
      if (!trialRequest) {
        console.error('Could not find trial request model for', trialRequestID)
        return
      }
      if (!window.confirm(`Deny ${trialRequest.get('properties').email}?`)) { return }
      trialRequest.set('status', 'denied')
      return trialRequest.patch({
        error: (model, response, options) => {
          return console.error('Error patching trial request', response)
        },
        success: (model, response, options) => {
          return (typeof this.render === 'function' ? this.render() : undefined)
        }
      })
    }
  }
  TrialRequestsView.initClass()
  return TrialRequestsView
})())
