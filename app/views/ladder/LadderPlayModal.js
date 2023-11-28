/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS104: Avoid inline assignments
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let LadderPlayModal
require('app/styles/play/ladder/play_modal.sass')
const ModalView = require('views/core/ModalView')
const template = require('app/templates/play/ladder/play_modal')
const ThangType = require('models/ThangType')
const { me } = require('core/auth')
const LeaderboardCollection = require('collections/LeaderboardCollection')
const { teamDataFromLevel } = require('./utils')
const { isCodeCombat } = require('core/utils')

module.exports = (LadderPlayModal = (function () {
  LadderPlayModal = class LadderPlayModal extends ModalView {
    static initClass () {
      this.prototype.id = 'ladder-play-modal'
      this.prototype.template = template
      this.prototype.closeButton = true
      this.shownTutorialButton = false
      this.prototype.tutorialLevelExists = null

      this.prototype.events = {
        'click #skip-tutorial-button': 'hideTutorialButtons',
        'change #tome-language': 'updateLanguage'
      }

      this.prototype.defaultAceConfig = {
        language: 'javascript',
        keyBindings: 'default',
        invisibles: false,
        indentGuides: false,
        behaviors: false,
        liveCompletion: true
      }
    }

    constructor (options, level, session, team) {
      super(options)
      let left, left1
      this.level = level
      this.session = session
      this.team = team
      this.otherTeam = this.team === 'ogres' ? 'humans' : 'ogres'
      if (isCodeCombat) {
        if (this.level.isType('ladder')) { this.otherTeam = 'humans' }
      }
      this.wizardType = ThangType.loadUniversalWizard()
      this.startLoadingChallengersMaybe()
      this.levelID = this.level.get('slug') || this.level.id
      this.language = (left = (left1 = this.session?.get('codeLanguage')) != null ? left1 : me.get('aceConfig')?.language) != null ? left : 'python'
      this.languages = [
        { id: 'python', name: 'Python' },
        { id: 'javascript', name: 'JavaScript' },
        { id: 'coffeescript', name: 'CoffeeScript' },
        { id: 'lua', name: 'Lua' },
        { id: 'cpp', name: 'C++' },
        { id: 'java', name: 'Java (Experimental)' }
      ]
      this.myName = me.get('name') || 'Newcomer'

      const teams = []
      for (const t of teamDataFromLevel(this.level)) { teams[t.id] = t }
      this.teamColor = teams[this.team].primaryColor
      this.teamBackgroundColor = teams[this.team].bgColor
      this.opponentTeamColor = teams[this.otherTeam].primaryColor
      this.opponentTeamBackgroundColor = teams[this.otherTeam].bgColor
    }

    updateLanguage () {
      let left
      let aceConfig = _.cloneDeep((left = me.get('aceConfig')) != null ? left : {})
      aceConfig = _.defaults(aceConfig, this.defaultAceConfig)
      aceConfig.language = this.$el.find('#tome-language').val()
      me.set('aceConfig', aceConfig)
      me.patch()
      if (this.session) {
        this.session.set('codeLanguage', aceConfig.language)
        if (isCodeCombat) {
          return this.session.save({ codeLanguage: aceConfig.language }, { patch: true, type: 'PUT' })
        } else {
          return this.session.patch()
        }
      }
    }

    // PART 1: Load challengers from the db unless some are in the matches
    startLoadingChallengersMaybe () {
      let matches
      if (this.options.league) {
        matches = _.find(this.session?.get('leagues'), { leagueID: this.options.league.id })?.stats.matches
      } else {
        matches = this.session?.get('matches')
      }
      if (matches?.length) { return this.loadNames() } else { return this.loadChallengers() }
    }

    loadChallengers () {
      this.challengersCollection = new ChallengersData(this.level, this.team, this.otherTeam, this.session, this.options.league)
      return this.listenTo(this.challengersCollection, 'sync', this.loadNames)
    }

    // PART 2: Loading the names of the other users

    loadNames () {
      let challenger
      this.challengers = this.getChallengers()
      const ids = ((() => {
        const result = []
        for (challenger of _.values(this.challengers)) {
          result.push(challenger.opponentID)
        }
        return result
      })())

      for (challenger of _.values(this.challengers)) {
        if (!challenger || !this.wizardType.loaded) { continue }
        if ((!challenger.opponentImageSource) && challenger.opponentWizard?.colorConfig) {
          challenger.opponentImageSource = this.wizardType.getPortraitSource(
            { colorConfig: challenger.opponentWizard.colorConfig })
        }
      }

      const success = nameMap => {
        // it seems to be fix that could go to both
        this.nameMap = nameMap
        if (this.destroyed) { return }
        for (challenger of _.values(this.challengers)) {
          challenger.opponentName = this.nameMap[challenger.opponentID]?.name || 'Anonymous'
          challenger.opponentWizard = this.nameMap[challenger.opponentID]?.wizard || {}
        }
        return this.checkWizardLoaded()
      }

      const data = { ids, wizard: true }
      if (this.options.league) {
        data.leagueId = this.options.league.id
      }
      const userNamesRequest = this.supermodel.addRequestResource('user_names', {
        url: '/db/user/-/getFullNames',
        data,
        method: 'POST',
        success
      }, 0)
      return userNamesRequest.load()
    }

    // PART 3: Make sure wizard is loaded

    checkWizardLoaded () {
      if (this.wizardType.loaded) { return this.finishRendering() } else { return this.listenToOnce(this.wizardType, 'sync', this.finishRendering) }
    }

    // PART 4: Render

    finishRendering () {
      if (this.destroyed) { return }
      this.checkTutorialLevelExists(exists => {
        if (this.destroyed) { return }
        this.tutorialLevelExists = exists
        this.render()
        return this.maybeShowTutorialButtons()
      })
      this.genericPortrait = this.wizardType.getPortraitSource()
      const myColorConfig = me.get('wizard')?.colorConfig
      this.myPortrait = myColorConfig ? this.wizardType.getPortraitSource({ colorConfig: myColorConfig }) : this.genericPortrait
    }

    maybeShowTutorialButtons () {
      if (this.session || LadderPlayModal.shownTutorialButton || !this.tutorialLevelExists) { return }
      this.$el.find('#normal-view').addClass('secret')
      this.$el.find('.modal-header').addClass('secret')
      this.$el.find('#noob-view').removeClass('secret')
      LadderPlayModal.shownTutorialButton = true
    }

    hideTutorialButtons () {
      this.$el.find('#normal-view').removeClass('secret')
      this.$el.find('.modal-header').removeClass('secret')
      return this.$el.find('#noob-view').addClass('secret')
    }

    checkTutorialLevelExists (cb) {
      if (isCodeCombat) {
        return // We don't have any tutorials, currently. TODO: should remove this or update to create more tutorials.
      }
      const levelID = this.level.get('slug') || this.level.id
      const tutorialLevelID = `${levelID}-tutorial`
      const success = () => cb(true) // eslint-disable-line n/no-callback-literal
      const failure = () => cb(false) // eslint-disable-line n/no-callback-literal
      return $.ajax({
        type: 'GET',
        url: `/db/level/${tutorialLevelID}/exists`,
        success,
        error: failure
      })
    }

    // Choosing challengers

    getChallengers () {
      // make an object of challengers to everything needed to link to them
      let easyInfo, hardInfo, mediumInfo
      let m
      const challengers = {}
      if (this.challengersCollection) {
        easyInfo = this.challengeInfoFromSession(this.challengersCollection.easyPlayer.models[0])
        mediumInfo = this.challengeInfoFromSession(this.challengersCollection.mediumPlayer.models[0])
        hardInfo = this.challengeInfoFromSession(this.challengersCollection.hardPlayer.models[0])
      } else {
        let matches
        if (this.options.league) {
          matches = _.find(this.session?.get('leagues'), { leagueID: this.options.league.id })?.stats.matches
        } else {
          matches = this.session?.get('matches')
        }
        const won = ((() => {
          const result = []
          for (m of matches) {
            if (m.metrics.rank < m.opponents[0].metrics.rank) {
              result.push(m)
            }
          }
          return result
        })())
        const lost = ((() => {
          const result1 = []
          for (m of matches) {
            if (m.metrics.rank > m.opponents[0].metrics.rank) {
              result1.push(m)
            }
          }
          return result1
        })())
        const tied = ((() => {
          const result2 = []
          for (m of matches) {
            if (m.metrics.rank === m.opponents[0].metrics.rank) {
              result2.push(m)
            }
          }
          return result2
        })())
        easyInfo = this.challengeInfoFromMatches(won)
        mediumInfo = this.challengeInfoFromMatches(tied)
        hardInfo = this.challengeInfoFromMatches(lost)
      }
      this.addChallenger(easyInfo, challengers, 'easy')
      this.addChallenger(mediumInfo, challengers, 'medium')
      this.addChallenger(hardInfo, challengers, 'hard')
      return challengers
    }

    addChallenger (info, challengers, title) {
      // check for duplicates first
      if (!info) { return }
      for (const key in challengers) {
        const value = challengers[key]
        if (value.sessionID === info.sessionID) { return }
      }
      challengers[title] = info
      return challengers[title]
    }

    challengeInfoFromSession (session) {
      // given a model from the db, return info needed for a link to the match
      if (!session) { return }
      return {
        sessionID: session.id,
        opponentID: session.get('creator'),
        codeLanguage: session.get('submittedCodeLanguage')
      }
    }

    challengeInfoFromMatches (matches) {
      if (!matches?.length) { return }
      const match = _.sample(matches)
      const opponent = match.opponents[0]
      return {
        sessionID: opponent.sessionID,
        opponentID: opponent.userID,
        codeLanguage: opponent.codeLanguage
      }
    }
  }
  LadderPlayModal.initClass()
  return LadderPlayModal
})())

class ChallengersData {
  constructor (level, team, otherTeam, session, league) {
    let score
    this.level = level
    this.team = team
    this.otherTeam = otherTeam
    this.session = session
    this.league = league
    _.extend(this, Backbone.Events)
    if (this.league) {
      score = _.find(this.session?.get('leagues'), { leagueID: this.league.id })?.stats?.totalScore || 10
    } else {
      score = this.session?.get('totalScore') || 10
    }
    for (const player of [
      { type: 'easyPlayer', order: 1, scoreOffset: score - 5 },
      { type: 'mediumPlayer', order: 1, scoreOffset: score },
      { type: 'hardPlayer', order: -1, scoreOffset: score + 5 }
    ]) {
      const playerResource = (this[player.type] = new LeaderboardCollection(this.level, this.collectionParameters({ order: player.order, scoreOffset: player.scoreOffset })))
      playerResource.fetch({ cache: false })
      this.listenToOnce(playerResource, 'sync', this.challengerLoaded)
    }
  }

  collectionParameters (parameters) {
    parameters.team = this.otherTeam
    parameters.limit = 1
    if (this.league) { parameters['leagues.leagueID'] = this.league.id }
    return parameters
  }

  challengerLoaded () {
    if (this.allLoaded()) {
      this.loaded = true
      return this.trigger('sync')
    }
  }

  playerIDs () {
    const collections = [this.easyPlayer, this.mediumPlayer, this.hardPlayer]
    return (collections.filter((c) => c?.models[0]).map((c) => c.models[0].get('creator')))
  }

  allLoaded () {
    return _.all([this.easyPlayer.loaded, this.mediumPlayer.loaded, this.hardPlayer.loaded])
  }
}
