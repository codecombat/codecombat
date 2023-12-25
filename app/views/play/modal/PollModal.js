/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS103: Rewrite code to no longer use __guard__, or convert again using --optional-chaining
 * DS104: Avoid inline assignments
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let PollModal
require('app/styles/play/modal/poll-modal.sass')
const ModalView = require('views/core/ModalView')
const template = require('app/templates/play/modal/poll-modal')
const utils = require('core/utils')

module.exports = (PollModal = (function () {
  PollModal = class PollModal extends ModalView {
    static initClass () {
      this.prototype.id = 'poll-modal'
      this.prototype.template = template

      this.prototype.subscriptions = {}

      this.prototype.events = {
        'click #close-modal': 'hide',
        'click .answer:not(.selected)': 'onClickAnswer'
      }
    }

    constructor (options) {
      let left, left1
      super(options)
      this.poll = options.poll
      this.userPollsRecord = options.userPollsRecord
      this.previousAnswer = ((left = this.userPollsRecord.get('polls')) != null ? left : {})[this.poll.id]
      this.previousReward = ((left1 = this.userPollsRecord.get('rewards')) != null ? left1 : {})[this.poll.id]
    }

    getRenderData (c) {
      c = super.getRenderData(c)
      c.poll = this.poll
      c.i18n = utils.i18n
      c.marked = marked
      return c
    }

    afterRender () {
      super.afterRender()
      this.playSound('game-menu-open')
      return this.updateAnswers()
    }

    onHidden () {
      super.onHidden()
      return this.playSound('game-menu-close')
    }

    updateAnswers (answered) {
      let answer, left, votes
      const myAnswer = ((left = this.userPollsRecord.get('polls')) != null ? left : {})[this.poll.id]
      answered = (myAnswer != null)
      this.$el.find('table, .random-gems-container-wrapper').toggleClass('answered', answered)
      if (!answered) { return }
      this.awardRandomGems()

      // Count total votes and find the answer with the most votes.
      let [maxVotes, totalVotes] = Array.from([0, 0])
      for (answer of Array.from(this.poll.get('answers') || [])) {
        votes = answer.votes || 0
        if (answer.key === this.previousAnswer) { --votes }
        if (answer.key === myAnswer) { ++votes }
        answer.votes = votes
        totalVotes += votes
        maxVotes = Math.max(maxVotes, votes || 0)
      }
      this.previousAnswer = myAnswer
      this.poll.set('answers', this.poll.get('answers')) // Update vote count locally (won't save to server).

      // Update each answer cell according to its share of max and total votes.
      for (answer of Array.from(this.poll.get('answers'))) {
        const $answer = this.$el.find(`.answer[data-answer='${answer.key}']`)
        $answer.toggleClass('selected', answer.key === myAnswer)
        votes = answer.votes || 0
        if (!totalVotes) { votes = (maxVotes = (totalVotes = 1)) } // If no votes yet, just pretend we voted for the first one.

        const widthPercentage = ((100 * votes) / maxVotes) + '%'
        const votePercentage = Math.round((100 * votes) / totalVotes) + '%'
        $answer.find('.progress-bar').css('width', '0%').animate({ width: widthPercentage }, 'slow')
        $answer.find('.vote-percentage').text(votePercentage)
        if (me.isAdmin()) { $answer.find('.vote-count').text(votes) }
      }

      return this.trigger('vote-updated')
    }

    onClickAnswer (e) {
      let left
      const $selectedAnswer = $(e.target).closest('.answer')
      const pollVotes = (left = this.userPollsRecord.get('polls')) != null ? left : {}
      pollVotes[this.poll.id] = $selectedAnswer.data('answer').toString()
      this.userPollsRecord.set('polls', pollVotes)
      this.updateAnswers(true)
      return this.userPollsRecord.save({ polls: pollVotes }, {
        success: () => {
          let left1
          if (typeof this.awardRandomGems === 'function') {
            this.awardRandomGems()
          }
          if (utils.isOzaria) { return }
          const myAnswer = ((left1 = this.userPollsRecord.get('polls')) != null ? left1 : {})[this.poll.id]
          const answerObj = _.find(this.poll.get('answers'), answer => answer.key === myAnswer) || {}
          const nextPollId = answerObj.nextPoll

          // The following block allows for the user to be indecisive with their answer, updating UI accordingly.
          const btn = this.$el.find('.btn.btn-illustrated.btn-lg.done-button')
          btn.off('click')

          if (answerObj.nextURL) {
            btn.text(i18n.t('common.next'))
            return btn.one('click', () => {
              btn.prop('disabled', true)
              return window.open(answerObj.nextURL, '_blank', 'noopener,noreferrer')
            })
          } else if (nextPollId) {
            btn.text(i18n.t('common.next'))
            return btn.one('click', () => {
              btn.prop('disabled', true)
              if (this.poll.id === '5e84c7a519cb270028516687') {
              // Show live Class Modal
                return this.trigger('trigger-show-live-classes')
              } else {
                return this.trigger('trigger-next-poll', nextPollId)
              }
            })
          } else {
            btn.text(i18n.t('play_level.done'))

            // For code quest modal
            return btn.one('click', () => {
              if (this.poll.id === '5f21e48ec22bdf002922cd8c') {
              // Id of codequest poll
                btn.prop('disabled', true)
                return this.trigger('trigger-codequest-modal')
              }
            })
          }
        }
      })
    }

    awardRandomGems () {
      let left, left1, reward
      if (!(reward = ((left = this.userPollsRecord.get('rewards')) != null ? left : {})[this.poll.id])) { return }
      this.$randomNumber = this.$el.find('#random-number-comment').empty()
      this.$randomGems = this.$el.find('#random-gems-comment').hide()
      this.$totalGems = this.$el.find('#total-gems-comment').hide()
      const commentStart = utils.commentStarts[(left1 = __guard__(me.get('aceConfig'), x => x.language)) != null ? left1 : 'python']
      const randomNumber = reward.random
      const randomGems = Math.ceil(2 * randomNumber * reward.level)
      const totalGems = this.previousReward ? me.gems() : Math.round(me.gems() + randomGems)
      const {
        playSound
      } = this

      if (this.previousReward) {
        utils.replaceText(this.$randomNumber.show(), commentStart + randomNumber.toFixed(7))
        utils.replaceText(this.$randomGems.show(), commentStart + randomGems)
        return utils.replaceText(this.$totalGems.show(), commentStart + totalGems)
      } else {
        let gemNoisesPlayed = 0
        for (let i = 0; i <= 1000; i += 25) {
          (i => {
            this.$randomNumber.queue(function () {
              const number = i === 1000 ? randomNumber : Math.random()
              utils.replaceText($(this), commentStart + number.toFixed(7))
              $(this).dequeue()
              if (Math.random() < (randomGems / 40)) {
                const gemTrigger = 'gem-' + (gemNoisesPlayed % 4) // 4 gem sounds
                ++gemNoisesPlayed
                return playSound(gemTrigger, (0.475 + (i / 2000)))
              }
            })
            return this.$randomNumber.delay(25)
          })(i)
        }
        this.$randomGems.delay(1100).queue(function () {
          utils.replaceText($(this), commentStart + randomGems)
          $(this).show()
          return $(this).dequeue()
        })
        this.$totalGems.delay(1200).queue(function () {
          utils.replaceText($(this), commentStart + totalGems)
          $(this).show()
          return $(this).dequeue()
        })

        this.previousReward = reward
        return _.delay(() => {
          let left2
          if (this.destroyed) { return }
          const earned = (left2 = me.get('earned')) != null ? left2 : {}
          if (earned.gems == null) { earned.gems = 0 }
          earned.gems += randomGems
          me.set('earned', earned)
          return me.trigger('change:earned', me, earned)
        }
        , 1200)
      }
    }
  }
  PollModal.initClass()
  return PollModal
})())

function __guard__ (value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined
}
