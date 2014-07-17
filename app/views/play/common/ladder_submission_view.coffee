CocoView = require 'views/kinds/CocoView'
template = require 'templates/play/common/ladder_submission'

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
    @setRankingButtonText 'submitting'
    success = =>
      @setRankingButtonText 'submitted' unless @destroyed
      Backbone.Mediator.publish 'ladder:game-submitted', session: @session, level: @level
    failure = (jqxhr, textStatus, errorThrown) =>
      console.log jqxhr.responseText
      @setRankingButtonText 'failed' unless @destroyed
    transpiledCode = @transpileSession()

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

  transpileSession: ->
    submittedCode = @session.get('code')
    language = @session.get('codeLanguage') or 'javascript'
    @session.set('submittedCodeLanguage', language)
    @session.save()  # TODO: maybe actually use a callback to make sure this works?
    transpiledCode = {}
    for thang, spells of submittedCode
      transpiledCode[thang] = {}
      for spellID, spell of spells
        unless _.contains(@session.get('teamSpells')[@session.get('team')], thang + '/' + spellID) then continue
        #DRY this
        aetherOptions =
          problems: {}
          language: language
          functionName: spellID
          functionParameters: []
          yieldConditionally: spellID is 'plan'
          globals: ['Vector', '_']
          protectAPI: true
          includeFlow: false
          executionLimit: 1 * 1000 * 1000
        if spellID is 'hear' then aetherOptions.functionParameters = ['speaker', 'message', 'data']
        if spellID is 'makeBid' then aetherOptions.functionParameters = ['tileGroupLetter']
        if spellID is 'findCentroids' then aetherOptions.functionParameters = ['centroids']

        aether = new Aether aetherOptions
        transpiledCode[thang][spellID] = aether.transpile spell
    transpiledCode

  onHelpSimulate: ->
    $('a[href="#simulate"]').tab('show')
