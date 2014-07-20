ModalView = require 'views/kinds/ModalView'
template = require 'templates/play/level/modal/reload'

# let's implement this once we have the docs database schema set up

module.exports = class ReloadModal extends ModalView
  id: '#reload-code-modal'
  template: template

  events:
    'click #restart-level-confirm-button': -> Backbone.Mediator.publish 'restart-level'
