/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS201: Simplify complex destructure assignments
 * DS206: Consider reworking classes to avoid initClass
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let AnonCertificatesView
require('app/styles/user/certificates-view.sass')
const RootView = require('views/core/RootView')
const User = require('models/User')
const LevelSession = require('models/LevelSession')
const Levels = require('collections/Levels')
const Level = require('models/Level')
const utils = require('core/utils')

// This certificate is generated anonymously. This requires the certificate
// to be generated only from query params.
// Requires campaign slug query param as well as username param.
module.exports = (AnonCertificatesView = (function () {
  AnonCertificatesView = class AnonCertificatesView extends RootView {
    static initClass () {
      this.prototype.id = 'certificates-view'
      this.prototype.template = require('templates/user/certificates-anon-view.pug')

      this.prototype.events =
        { 'click .print-btn': 'onClickPrintButton' }
    }

    initialize (options, userId) {
      this.loading = true
      const user = new User({ _id: userId })
      const userPromise = user.fetch()
      const campaignSlug = utils.getQueryVariable('campaign')
      this.name = utils.getQueryVariable('username')
      const levelsPromise = (new Levels()).fetchForCampaign(campaignSlug, {})
      const sessionsPromise = levelsPromise
        .then(l => {
          return Promise.all(
            l.map(x => x._id)
              .map(this.fetchLevelSession)
          )
        })

      // Initial data.
      this.courseStats = {
        levels: {
          numDone: 0
        },
        linesOfCode: 0,
        courseComplete: true
      }

      return Promise.all([userPromise, levelsPromise, sessionsPromise])
        .then((...args) => {
          let [u, l, ls] = Array.from(args[0]) // eslint-disable-line no-unused-vars
          ls = ls.map(data => new LevelSession(data))
          l = l.map(data => new Level(data))
          this.concepts = this.loadConcepts(l)
          this.courseStats = this.reduceSessionStats(ls, l)
          this.loading = false
          return this.render()
        })
    }

    backgroundImage () {
      return '/images/pages/user/certificates/backgrounds/background-hoc.png'
    }

    getMedallion () {
      return '/images/pages/user/certificates/medallions/medallion-gd3.png'
    }

    onClickPrintButton () {
      return window.print()
    }

    userName () {
      return this.name || 'Lorem Ipsum Name'
    }

    getCodeLanguageName () {
      return 'Python'
    }

    loadConcepts (levels) {
      const allConcepts = levels
        .map(l => l.get('concepts'))
        .reduce((m, c) => {
          return m.concat(c)
        }
        , [])

      const concepts = [];
      (new Set(allConcepts))
        .forEach(v => concepts.push(v))
      return concepts
    }

    getConcepts () {
      return this.concepts
    }

    fetchLevelSession (levelID) {
      const url = `/db/level/${levelID}/session`
      const session = new LevelSession()
      return session.fetch({ url })
    }

    reduceSessionStats (sessions, levels) {
      return sessions.reduce((stats, ls, i) => {
        stats.levels.numDone += 1
        stats.linesOfCode += ls.countOriginalLinesOfCode(levels[i])
        return stats
      }
      , this.courseStats)
    }
  }
  AnonCertificatesView.initClass()
  return AnonCertificatesView
})())
