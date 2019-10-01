ContributeClassView = require './ContributeClassView'
template = require 'templates/contribute/ambassador'
{me} = require 'core/auth'
ContactModal = require 'views/core/ContactModal'

module.exports = class AmbassadorView extends ContributeClassView
  id: 'ambassador-view'
  template: template
  
  events:
    'click [data-toggle="coco-modal"][data-target="core/ContactModal"]': 'openContactModal'

  initialize: ->
    @contributorClassName = 'ambassador'

  openContactModal: (e) ->
    e.stopPropagation()
    @openModalView new ContactModal()
