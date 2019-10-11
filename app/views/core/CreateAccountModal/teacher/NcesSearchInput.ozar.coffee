require 'app/styles/modal/create-account-modal/nces-search-input.sass'
algolia = require 'core/services/algolia'
DISTRICT_NCES_KEYS = ['district', 'district_id', 'district_schools', 'district_students']
SCHOOL_NCES_KEYS = DISTRICT_NCES_KEYS.concat(['id', 'name', 'students', 'phone'])
# NOTE: Phone number in algolia search results is for a school, not a district

NcesSearchInput = Vue.extend
  name: 'nces-search-input'
  template: require('templates/core/create-account-modal/nces-search-input')()
  
  data: ->
    # return _.assign(ncesData, formData, {
    return {
      mouseOnSuggestion: false
      suggestions: []
      suggestionIndex: 0
      filledSuggestion: ''
      value: @initialValue
    }

  props:
    displayKey:
      type: String
      default: ''
    initialValue:
      type: String
      default: ''
    name:
      type: String
      default: ''
    showRequired:
      type: Boolean
      default: false
    label:
      type: String

  methods:
    onInput: (e) ->
      value = $(e.currentTarget).val()
      @$emit('updateValue', @name, value)
      @searchNces(value)

    searchNces: (term) ->
      @suggestions = []
      @filledSuggestion = ''
      algolia.schoolsIndex.search(term, { hitsPerPage: 5, aroundLatLngViaIP: false })
      .then ({hits}) =>
        return unless @value is term
        @suggestions = hits
        @suggestionIndex = 0

    navSearchUp: -> @suggestionIndex = Math.max(0, @suggestionIndex - 1)
    navSearchDown: -> @suggestionIndex = Math.min(@suggestions.length, @suggestionIndex + 1)
    navSearchChoose: ->
      suggestion = @suggestions[@suggestionIndex]
      return unless suggestion
      @navSearchClear()
      @$emit('navSearchChoose', @displayKey, suggestion)
    onBlur: ->
      @navSearchClear()
    navSearchClear: ->
      @suggestions = []
    suggestionHover: (index) ->
      @suggestionIndex = index
  
  watch:
    initialValue: (@value) ->

module.exports = NcesSearchInput
