View = require 'views/kinds/ModalView'
template = require 'templates/play/level/modal/victory'
{me} = require 'lib/auth'
LevelFeedback = require 'models/LevelFeedback'

# let's implement this once we have the docs database schema set up

module.exports = class VictoryModal extends View
  id: 'level-victory-modal'
  template: template

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
    body = victory?.i18n?[me.lang()]?.body or victory.body or 'Sorry, this level has no victory message yet.'
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
    @feedback.once 'sync', => @onFeedbackLoaded()
    @feedback.once 'error', => @onFeedbackNotFound()

  onFeedbackLoaded: ->
    @feedback.url = -> '/db/level.feedback/' + @id
    @$el.find('.review textarea').val(@feedback.get('review'))
    @$el.find('.review').show()
    @showStars()

  onFeedbackNotFound: ->
    @feedback = new LevelFeedback()
    @feedback.set('levelID', @level.get('slug') or @level.id)
    @feedback.set('levelName', @level.get('name') or '')
    @feedback.set('level', {majorVersion: @level.get('version').major, original:@level.get('original')})
    @showStars()

  onPlayNextLevel: ->
    @saveReview() if @$el.find('.review textarea').val()
    Backbone.Mediator.publish('play-next-level')

  getRenderData: ->
    c = super()
    c.body = @body
    c.me = me
    c.hasNextLevel = _.isObject(@level.get('nextLevel')) and (@level.get('name') isnt "Mobile Artillery")
    c.levelName = @level.get('i18n')?[me.lang()]?.name ? @level.get('name')
    if me.get 'hourOfCode'
      # Show the Hour of Code "I'm Done" tracking pixel after they played for 30 minutes
      elapsed = (new Date() - new Date(me.get('dateCreated')))
      enough = not c.hasNextLevel or elapsed >= 30 * 60 * 1000
      if enough and not me.get('hourOfCodeComplete')
        $('body').append($("<img src='http://code.org/api/hour/finish_codecombat.png' style='visibility: hidden;'>"))
        me.set 'hourOfCodeComplete', true
        me.save()
        window.tracker?.trackEvent 'Hour of Code Finish', {}
      # Show the "I'm done" button if they get to the end, unless it's been over two hours
      tooMuch = elapsed >= 120 * 60 * 1000
      c.showHourOfCodeDoneButton = not c.hasNextLevel and not tooMuch

    if c.hasNextLevel and me.lang().split('-')[0] is 'en'
      # A/B test "Unlock Next Level" vs. "Play Next Level"
      unlock = Boolean(me.get('testGroupNumber') & 2)  # 2, 3, 6, 7, 10, 11, ...
      text = if unlock then "Unlock Next Level" else "Play Next Level"
      window.tracker?.trackEvent 'Next Level Text', text: text
      window.tracker?.identify {nextLevelText: text}
      c.nextLevelText = text
    c

  afterRender: ->
    super()

  afterInsert: ->
    super()
    Backbone.Mediator.publish 'play-sound', trigger: "victory"
    gapi?.plusone?.go? @$el[0]
    FB?.XFBML?.parse? @$el[0]
    twttr?.widgets?.load?()

  onHidden: ->
    Backbone.Mediator.publish 'level:victory-hidden'

  destroy: ->
    super()
    @saveReview() if @$el.find('.review textarea').val()

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
