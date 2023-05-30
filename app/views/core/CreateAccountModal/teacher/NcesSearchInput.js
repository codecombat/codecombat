// TODO: This file was created by bulk-decaffeinate.
// Sanity-check the conversion and remove this comment.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/main/docs/suggestions.md
 */
import 'app/styles/modal/create-account-modal/nces-search-input.sass';

import algolia from 'core/services/algolia';
import utils from 'core/utils';
const DISTRICT_NCES_KEYS = ['district', 'district_id', 'district_schools', 'district_students'];
const SCHOOL_NCES_KEYS = DISTRICT_NCES_KEYS.concat(['id', 'name', 'students', 'phone']);
// NOTE: Phone number in algolia search results is for a school, not a district

const NcesSearchInput = Vue.extend({
  name: 'nces-search-input',
  template: require('app/templates/core/create-account-modal/nces-search-input')(),

  data() {
    // return _.assign(ncesData, formData, {
    return {
      mouseOnSuggestion: false,
      suggestions: [],
      suggestionIndex: 0,
      filledSuggestion: '',
      value: this.initialValue
    };
  },

  props: {
    displayKey: {
      type: String,
      default: ''
    },
    initialValue: {
      type: String,
      default: ''
    },
    name: {
      type: String,
      default: ''
    },
    // ozar version applied, because new properties with default values
    // should make no difference even if they're not used
    placeholder: {
      type: String,
      default: ''
    },
    isOptional: {
      type: Boolean,
      default: false
    },
    showRequired: {
      type: Boolean,
      default: false
    },
    label: {
      type: String
    }
  },

  methods: {
    onInput(e) {
      const value = $(e.currentTarget).val();
      this.$emit('updateValue', this.name, value);
      return this.searchNces(value);
    },

    searchNces(term) {
      if (utils.isCodeCombat && me.get('country') && (me.get('country') !== 'united-states')) { return; }
      // don't do any of the NCES-based autocomplete stuff
      // unless the user manually specifies "United States" as the country, then turn it back on
      this.suggestions = [];
      this.filledSuggestion = '';
      return algolia.schoolsIndex.search(term, { hitsPerPage: 5, aroundLatLngViaIP: false })
      .then(({hits}) => {
        if (this.value !== term) { return; }
        this.suggestions = hits;
        return this.suggestionIndex = 0;
      });
    },

    navSearchUp() { return this.suggestionIndex = Math.max(0, this.suggestionIndex - 1); },
    navSearchDown() { return this.suggestionIndex = Math.min(this.suggestions.length, this.suggestionIndex + 1); },
    navSearchChoose() {
      const suggestion = this.suggestions[this.suggestionIndex];
      if (!suggestion) { return; }
      this.navSearchClear();
      return this.$emit('navSearchChoose', this.displayKey, suggestion);
    },
    onBlur() {
      return this.navSearchClear();
    },
    navSearchClear() {
      return this.suggestions = [];
    },
    suggestionHover(index) {
      return this.suggestionIndex = index;
    }
  },

  watch: {
    initialValue(value) {
      this.value = value;
    }
  }
});

export default NcesSearchInput;
