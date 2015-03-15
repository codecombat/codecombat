CocoView = require 'views/core/CocoView'
template = require 'templates/play/common/ladder_submission'
{createAetherOptions} = require 'lib/aether_utils'

module.exports = class LadderSubmissionView extends CocoView
  className: 'ladder-submission-view'
  template: template

  events:
    'click .rank-button': 'rankSession'
    'click .help-simulate': 'onHelpSimulate'

  constructor: (options) ->
    super options
    @session = options.session
    @level = options.level

  getRenderData: ->
    ctx = super()
    ctx.readyToRank = @session?.readyToRank()
    ctx.isRanking = @session?.get('isRanking')
    ctx.simulateURL = "/play/ladder/#{@level.get('slug')}#simulate"
    ctx.lastSubmitted = moment(submitDate).fromNow() if submitDate = @session?.get('submitDate')
    ctx

  afterRender: ->
    super()
    return unless @supermodel.finished()
    @rankButton = @$el.find('.rank-button')
    @updateButton()

  updateButton: ->
    rankingState = 'unavailable'
    if @session?.readyToRank()
      rankingState = 'rank'
    else if @session?.get 'isRanking'
      rankingState = 'ranking'
    @setRankingButtonText rankingState

  setRankingButtonText: (spanClass) ->
    @rankButton.find('span').hide()
    @rankButton.find(".#{spanClass}").show()
    @rankButton.toggleClass 'disabled', spanClass isnt 'rank'
    helpSimulate = spanClass in ['submitted', 'ranking']
    @$el.find('.help-simulate').toggle(helpSimulate, 'slow')
    showLastSubmitted = not (spanClass in ['submitting'])
    @$el.find('.last-submitted').toggle(showLastSubmitted)

  rankSession: (e) ->
    return unless @session.readyToRank()
    @playSound 'menu-button-click'
    @setRankingButtonText 'submitting'
    success = =>
      @setRankingButtonText 'submitted' unless @destroyed
      Backbone.Mediator.publish 'ladder:game-submitted', session: @session, level: @level
    failure = (jqxhr, textStatus, errorThrown) =>
      console.log jqxhr.responseText
      @setRankingButtonText 'failed' unless @destroyed
    @transpileSession (transpiledCode) =>

      ajaxData =
        session: @session.id
        levelID: @level.id
        originalLevelID: @level.get('original')
        levelMajorVersion: @level.get('version').major
        transpiledCode: transpiledCode

      $.ajax '/queue/scoring', {
        type: 'POST'
        data: ajaxData
        success: success
        error: failure
      }

  transpileSession: (callback) ->
    submittedCode = @session.get('code')
    codeLanguage = @session.get('codeLanguage') or 'javascript'
    @session.set('submittedCodeLanguage', codeLanguage)
    transpiledCode = {}
    for thang, spells of submittedCode
      transpiledCode[thang] = {}
      for spellID, spell of spells
        unless _.contains(@session.get('teamSpells')[@session.get('team')], thang + '/' + spellID) then continue
        aetherOptions = createAetherOptions functionName: spellID, codeLanguage: codeLanguage
        aether = new Aether aetherOptions
        transpiledCode[thang][spellID] = aether.transpile spell
    @session.save null, success: -> callback transpiledCode

  onHelpSimulate: ->
    @playSound 'menu-button-click'
    $('a[href="#simulate"]').tab('show')
