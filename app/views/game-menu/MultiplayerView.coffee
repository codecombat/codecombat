CocoView = require 'views/kinds/CocoView'
template = require 'templates/game-menu/multiplayer-view'
{me} = require 'lib/auth'
ThangType = require 'models/ThangType'
LadderSubmissionView = require 'views/play/common/LadderSubmissionView'

module.exports = class MultiplayerView extends CocoView
  id: 'multiplayer-view'
  className: 'tab-pane'
  template: template

  subscriptions:
    'ladder:game-submitted': 'onGameSubmitted'

  events:
    'click textarea': 'onClickLink'
    'change #multiplayer': 'updateLinkSection'

  constructor: (options) ->
    super(options)
    @level = options.level
    @session = options.session
    @playableTeams = options.playableTeams
    @listenTo @session, 'change:multiplayer', @updateLinkSection

  getRenderData: ->
    c = super()
    c.joinLink = "#{document.location.href.replace(/\?.*/, '').replace('#', '')}?session=#{@session.id}"
    c.multiplayer = @session.get 'multiplayer'
    c.team = @session.get 'team'
    c.levelSlug = @level?.get 'slug'
    c.playableTeams = @playableTeams
    # For now, ladderGame will disallow multiplayer, because session code combining doesn't play nice yet.
    if @level?.get('type') is 'ladder'
      c.ladderGame = true
      c.readyToRank = @session?.readyToRank()
    c

  afterRender: ->
    super()
    @updateLinkSection()
    @ladderSubmissionView = new LadderSubmissionView session: @session, level: @level
    @insertSubView @ladderSubmissionView, @$el.find('.ladder-submission-view')

  onClickLink: (e) ->
    e.target.select()

  onGameSubmitted: (e) ->
    ladderURL = "/play/ladder/#{@level.get('slug')}#my-matches"
    Backbone.Mediator.publish 'router:navigate', route: ladderURL

  updateLinkSection: ->
    multiplayer = @$el.find('#multiplayer').prop('checked')
    la = @$el.find('#link-area')
    la.toggle Boolean(multiplayer)
    true

  onHidden: ->
    multiplayer = Boolean(@$el.find('#multiplayer').prop('checked'))
    @session.set('multiplayer', multiplayer)
