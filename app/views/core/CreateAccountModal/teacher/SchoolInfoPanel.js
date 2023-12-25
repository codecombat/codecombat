// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
require('app/styles/modal/create-account-modal/school-info-panel.sass')
const NcesSearchInput = require('./NcesSearchInput')
const algolia = require('core/services/algolia')
const utils = require('core/utils')
const DISTRICT_NCES_KEYS = ['district', 'district_id', 'district_schools', 'district_students']
const SCHOOL_NCES_KEYS = DISTRICT_NCES_KEYS.concat(['id', 'name', 'students', 'phone'])
// NOTE: Phone number in algolia search results is for a school, not a district
const { countries } = require('core/utils')
const countryList = require('country-list')()
const {
  UsaStates
} = require('usa-states')

const SchoolInfoPanel = {
  name: 'school-info-panel',
  template: require('app/templates/core/create-account-modal/school-info-panel')(),

  data () {
    // TODO: Store ncesData in just the store?
    let key
    const ncesData = _.zipObject((() => {
      const result = []
      for (key of Array.from(SCHOOL_NCES_KEYS)) {
        result.push(['nces_' + key, ''])
      }
      return result
    })())
    const formData = _.pick(this.$store.state.modalTeacher.trialRequestProperties,
      ((() => {
        const result1 = []
        for (key of Array.from(SCHOOL_NCES_KEYS)) {
          result1.push('nces_' + key)
        }
        return result1
      })()).concat([
        'organization',
        'district',
        'city',
        'state',
        'country'
      ]))

    Object.assign(formData, {
      countriesList: countryList.getNames()
    })

    return _.assign(ncesData, formData, {
      showRequired: false,
      usaStates: new UsaStates().states,
      usaStatesAbbreviations: new UsaStates().arrayOf('abbreviations'),
      countryMap: {
        'Hong Kong': 'Hong Kong, China',
        Macao: 'Macao, China',
        'Taiwan, Province of China': 'Taiwan, China'
      }
    })
  },

  components: {
    'nces-search-input': NcesSearchInput
  },

  methods: {
    updateValue (name, value) {
      this[name] = value
      // Clear relevant NCES fields if they type a custom value instead of an autocompleted value
      if (name === 'organization') {
        this.clearSchoolNcesValues()
      }
      if (name === 'district') {
        this.clearSchoolNcesValues()
        return this.clearDistrictNcesValues()
      }
    },

    clearDistrictNcesValues () {
      return Array.from(DISTRICT_NCES_KEYS).map((key) =>
        (this['nces_' + key] = ''))
    },

    clearSchoolNcesValues () {
      return Array.from(_.difference(SCHOOL_NCES_KEYS, DISTRICT_NCES_KEYS)).map((key) =>
        (this['nces_' + key] = ''))
    },

    applySuggestion (displayKey, suggestion) {
      if (!suggestion) { return }
      _.assign(this, _.pick(suggestion, 'district', 'city', 'state'))
      if (displayKey === 'name') {
        this.organization = suggestion.name
      }
      this.country = 'United States'
      this.clearSchoolNcesValues()
      this.clearDistrictNcesValues()
      const NCES_KEYS = displayKey === 'name' ? SCHOOL_NCES_KEYS : DISTRICT_NCES_KEYS
      return Array.from(NCES_KEYS).map((key) =>
        (this['nces_' + key] = suggestion[key]))
    },

    onChangeCountry () {
      if ((this.country === 'United States') && !this.usaStatesAbbreviations.includes(this.state)) {
        return this.state = ''
      }
    },

    commitValues () {
      const attrs = _.pick(this, 'organization', 'district', 'city', 'state', 'country')
      for (const key of Array.from(SCHOOL_NCES_KEYS)) {
        const ncesKey = 'nces_' + key
        attrs[ncesKey] = this[ncesKey].toString()
      }
      return this.$store.commit('modalTeacher/updateTrialRequestProperties', attrs)
    },

    clickContinue () {
      // Make sure to add conditions if we change this to be used on non-teacher path
      if (window.tracker != null) {
        window.tracker.trackEvent('CreateAccountModal Teacher SchoolInfoPanel Continue Clicked', { category: 'Teachers' })
      }
      const requiredAttrs = _.pick(this, 'district', 'city', 'state', 'country')
      if (!_.all(requiredAttrs)) {
        this.showRequired = true
        return
      }
      this.commitValues()
      if (window.tracker != null) {
        window.tracker.trackEvent('CreateAccountModal Teacher SchoolInfoPanel Continue Success', { category: 'Teachers' })
      }
      return this.$emit('continue')
    },

    clickBack () {
      this.commitValues()
      if (window.tracker != null) {
        window.tracker.trackEvent('CreateAccountModal Teacher SchoolInfoPanel Back Clicked', { category: 'Teachers' })
      }
      return this.$emit('back')
    }
  },

  mounted () {
    $("input[name*='organization']").focus()

    if (utils.isOzaria) {
      return
    }

    if (me.showChinaRegistration()) {
      this.country = 'China'
    } else {
      const userCountry = me.get('country')
      const matchingCountryName = userCountry ? _.find(countryList.getNames(), c => (c === _.string.slugify(userCountry)) || (c.toLowerCase() === userCountry.toLowerCase())) : undefined
      if (matchingCountryName) {
        this.country = matchingCountryName
      } else {
        this.country = 'United States'
      }
    }

    if (!me.addressesIncludeAdministrativeRegion()) {
      return this.state = ' '
    }
  }
}

module.exports = SchoolInfoPanel
