<script>
  import { mapMutations, mapGetters } from 'vuex'
  import UnitedStatesSchoolForm from './UnitedStatesSchoolForm'
  import OtherCountriesSchoolForm from './OtherCountriesSchoolForm'
  import { COUNTRIES } from '../common/constants'
  import { getSchoolFormFieldsConfig } from '../common/signUpConfig'
  import { validationMixin } from 'vuelidate'
  import { educatorOtherInfoValidations, validationMessages } from '../common/signUpValidations'
  import SecondaryButton from '../../../teacher-dashboard/common/buttons/SecondaryButton'

  export default {
    components: {
      'united-states-school-form': UnitedStatesSchoolForm,
      'other-countries-school-form': OtherCountriesSchoolForm,
      SecondaryButton
    },

    mixins: [validationMixin],

    data: () => ({
      phoneNumber: '',
      numStudents: '',
      marketingConsent: !me.inEU(),
      gdprConsent: !me.inEU(),
      validationMessages,
      isChinaServerSignup: me.showChinaRegistration(),
      childFormValid: false
    }),

    validations () {
      return educatorOtherInfoValidations(this.country, this.role, this.isChinaServerSignup)
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
        return getSchoolFormFieldsConfig(this.country, this.role, this.isChinaServerSignup)
      },

      isUS () {
        return this.trialReqProps.country === COUNTRIES.US
      },

      isEU () {
        return me.inEU()
      },

      isFormValid () {
        return !this.$v.$invalid && this.childFormValid
      },

      doneDisabled () {
        return !this.isFormValid || !this.gdprConsent
      }
    },

    watch: {
      isFormValid (val) {
        this.$emit('validityChange', val)
      }
    },

    mounted () {
      // default country code
      if (this.isChinaServerSignup) {
        this.phoneNumber = '+86 '
      } else {
        this.phoneNumber = '+1 '
      }
    },

    methods: {
      ...mapMutations({
        updateTrialRequestProperties: 'teacherSignup/updateTrialRequestProperties',
        setMarketingConsent: 'teacherSignup/setMarketingConsent'
      }),

      onChangeValue (event = {}) {
        const attrs = {}
        if (event.target) {
          attrs[event.target.name] = event.target.value
        }
        this.updateTrialRequestProperties(attrs)
      },

      onClickNext () {
        if (this.isFormValid) {
          this.setMarketingConsent({ marketingConsent: this.marketingConsent })
          this.$emit('goToNext')
        }
      }
    }
  }
</script>

<template lang="pug">
  #school-info-component
    form.form-container(@submit.prevent="onClickNext")
      united-states-school-form(v-if="isUS" @validityChange="(val) => this.childFormValid = val")
      other-countries-school-form(v-else @validityChange="(val) => this.childFormValid = val")
      .phoneNumber.form-group.row(v-if="formFieldConfig.phoneNumber.visible" :class="{ 'has-error': $v.phoneNumber.$error }")
        .col-xs-10
          label.control-label {{ $t("teachers_quote.phone_number") }}
          span.control-label.optional-text(v-if="!formFieldConfig.phoneNumber.required") !{' '}({{ $t("signup.optional") }})
          input.phone-input.form-control(name="phoneNumber" v-model="$v.phoneNumber.$model" @change="onChangeValue($event)")
          span.form-error(v-if="!$v.phoneNumber.required") {{ $t(validationMessages.errorRequired.i18n) }}
      .numStudents.form-group.row(v-if="formFieldConfig.numStudents.visible" :class="{ 'has-error': $v.numStudents.$error }")
        .col-xs-10
          label.control-label {{ $t("teachers_quote.num_students_help") }}
          span.control-label.optional-text(v-if="!formFieldConfig.numStudents.required") !{' '}({{ $t("signup.optional") }})
          select#numStudents-input.form-control(name="numStudents", v-model="$v.numStudents.$model" @change="onChangeValue($event)" :class="{ 'placeholder-text': !numStudents }")
            option(disabled selected value='') {{ $t("teachers_quote.num_students_default") }}
            option 1-10
            option 11-50
            option 51-100
            option 101-200
            option 201-500
            option 501-1000
            option 1000+
          span.form-error(v-if="!$v.numStudents.required") {{ $t(validationMessages.errorRequired.i18n) }}
      .marketingConsent.form-group.row
        .col-xs-10.form-checkbox-input
          input#marketingConsent(name="marketingConsent", type="checkbox", v-model="marketingConsent")
          span {{ $t("signup.teacher_email_announcements") }}
      .gdprConsent.form-group.row(v-if="isEU")
        .col-xs-10.form-checkbox-input
          input#gdprConsent(name="gdprConsent", type="checkbox", v-model="gdprConsent")
          span {{ $t("signup.eu_confirmation") }}!{' '}
            a(href="https://www.ozaria.com/privacy#gdpr" target="_blank") {{ $t("signup.eu_confirmation_place_of_processing") }}
      .buttons.form-group.row
        .col-xs-offset-7
          secondary-button(type="submit", :inactive="doneDisabled") {{ $t("common.done") }}
</template>

<style lang="sass" scoped>
#school-info-component
  height: 100vh
  display: flex
  flex-flow: column
  justify-content: center
  .form-container
    width: 48vw
  .buttons
    margin-top: 30px
    button
      width: 150px
      height: 35px
</style>
