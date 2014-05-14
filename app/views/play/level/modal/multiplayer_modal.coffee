View = require 'views/kinds/ModalView'
template = require 'templates/play/level/modal/multiplayer'
{me} = require('lib/auth')

module.exports = class MultiplayerModal extends View
  id: 'level-multiplayer-modal'
  template: template

  events:
    'click textarea': 'onClickLink'
    'change #multiplayer': 'updateLinkSection'
    'click .rank-game-button': 'onRankGame'

  constructor: (options) ->
    super(options)
    @session = options.session
    @level = options.level
    @listenTo(@session, 'change:multiplayer', @updateLinkSection)
    @playableTeams = options.playableTeams

  getRenderData: ->
    c = super()
    c.joinLink = (document.location.href.replace(/\?.*/, '').replace('#', '') +
      '?session=' +
      @session.id)
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

  onClickLink: (e) ->
    e.target.select()

  updateLinkSection: ->
    multiplayer = @$el.find('#multiplayer').prop('checked')
    la = @$el.find('#link-area')
    la.toggle Boolean(multiplayer)
    true

  onHidden: ->
    multiplayer = Boolean(@$el.find('#multiplayer').prop('checked'))
    @session.set('multiplayer', multiplayer)

  onRankGame: (e) ->
    button = @$el.find('.rank-game-button')
    button.text($.i18n.t('play_level.victory_ranking_game', defaultValue: 'Submitting...'))
    button.prop 'disabled', true
    ajaxData = 
      session: @session.id
      levelID: @level.id
      originalLevelID: @level.get('original')
      levelMajorVersion: @level.get('version').major
      transpiledCode: @transpileSession(@session)
    ladderURL = "/play/ladder/#{@level.get('slug')}#my-matches"
    goToLadder = -> Backbone.Mediator.publish 'router:navigate', route: ladderURL
    $.ajax '/queue/scoring',
      type: 'POST'
      data: ajaxData
      success: goToLadder
      failure: (response) ->
        console.error "Couldn't submit game for ranking:", response
        goToLadder()
  
  transpileSession: (session) ->
    submittedCode = session.get('code')
    transpiledCode = {}
    for thang, spells of submittedCode
      transpiledCode[thang] = {}
      for spellID, spell of spells
        #DRY this
        aetherOptions =
          problems: {}
          language: "javascript"
          functionName: spellID
          functionParameters: []
          yieldConditionally: spellID is "plan"
          globals: ['Vector', '_']
          protectAPI: true
          includeFlow: false
        if spellID is "hear" then aetherOptions["functionParameters"] = ["speaker","message","data"]

        aether = new Aether aetherOptions
        transpiledCode[thang][spellID] = aether.transpile spell
    transpiledCode
    
  destroy: ->
    super()
