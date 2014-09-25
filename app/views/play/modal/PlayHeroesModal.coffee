ModalView = require 'views/kinds/ModalView'
template = require 'templates/play/modal/play-heroes-modal'
CocoCollection = require 'collections/CocoCollection'
ThangType = require 'models/ThangType'
#HeroView = require 'views/game-menu/HeroView'

module.exports = class PlayHeroesModal extends ModalView
  className: 'modal fade play-modal'
  template: template
  modalWidthPercent: 90
  id: 'play-heroes-modal'
  #instant: true

  #events:
  #  'change input.select': 'onSelectionChanged'

  constructor: (options) ->
    super options
    @heroes = new CocoCollection([], {model: ThangType})
    @heroes.url = '/db/thang.type?view=heroes&project=name,description,components,original,rasterIcon'
    @supermodel.loadCollection(@heroes, 'heroes')

  getRenderData: (context={}) ->
    context = super(context)
    context.heroes = @heroes.models
    context

  afterRender: ->
    super()
    return unless @supermodel.finished()
    Backbone.Mediator.publish 'audio-player:play-sound', trigger: 'game-menu-open', volume: 1
    #@addHeroViews()

  onHidden: ->
    super()
    Backbone.Mediator.publish 'audio-player:play-sound', trigger: 'game-menu-close', volume: 1

  #addHeroViews: ->
  #  keys = (hero.id for hero in @heroes.models)
  #  heroMap = _.zipObject keys, @heroes.models
  #  for heroStub in @$el.find('.replace-me')
  #    heroID = $(heroStub).data('hero-id')
  #    hero = heroMap[heroID]
  #    heroView = new HeroView({hero: hero, includes: {name: true, stats: true, props: true}})
  #    heroView.render()
  #    $(heroStub).replaceWith(heroView.$el)
  #    @registerSubView(heroView)
