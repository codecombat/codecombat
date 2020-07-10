<script>
  import { mapMutations, mapGetters } from 'vuex'
  import { validationMixin } from 'vuelidate'
  import { getSchoolFormFieldsConfig } from '../common/signUpConfig'
  import { DISTRICT_NCES_KEYS, SCHOOL_NCES_KEYS } from '../common/constants'
  import { schoolLocationInfoValidations, validationMessages } from '../common/signUpValidations'

  import NcesSearchInput from './NcesSearchInput'
  const UsaStates = require('usa-states').UsaStates

  export default {
    components: {
      'nces-search-input': NcesSearchInput
    },

    mixins: [validationMixin],

    data: function () {
      let ncesData = {}
      let formData = {}
      let ncesKeys = []
      SCHOOL_NCES_KEYS.forEach(key => {
        ncesKeys.push('nces_' + key, '')
      })
      ncesData = _.zipObject(ncesKeys)
      formData = _.pick(this.$store.state.teacherSignup.trialRequestProperties, ncesKeys.concat([ 'organization', 'district', 'city', 'state' ]))

      return _.assign(ncesData, formData, {
        usaStates: new UsaStates().states,
        usaStatesAbbreviations: new UsaStates().arrayOf('abbreviations'),
        validationMessages,
        isChinaServer: window.features.china
      })
    },

    validations () {
      return schoolLocationInfoValidations(this.country, this.role, this.isChinaServer)
    },

    computed: {
      ...mapGetters({
        trialReqProps: 'teacherSignup/getTrialRequestProperties'
      }),

      country () {
        return this.trialReqProps.country
      },

      role () {
        return this.trialReqProps.role
      },

      formFieldConfig () {
        return getSchoolFormFieldsConfig(this.country, this.role, this.isChinaServer)
      },

      isFormValid () {
        return !this.$v.$invalid
      }
    },

    watch: {
      isFormValid (val) {
        this.$emit('validityChange', val)
      }
    },

    methods: {
      ...mapMutations({
        updateTrialRequestProperties: 'teacherSignup/updateTrialRequestProperties'
      }),

      updateValue (name, value) {
        this[name] = value
        // Clear relevant NCES fields if they type a custom value instead of an autocompleted value
        if (name === 'organization') {
          this.clearSchoolNcesValues()
          this.$v.organization.$touch()
        }
        if (name === 'district') {
          this.clearSchoolNcesValues()
          this.clearDistrictNcesValues()
          this.$v.district.$touch()
        }
      },

      clearDistrictNcesValues () {
        DISTRICT_NCES_KEYS.forEach(key => {
          this['nces_' + key] = ''
        })
      },

      clearSchoolNcesValues () {
        _.difference(SCHOOL_NCES_KEYS, DISTRICT_NCES_KEYS).forEach(key => {
          this['nces_' + key] = ''
        })
      },

      applySuggestion (displayKey, suggestion) {
        if (!suggestion) {
          return
        }
        _.assign(this, _.pick(suggestion, 'district', 'city', 'state'))
        let ncesKeys = []
        if (displayKey === 'name') {
          this.organization = suggestion.name
          ncesKeys = SCHOOL_NCES_KEYS
        } else {
          ncesKeys = DISTRICT_NCES_KEYS
        }
        this.clearSchoolNcesValues()
        this.clearDistrictNcesValues()

        const attrs = _.pick(this, 'organization', 'district', 'city', 'state')
        ncesKeys.forEach(key => {
          const ncesKey = 'nces_' + key
          this[ncesKey] = suggestion[key]
          attrs[ncesKey] = this[ncesKey].toString()
        })
        this.updateTrialRequestProperties(attrs)
      },

      onChangeValue () {
        const attrs = {}
        attrs[event.target.name] = event.target.value
        this.updateTrialRequestProperties(attrs)
      }
    }
  }
</script>

<template lang="pug">
  div.school-form-container
    .organization.form-group.row(v-if="formFieldConfig.organization.visible" :class="{ 'has-error': $v.organization.$error }")
      .col-xs-10
        nces-search-input(
          :label='$t("teachers_quote.school_name")'
          placeholder="Search for your school"
          @navSearchChoose="applySuggestion"
          name="organization"
          displayKey="name"
          :isOptional="!formFieldConfig.organization.required"
          :initialValue="organization"
          @updateValue="updateValue"
        )
        span.form-error(v-if="!$v.organization.required") {{ $t(validationMessages.errorRequired.i18n) }}
    .district.form-group.row(v-if="formFieldConfig.district.visible" :class="{ 'has-error': $v.district.$error }")
      .col-xs-10
        nces-search-input(
          :label='$t("teachers_quote.district_name")'
          placeholder="Search for your district"
          @navSearchChoose="applySuggestion"
          name="district"
          displayKey="district"
          :isOptional="!formFieldConfig.district.required"
          :initialValue="district"
          @updateValue="updateValue"
        )
        span.form-error(v-if="!$v.district.required") {{ $t(validationMessages.errorRequired.i18n) }}
    .city.form-group.row(v-if="formFieldConfig.city.visible" :class="{ 'has-error': $v.city.$error }")
      .col-xs-10
        label.control-label {{ $t("teachers_quote.city") }}
        span.control-label.optional-text(v-if="!formFieldConfig.city.required") !{' '}({{ $t("signup.optional") }})
        input#city-input.form-control(name="city" v-model="$v.city.$model" @change="onChangeValue($event)")
        span.form-error(v-if="!$v.city.required") {{ $t(validationMessages.errorRequired.i18n) }}
    .state.form-group.row(v-if="formFieldConfig.state.visible" :class="{ 'has-error': $v.state.$error }")
      .col-xs-10
        label.control-label {{ $t("teachers_quote.state") }}
        span.control-label.optional-text(v-if="!formFieldConfig.state.required") !{' '}({{ $t("signup.optional") }})
        select#state-input.form-control(name="state" v-model="$v.state.$model" @change="onChangeValue($event)" :class="{ 'placeholder-text': !state }")
          option(selected disabled value="") {{ $t("signup.select_your_state") }}
          option(v-for="state in usaStates" v-bind:value="state.abbreviation")
            | {{ state.abbreviation }}
        span.form-error(v-if="!$v.state.required") {{ $t(validationMessages.errorRequired.i18n) }}
</template>

<style lang="sass" scoped>
</style>
