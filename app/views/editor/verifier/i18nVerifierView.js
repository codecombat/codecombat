// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS002: Fix invalid constructor
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS206: Consider reworking classes to avoid initClass
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
let I18nVerifierView
require('app/styles/editor/verifier/i18n-verifier-view.sass')
const RootComponent = require('views/core/RootComponent')
const Problem = require('views/play/level/tome/Problem')
const locale = require('locale/locale')
const api = require('core/api')
const co = require('co')
const utils = require('core/utils')

const I18nVerifierComponent = Vue.extend({
  template: require('app/templates/editor/verifier/i18n-verifier-view')(),
  data () {
    return {
      allLocales: Object.keys(locale).concat('rot13'),
      language: 'en',
      levelSlug: null,
      startDay: moment(new Date()).subtract(2, 'weeks').format('YYYY-MM-DD'),
      endDay: moment(new Date()).format('YYYY-MM-DD'),
      partialThreshold: 1,
      completeThreshold: 99,
      countThreshold: 0,
      totalCount: 0,
      messageOrHint: utils.getQueryVariable('messageOrHint') || 'message',
      me,
      serverConfig,
      problemsByLevel: {},
      regexes: [],
      otherRegexes: [],
      displayMode: utils.getQueryVariable('displayMode') || 'human-readable',
      showCampaigns: false,
      showLevels: false,
      showTranslated: true,
      showUntranslated: true,
      campaigns: [],
      selectedCampaign: null,
      selectedLevelSlugs: [],
      loading: true
    }
  },
  computed: {
    exportList () {
      return _(this.problems).filter(p => {
        return (p[this.messageOrHint].length > 0) &&
          (this.percentDifference(p) < this.completeThreshold) &&
          ((p.count / this.totalCount) >= (this.countThreshold / 100))
      })
        .uniq(p => p.trimmed)
        .value()
    },
    problems () {
      return _.sortBy(_.flatten(Object.values(this.problemsByLevel), true), p => -p.count)
    },
    problemCountByLevel () {
      return _.mapValues(this.problemsByLevel, problems => _.reduce(_.map(problems, 'count'), (a, b) => a + b))
    }
  },
  created: co.wrap(function * () {
    this.levelSlug = this.$options.propsData.levelSlug
    this.selectedLevelSlugs = [this.levelSlug]
    yield $.i18n.changeLanguage(this.language)
    yield this.loadCampaigns()
    yield locale.load(this.language)
    this.setupRegexes()
    const newProblems = yield this.getProblems(this.levelSlug)
    this.compareStrings(newProblems)
    return this.loading = false
  }),
  watch: {
    language: co.wrap(function * () {
      yield locale.load(this.language)
      console.log('Finished loading language', this.language)
      this.setupRegexes()
      return this.compareStrings(this.problems)
    }),
    selectedLevelSlugs () {
      this.loading = true
      const promises = []
      for (const slug of Array.from(this.selectedLevelSlugs)) {
        if (!this.problemsByLevel[slug]) {
          promises.push(this.getProblems(slug))
        }
      }
      return Promise.all(promises).then(newProblems => {
        this.loading = false
        return _.defer(() => {
          return this.compareStrings(_.flatten(newProblems))
        })
      })
    },
    messageOrHint () {
      return this.compareStrings(this.problems)
    }
  },
  methods: {
    problemFrequency (problem) {
      return problem.count / this.problemCountByLevel[problem.levelSlug]
    },
    loadCampaigns: co.wrap(function * () {
      this.campaigns = yield api.campaigns.getAll({ project: 'levels' })
      this.selectedCampaign = _.find(this.campaigns, c => c.name === 'Dungeon')
      return Array.from(this.campaigns).map((campaign) =>
        Vue.set(campaign, 'levelsArray', Object.values(campaign.levels)))
    }),
    setupRegexes () {
      let translationKey
      const en = locale.en.translation
      // Call require like this to prevent preload.js from trying to load app/locale.js which doesn't exist
      const otherLang = locale[this.language].translation
      const translationKeys = Object.keys(en.esper)
      this.regexes = []
      for (translationKey of Array.from(translationKeys)) {
        const englishString = en.esper[translationKey]
        const regex = Problem.prototype.makeTranslationRegex(englishString)
        this.regexes.push(regex)
      }
      this.otherRegexes = []
      return (() => {
        const result = []
        for (translationKey of Array.from(translationKeys)) {
          const otherString = (otherLang.esper != null ? otherLang.esper[translationKey] : undefined) || ''
          const otherRegex = Problem.prototype.makeTranslationRegex(otherString)
          result.push(this.otherRegexes.push(otherRegex))
        }
        return result
      })()
    },
    percentDifference (problem) {
      return ((1 - ((problem.trimmed != null ? problem.trimmed.length : undefined) / problem[this.messageOrHint].length)) * 100).toFixed(0)
    },
    color (problem) {
      const amountTranslated = this.percentDifference(problem)
      if (amountTranslated >= this.completeThreshold) {
        return 'green'
      } else if (amountTranslated >= this.partialThreshold) {
        return 'yellow'
      } else {
        return 'red'
      }
    },
    getProblemsAndCompare (levelSlug) {
      return this.getProblems(levelSlug).then(problems => {
        return this.compareStrings(problems)
      })
    },
    getProblems: co.wrap(function * (levelSlug) {
      const newProblems = yield api.userCodeProblems.getCommon({ levelSlug, startDay: this.startDay, endDay: this.endDay })
      for (const problem of Array.from(newProblems)) {
        if (problem.hint == null) { problem.hint = '' }
        problem.levelSlug = levelSlug
      }
      Vue.set(this.problemsByLevel, levelSlug, newProblems)
      this.totalCount = _.reduce(_.map(this.problems, p => p.count), (a, b) => a + b)
      return newProblems
    }),
    compareStrings (problems) {
      return $.i18n.changeLanguage(this.language, () => {
        return problems.forEach(problem => {
          const original = problem[this.messageOrHint]
          const translated = Problem.prototype.translate(problem[this.messageOrHint])
          let trimmed = translated
          for (const regex of Array.from(this.otherRegexes)) {
            trimmed = trimmed.replace(regex, '').replace(/^\n/, '')
          }
          Vue.set(problem, 'translated', translated)
          return Vue.set(problem, 'trimmed', trimmed)
        })
      })
    },
    slugifyProblem (problem) {
      const str = _.string.slugify(problem.trimmed)
      return str.split('-').slice(0, 4).join('_')
    }
  }
})

module.exports = (I18nVerifierView = (function () {
  I18nVerifierView = class I18nVerifierView extends RootComponent {
    static initClass () {
      this.prototype.id = 'i18n-verifier-view'
      this.prototype.template = require('app/templates/base-flat')
      this.prototype.VueComponent = I18nVerifierComponent
    }

    constructor (options, levelSlug) {
      super(options)
      this.levelSlug = levelSlug
      this.propsData = { levelSlug: this.levelSlug }
    }

    destroy () {
      super.destroy(...arguments)
      return $.i18n.changeLanguage(me.get('preferredLanguage'))
    }
  }
  I18nVerifierView.initClass()
  return I18nVerifierView
})())
