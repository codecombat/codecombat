<script>
  import { mapMutations, mapGetters } from 'vuex'
  import { validationMixin } from 'vuelidate'
  import { getSchoolFormFieldsConfig } from '../common/signUpConfig'
  import { SCHOOL_NCES_KEYS } from '../common/constants'
  import { schoolLocationInfoValidations, validationMessages } from '../common/signUpValidations'

  export default {
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

      formFieldClasses () {
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

      onChangeValue () {
        const attrs = _.pick(this, 'organization', 'district', 'city', 'state')
        SCHOOL_NCES_KEYS.forEach(key => {
          const ncesKey = 'nces_' + key
          attrs[ncesKey] = this[ncesKey].toString()
        })
        this.updateTrialRequestProperties(attrs)
      }
    }
  }
</script>

<template lang="pug">
  div.school-form-container
    .organization.form-group.row(v-if="formFieldClasses.organization.visible" :class="{ 'has-error': $v.organization.$error }")
      .col-xs-10
        span.inline-flex-form-label-div
          span.control-label {{ $t("teachers_quote.school_name") }}
          span.form-error(v-if="!$v.organization.required") {{ $t(validationMessages.errorRequired.i18n) }}
        input#organization-input.form-control(name="organization" v-model="$v.organization.$model" @change="onChangeValue($event)")
    .district.form-group.row(v-if="formFieldClasses.district.visible" :class="{ 'has-error': $v.district.$error }")
      .col-xs-10
        span.inline-flex-form-label-div
          span.control-label {{ $t("teachers_quote.district_label") }}
          span.form-error(v-if="!$v.district.required") {{ $t(validationMessages.errorRequired.i18n) }}
        input#district-input.form-control(name="district" v-model="$v.district.$model" @change="onChangeValue($event)")
    .city.form-group.row(v-if="formFieldClasses.city.visible" :class="{ 'has-error': $v.city.$error }")
      .col-xs-10
        span.inline-flex-form-label-div
          span.control-label {{ $t("teachers_quote.city") }}
          span.form-error(v-if="!$v.city.required") {{ $t(validationMessages.errorRequired.i18n) }}
        input#city-input.form-control(name="city" v-model="$v.city.$model" @change="onChangeValue($event)")
    .state.form-group.row(v-if="formFieldClasses.state.visible" :class="{ 'has-error': $v.state.$error }")
      .col-xs-10
        span.inline-flex-form-label-div
          span.control-label {{ $t("teachers_quote.state") }}
          span.form-error(v-if="!$v.state.required") {{ $t(validationMessages.errorRequired.i18n) }}
        input#state-input.form-control(name="state" v-model="$v.state.$model" @change="onChangeValue($event)")
</template>

<style lang="sass" scoped>
</style>
