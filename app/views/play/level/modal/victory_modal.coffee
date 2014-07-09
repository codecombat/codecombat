View = require 'views/kinds/ModalView'
template = require 'templates/play/level/modal/victory'
{me} = require 'lib/auth'
LadderSubmissionView = require 'views/play/common/ladder_submission_view'
LevelFeedback = require 'models/LevelFeedback'
utils = require 'lib/utils'

module.exports = class VictoryModal extends View
  id: 'level-victory-modal'
  template: template

  subscriptions:
    'ladder:game-submitted': 'onGameSubmitted'

  events:
    'click .next-level-button': 'onPlayNextLevel'

    # review events
    'mouseover .rating i': (e) -> @showStars(@starNum($(e.target)))
    'mouseout .rating i': -> @showStars()
    'click .rating i': (e) ->
      @setStars(@starNum($(e.target)))
      @$el.find('.review').show()
    'keypress .review textarea': -> @saveReviewEventually()

  shortcuts:
    'enter': -> 'onPlayNextLevel'

  constructor: (options) ->
    victory = options.level.get('victory')
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
    @feedback.url = -> url
    @feedback.fetch()
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

  onPlayNextLevel: ->
    @saveReview() if @$el.find('.review textarea').val()
    Backbone.Mediator.publish('play-next-level')

  onGameSubmitted: (e) ->
    ladderURL = "/play/ladder/#{@level.get('slug')}#my-matches"
    Backbone.Mediator.publish 'router:navigate', route: ladderURL

  getRenderData: ->
    c = super()
    c.body = @body
    c.me = me
    c.hasNextLevel = _.isObject(@level.get('nextLevel'))
    c.levelName = utils.i18n @level.attributes, 'name'
    c.level = @level
    if c.level.get('type') is 'ladder'
      c.readyToRank = @session.readyToRank()
    if me.get 'hourOfCode'
      # Show the Hour of Code "I'm Done" tracking pixel after they played for 30 minutes
      elapsed = (new Date() - new Date(me.get('dateCreated')))
      enough = not c.hasNextLevel or elapsed >= 30 * 60 * 1000
      if enough and not me.get('hourOfCodeComplete')
        $('body').append($('<img src="http://code.org/api/hour/finish_codecombat.png" style="visibility: hidden;">'))
        me.set 'hourOfCodeComplete', true
        me.patch()
        window.tracker?.trackEvent 'Hour of Code Finish', {}
      # Show the "I'm done" button if they get to the end, unless it's been over two hours
      tooMuch = elapsed >= 120 * 60 * 1000
      c.showHourOfCodeDoneButton = not c.hasNextLevel and not tooMuch
    c

  afterRender: ->
    super()
    @ladderSubmissionView = new LadderSubmissionView session: @session, level: @level
    @insertSubView @ladderSubmissionView, @$el.find('.ladder-submission-view')

  afterInsert: ->
    super()
    Backbone.Mediator.publish 'play-sound', trigger: 'victory'
    gapi?.plusone?.go? @$el[0]
    FB?.XFBML?.parse? @$el[0]
    twttr?.widgets?.load?()

  onHidden: ->
    Backbone.Mediator.publish 'level:victory-hidden'

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
