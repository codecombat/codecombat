ModalView = require 'views/core/ModalView'
template = require 'templates/courses/hero-select-modal'
Classroom = require 'models/Classroom'
ThangTypes = require 'collections/ThangTypes'
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
    @debouncedRender = _.debounce @render, 0

    @state = new State({
      currentHeroID
      selectedHeroID: currentHeroID
    })

    @heroes = new ThangTypes({}, { project: ['original', 'name', 'heroClass'] })
    @supermodel.trackRequest @heroes.fetchHeroes()

    @listenTo @state, 'all', -> @debouncedRender()
    @listenTo @heroes, 'all', -> @debouncedRender()

  onClickHeroOption: (e) ->
    heroID = $(e.currentTarget).data('hero-id')
    @state.set selectedHeroID: heroID
    hero = @heroes.get(heroID)
    me.set(heroConfig: {}) unless me.get('heroConfig')
    heroConfig = _.assign me.get('heroConfig'), { thangType: hero.get('original') }
    me.set({ heroConfig })
    me.save().then =>
      @trigger 'hero-select:success', hero

  onClickSelectHeroButton: () ->
    @hide()
