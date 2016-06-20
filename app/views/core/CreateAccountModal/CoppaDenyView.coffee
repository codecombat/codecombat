ModalView = require 'views/core/ModalView'
template = require 'templates/core/create-account-modal/coppa-deny-view'
forms = require 'core/forms'

module.exports = class SegmentCheckView extends ModalView
  id: 'coppa-deny-view'
  template: template

  events:
    null

  initialize: ({ @sharedState } = {}) ->
