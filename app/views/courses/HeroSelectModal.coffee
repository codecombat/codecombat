ModalView = require 'views/core/ModalView'
template = require 'templates/courses/hero-select-modal'
Classroom = require 'models/Classroom'
CocoCollection = require 'collections/CocoCollection'
State = require 'models/State'
ThangType = require 'models/ThangType'
User = require 'models/User'

module.exports = class HeroSelectModal extends ModalView
  id: 'hero-select-modal'
  template: template

  events:
    'click .select-hero-btn': 'onClickSelectHeroButton'
    'click .hero-option': 'onClickHeroOption'

  initialize: ({ currentHeroID }) ->
    @state = new State({
      currentHeroID
      selectedHeroID: currentHeroID
    })

    @heroes = new CocoCollection([], {model: ThangType})
    @heroes.url = '/db/thang.type?view=heroes'
    @heroes.setProjection ['original','name']
    @heroes.comparator = 'gems' # TODO: Random? Alphabetical? Something else?
    @supermodel.loadCollection(@heroes, 'heroes')

    @listenTo @state, 'all', @render
    @listenTo @heroes, 'all', @render

  onClickHeroOption: (e) ->
    heroID = $(e.currentTarget).data('hero-id')
    @state.set selectedHeroID: heroID
    hero = @heroes.get(heroID)
    me.set(heroConfig: {}) unless me.get('heroConfig')
    me.get('heroConfig').thangType = hero.get('original')
    me.save().then =>
      @trigger 'hero-select:success', hero

  onClickSelectHeroButton: () ->
    @hide()
