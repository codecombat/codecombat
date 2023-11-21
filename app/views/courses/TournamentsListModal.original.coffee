require('app/styles/courses/tournaments-list-modal.sass')
ModalView = require 'views/core/ModalView'
template = require 'templates/courses/tournaments-list-modal'
DOMPurify = require 'dompurify';

module.exports = class TournamentsListModal extends ModalView
  id: 'tournaments-list-modal'
  template: template

  events:
    'click #close-modal': 'hide'

  constructor: (options) ->
    super(options)
    @tournamentsByState = options.tournamentsByState
    @ladderImageMap = options.ladderImageMap