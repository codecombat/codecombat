require('app/styles/courses/hero-select-modal.sass')
ModalView = require 'views/core/ModalView'
HeroSelectView = require 'views/core/HeroSelectView'
template = require 'templates/courses/hero-select-modal'
Classroom = require 'models/Classroom'
ThangTypes = require 'collections/ThangTypes'
State = require 'models/State'
ThangType = require 'models/ThangType'
User = require 'models/User'

module.exports = class HeroSelectModal extends ModalView
  id: 'hero-select-modal'
  template: template
  retainSubviews: true

  events:
    'click .select-hero-btn': 'onClickSelectHeroButton'

  initialize: ->
    @listenTo @insertSubView(new HeroSelectView({ showCurrentHero: true })),
      'hero-select:success', (hero) ->
        @trigger('hero-select:success', hero)

  onClickSelectHeroButton: () ->
    @hide()
