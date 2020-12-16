CocoView = require 'views/core/CocoView'
template = require 'templates/play/common/ladder_submission'
{createAetherOptions} = require 'lib/aether_utils'
LevelSession = require 'models/LevelSession'

module.exports = class LadderSubmissionView extends CocoView
  className: 'ladder-submission-view'
  template: template

  events:
    'click .rank-button': 'rankSession'
    'click .help-simulate': 'onHelpSimulate'

  constructor: (options) ->
    super options
    @session = options.session
    @mirrorSession = options.mirrorSession
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

  showApologeticSignupModal: ->
    CreateAccountModal = require 'views/core/CreateAccountModal'
    @openModalView(new CreateAccountModal({showRequiredError: true}))

  rankSession: (e) ->
    return unless @session.readyToRank()
    return @showApologeticSignupModal() if me.get('anonymous')
    @playSound 'menu-button-click'
    @setRankingButtonText 'submitting'
    success = =>
      @setRankingButtonText 'submitted' unless @destroyed
      Backbone.Mediator.publish 'ladder:game-submitted', session: @session, level: @level
    failure = (jqxhr, textStatus, errorThrown) =>
      console.log jqxhr.responseText
      @setRankingButtonText 'failed' unless @destroyed
    @session.save null, success: =>
      ajaxData =
        session: @session.id
        levelID: @level.id
        originalLevelID: @level.get('original')
        levelMajorVersion: @level.get('version').major
      ajaxOptions =
        type: 'POST'
        data: ajaxData
        success: success
        error: failure
      if @mirrorSession
        # Also submit the mirrorSession after the main session submits successfully.
        mirrorAjaxData = _.clone ajaxData
        mirrorAjaxData.session = @mirrorSession.id
        mirrorCode = @mirrorSession.get('code') ? {}
        if @session.get('team') is 'humans'
          mirrorCode['hero-placeholder-1'] = @session.get('code')['hero-placeholder']
        else
          mirrorCode['hero-placeholder'] = @session.get('code')['hero-placeholder-1']
        mirrorAjaxOptions = _.clone ajaxOptions
        mirrorAjaxOptions.data = mirrorAjaxData
        ajaxOptions.success = =>
          patch = code: mirrorCode, codeLanguage: @session.get('codeLanguage')
          tempSession = new LevelSession _id: @mirrorSession.id
          tempSession.save patch, patch: true, type: 'PUT', success: ->
            $.ajax '/queue/scoring', mirrorAjaxOptions

      $.ajax '/queue/scoring', ajaxOptions

  onHelpSimulate: ->
    @playSound 'menu-button-click'
    $('a[href="#simulate"]').tab('show')
