require('app/styles/modal/create-account-modal/oz-vs-coco-view.sass')
CocoView = require 'views/core/CocoView'
template = require 'templates/core/create-account-modal/oz-vs-coco-view'

module.exports = class OzVsCocoView extends CocoView
  id: 'oz-vs-coco-view'
  template: template

  events:
    'click .continue-codecombat': -> @trigger 'nav-forward'
    'click .back-button': -> @trigger 'nav-back'
