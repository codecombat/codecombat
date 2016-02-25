ModalView = require 'views/core/ModalView'
CreateAccountModal = require 'views/core/CreateAccountModal'
template = require 'templates/play/level/modal/victory'
{me} = require 'core/auth'
LadderSubmissionView = require 'views/play/common/LadderSubmissionView'
LevelFeedback = require 'models/LevelFeedback'
utils = require 'core/utils'

module.exports = class VictoryModal extends ModalView
  id: 'level-victory-modal'
  template: template

  subscriptions:
    'ladder:game-submitted': 'onGameSubmitted'

  events:
    'click .sign-up-button': 'onClickSignupButton'

    # review events
    'mouseover .rating i': (e) -> @showStars(@starNum($(e.target)))
    'mouseout .rating i': -> @showStars()
    'click .rating i': (e) ->
      @setStars(@starNum($(e.target)))
      @$el.find('.review').show()
    'keypress .review textarea': -> @saveReviewEventually()

  constructor: (options) ->
    application.router.initializeSocialMediaServices()
    victory = options.level.get('victory', true)
    body = utils.i18n(victory, 'body') or 'Sorry, this level has no victory message yet.'
    @body = marked(body)
    @level = options.level
    @session = options.session
    @saveReviewEventually = _.debounce(@saveReviewEventually, 2000)
    @loadExistingFeedback()
    super options

  loadExistingFeedback: ->
    url = "/db/level/#{@level.id}/feedback"
    @feedback = new LevelFeedback()
    @feedback.setURL url
    @feedback.fetch cache: false
    @listenToOnce(@feedback, 'sync', -> @onFeedbackLoaded())
    @listenToOnce(@feedback, 'error', -> @onFeedbackNotFound())

  onFeedbackLoaded: ->
    @feedback.url = -> '/db/level.feedback/' + @id
    @$el.find('.review textarea').val(@feedback.get('review'))
    @$el.find('.review').show()
    @showStars()

  onFeedbackNotFound: ->
    @feedback = new LevelFeedback()
    @feedback.set('levelID', @level.get('slug') or @level.id)
    @feedback.set('levelName', @level.get('name') or '')
    @feedback.set('level', {majorVersion: @level.get('version').major, original: @level.get('original')})
    @showStars()

  onClickSignupButton: (e) ->
    e.preventDefault()
    window.tracker?.trackEvent 'Started Signup', category: 'Play Level', label: 'Victory Modal', level: @level.get('slug')
    @openModalView new CreateAccountModal()

  onGameSubmitted: (e) ->
    ladderURL = "/play/ladder/#{@level.get('slug')}#my-matches"
    Backbone.Mediator.publish 'router:navigate', route: ladderURL

  getRenderData: ->
    c = super()
    c.body = @body
    c.me = me
    c.levelName = utils.i18n @level.attributes, 'name'
    c.level = @level
    if c.level.get('type') is 'ladder'
      c.readyToRank = @session.readyToRank()
    c

  afterRender: ->
    super()
    @ladderSubmissionView = new LadderSubmissionView session: @session, level: @level
    @insertSubView @ladderSubmissionView, @$el.find('.ladder-submission-view')

  afterInsert: ->
    super()
    @playSound 'victory'
    gapi?.plusone?.go? @$el[0]
    FB?.XFBML?.parse? @$el[0]
    twttr?.widgets?.load?()

  destroy: ->
    @saveReview() if @$el.find('.review textarea').val()
    @feedback.off()
    super()

  # rating, review

  starNum: (starEl) -> starEl.prevAll('i').length + 1

  showStars: (num) ->
    @$el.find('.rating').show()
    num ?= @feedback?.get('rating') or 0
    stars = @$el.find('.rating i')
    stars.removeClass('icon-star').addClass('icon-star-empty')
    stars.slice(0, num).removeClass('icon-star-empty').addClass('icon-star')

  setStars: (num) ->
    @feedback.set('rating', num)
    @feedback.save()

  saveReviewEventually: ->
    @saveReview()

  saveReview: ->
    @feedback.set('review', @$el.find('.review textarea').val())
    @feedback.save()
