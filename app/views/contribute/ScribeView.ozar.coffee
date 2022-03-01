ContributeClassView = require './ContributeClassView'
template = require 'templates/contribute/scribe'
{me} = require 'core/auth'
ContactModal = require 'views/core/ContactModal'

module.exports = class ScribeView extends ContributeClassView
  id: 'scribe-view'
  template: template

  events:
    'click [data-toggle="coco-modal"][data-target="core/ContactModal"]': 'openContactModal'

  initialize: ->
    @contributorClassName = 'scribe'

  openContactModal: (e) ->
    e.stopPropagation()
    @openModalView new ContactModal()

  contributors: [
    {name: 'Ryan Faidley'}
    {name: 'Mischa Lewis-Norelle', github: 'mlewisno'}
    {name: 'Tavio'}
    {name: 'Ronnie Cheng', github: 'rhc2104'}
    {name: 'engstrom'}
    {name: 'Dman19993'}
    {name: 'mattinsler'}
  ]
