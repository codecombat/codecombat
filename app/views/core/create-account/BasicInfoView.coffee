ModalView = require 'views/core/ModalView'
template = require 'templates/core/create-account-modal/basic-info-view'
forms = require 'core/forms'

module.exports = class SegmentCheckView extends ModalView
  id: 'basic-info-view'
  template: template

  events:
    'click .back-to-account-type': -> @trigger 'nav-back'

  initialize: ({ @sharedState } = {}) ->
