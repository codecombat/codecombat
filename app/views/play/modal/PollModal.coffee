ModalView = require 'views/core/ModalView'
template = require 'templates/play/modal/poll-modal'
utils = require 'core/utils'
UserPollsRecord = require 'models/UserPollsRecord'

module.exports = class PollModal extends ModalView
  id: 'poll-modal'
  template: template

  subscriptions: {}

  events:
    'click #close-modal': 'hide'
    'click .answer:not(.selected)': 'onClickAnswer'

  constructor: (options) ->
    super options
    @poll = options.poll
    @userPollsRecord = options.userPollsRecord
    @previousAnswer = (@userPollsRecord.get('polls') ? {})[@poll.id]
    @previousReward = (@userPollsRecord.get('rewards') ? {})[@poll.id]

  getRenderData: (c) ->
    c = super c
    c.poll = @poll
    c.i18n = utils.i18n
    c.marked = marked
    c

  afterRender: ->
    super()
    @playSound 'game-menu-open'
    @updateAnswers()

  onHidden: ->
    super()
    @playSound 'game-menu-close'

  updateAnswers: (answered) ->
    myAnswer = (@userPollsRecord.get('polls') ? {})[@poll.id]
    answered = myAnswer?
    @$el.find('table, .random-gems-container-wrapper').toggleClass 'answered', answered
    return unless answered
    @awardRandomGems()

    # Count total votes and find the answer with the most votes.
    [maxVotes, totalVotes] = [0, 0]
    for answer in @poll.get('answers') or []
      votes = answer.votes or 0
      --votes if answer.key is @previousAnswer
      ++votes if answer.key is myAnswer
      answer.votes = votes
      totalVotes += votes
      maxVotes = Math.max maxVotes, votes or 0
    @previousAnswer = myAnswer
    @poll.set 'answers', @poll.get('answers')  # Update vote count locally (won't save to server).

    # Update each answer cell according to its share of max and total votes.
    for answer in @poll.get 'answers'
      $answer = @$el.find(".answer[data-answer='#{answer.key}']")
      $answer.toggleClass 'selected', answer.key is myAnswer
      votes = answer.votes or 0
      votes = maxVotes = totalVotes = 1 unless totalVotes  # If no votes yet, just pretend we voted for the first one.

      widthPercentage = (100 * votes / maxVotes) + '%'
      votePercentage = Math.round(100 * votes / totalVotes) + '%'
      $answer.find('.progress-bar').css('width', '0%').animate({width: widthPercentage}, 'slow')
      $answer.find('.vote-percentage').text votePercentage
      $answer.find('.vote-count').text votes if me.isAdmin()

    @trigger 'vote-updated'

  onClickAnswer: (e) ->
    $selectedAnswer = $(e.target).closest('.answer')
    pollVotes = @userPollsRecord.get('polls') ? {}
    pollVotes[@poll.id] = $selectedAnswer.data('answer').toString()
    @userPollsRecord.set 'polls', pollVotes
    @updateAnswers true
    @userPollsRecord.save {polls: pollVotes}, {success: => @awardRandomGems?()}

  awardRandomGems: ->
    return unless reward = (@userPollsRecord.get('rewards') ? {})[@poll.id]
    @$randomNumber = @$el.find('#random-number-comment').empty()
    @$randomGems = @$el.find('#random-gems-comment').hide()
    @$totalGems = @$el.find('#total-gems-comment').hide()
    commentStart = commentStarts[me.get('aceConfig')?.language ? 'python']
    randomNumber = reward.random
    randomGems = Math.ceil 2 * randomNumber * reward.level
    totalGems = if @previousReward then me.gems() else Math.round me.gems() + randomGems
    playSound = @playSound

    if @previousReward
      utils.replaceText @$randomNumber.show(), commentStart + randomNumber.toFixed(7)
      utils.replaceText @$randomGems.show(), commentStart + randomGems
      utils.replaceText @$totalGems.show(), commentStart + totalGems
    else
      gemNoisesPlayed = 0
      for i in [0 .. 1000] by 25
        do (i) =>
          @$randomNumber.queue ->
            number = if i is 1000 then randomNumber else Math.random()
            utils.replaceText $(@), commentStart + number.toFixed(7)
            $(@).dequeue()
            if Math.random() < randomGems / 40
              gemTrigger = 'gem-' + (gemNoisesPlayed % 4)  # 4 gem sounds
              ++gemNoisesPlayed
              playSound gemTrigger, (0.475 + i / 2000)
          @$randomNumber.delay 25
      @$randomGems.delay(1100).queue ->
        utils.replaceText $(@), commentStart + randomGems
        $(@).show()
        $(@).dequeue()
      @$totalGems.delay(1200).queue ->
        utils.replaceText $(@), commentStart + totalGems
        $(@).show()
        $(@).dequeue()

      @previousReward = reward
      _.delay (=>
        return if @destroyed
        earned = me.get('earned') ? {}
        earned.gems += randomGems
        me.set 'earned', earned
        me.trigger 'change:earned'
      ), 1200


commentStarts =
  javascript: '// '
  python: '# '
  coffeescript: '# '
  lua: '-- '
  java: '// '
