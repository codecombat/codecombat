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
    window.nextURL = "/play/ladder/#{@level.get('slug')}?submit=true"
    CreateAccountModal = require 'views/core/CreateAccountModal'
    @openModalView new CreateAccountModal accountRequiredMessage: $.i18n.t('signup.create_account_to_submit_multiplayer')  # Note: may destroy `this` if we were living in another modal

  rankSession: (e) ->
    return unless @session.readyToRank()
    return @showApologeticSignupModal() if me.get('anonymous')
    @playSound 'menu-button-click'
    @setRankingButtonText 'submitting'
    if currentAge = me.age()
      @session.set 'creatorAge', currentAge
    success = =>
      @setRankingButtonText 'submitted' unless @destroyed
      Backbone.Mediator.publish 'ladder:game-submitted', session: @session, level: @level
      @submittingInProgress = false
      if @destroyed
        @session = @level = @mirrorSession = @submittingInProgress = undefined
    failure = (jqxhr, textStatus, errorThrown) =>
      console.log jqxhr.responseText
      @setRankingButtonText 'failed' unless @destroyed
      @submittingInProgress = false
      if @destroyed
        @session = @level = @mirrorSession = @submittingInProgress = undefined
    @submittingInProgress = true
    tempSession = @session.clone() # do not modify @session here
    if @level.isType('ladder') and tempSession.get('team') is 'ogres'
      code = tempSession.get('code') ? {'hero-placeholder': {plan:''}, 'hero-placeholder-1': {plan: ''}}
      tempSession.set('team', 'humans')
      code['hero-placeholder'] = JSON.parse(JSON.stringify(code['hero-placeholder-1']))
      tempSession.set('code', code)
    tempSession.save null, success: =>
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
        if tempSession.get('team') is 'humans'
          mirrorCode['hero-placeholder-1'] = tempSession.get('code')['hero-placeholder']
        else
          mirrorCode['hero-placeholder'] = tempSession.get('code')['hero-placeholder-1']
        mirrorAjaxOptions = _.clone ajaxOptions
        mirrorAjaxOptions.data = mirrorAjaxData
        ajaxOptions.success = =>
          patch = code: mirrorCode, codeLanguage: tempSession.get('codeLanguage')
          tempMirrorSession = new LevelSession _id: @mirrorSession.id
          tempMirrorSession.save patch, patch: true, type: 'PUT', success: ->
            $.ajax '/queue/scoring', mirrorAjaxOptions
      $.ajax '/queue/scoring', ajaxOptions

  onHelpSimulate: ->
    @playSound 'menu-button-click'
    $('a[href="#simulate"]').tab('show')

  destroy: ->
    # Atypical: if we are destroyed mid-submission, keep a few locals around to be able to finish it
    if @submittingInProgress
      session = @session
      level = @level
      mirrorSession = @mirrorSession
    super()
    if session
      @session = session
      @level = level
      @mirrorSession = @mirrorSession
      @submittingInProgress = true
