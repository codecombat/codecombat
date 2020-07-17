<script>
  import { mapMutations } from 'vuex'
  import { validationMixin } from 'vuelidate'
  import utils from 'app/core/utils'
  import { getEducatorRoles } from './common/signUpConfig'
  import { SCHOOL_NCES_KEYS } from './common/constants'
  import { validationMessages, roleInfoValidations } from './common/signUpValidations'
  import SecondaryButton from '../../teacher-dashboard/common/buttons/SecondaryButton'

  const countryList = require('country-list')()

  export default {
    components: {
      SecondaryButton
    },
    mixins: [validationMixin],
    data: () => ({
      countriesList: countryList.getNames(),
      country: '',
      role: '',
      roleOptions: getEducatorRoles(me.showChinaRegistration()),
      validationMessages
    }),

    validations: roleInfoValidations,

    computed: {
      isFormValid () {
        return !this.$v.$invalid
      }
    },

    watch: {
      isFormValid (val) {
        this.$emit('validityChange', val)
      }
    },

    mounted () {
      // Set default value for country
      const userCountry = (utils.countries || []).find((c) => c.country === me.get('country')).countryCode
      if (userCountry) {
        this.country = countryList.getName(userCountry)
        this.updateTrialRequestProperties({ country: this.country })
      }
    },

    methods: {
      ...mapMutations({
        updateTrialRequestProperties: 'teacherSignup/updateTrialRequestProperties'
      }),

      onChangeValue (event) {
        const attrs = {}
        attrs[event.target.name] = event.target.value
        this.updateTrialRequestProperties(attrs)
        this.clearSchoolInfoFormValues() // since different properties are needed for different country-role combinations, reset the school form to fill it again
      },

      clearSchoolInfoFormValues () {
        const attrs = {
          organization: '',
          district: '',
          city: '',
          state: '',
          phoneNumber: '',
          numStudents: ''
        }
        SCHOOL_NCES_KEYS.forEach(key => {
          const ncesKey = 'nces_' + key
          attrs[ncesKey] = ''
        })
        this.updateTrialRequestProperties(attrs)
      },

      onClickNext () {
        if (this.isFormValid) {
          this.$emit('goToNext')
        }
      }
    }
  }
</script>

<template lang="pug">
  #role-info-component
    form.form-container(@submit.prevent="onClickNext")
      .country.form-group.row(:class="{ 'has-error': $v.country.$error }")
        .col-xs-8
          span.inline-flex-form-label-div
            span.control-label {{ $t("teachers_quote.country") }}
            span.form-error(v-if="!$v.country.required") {{ $t(validationMessages.errorRequired.i18n) }}
          select#country-input.form-control(name="country", v-model="$v.country.$model", @change="onChangeValue($event)")
            option(v-for="country in countriesList" v-bind:value="country") {{ country }}
      .role.form-group.row(:class="{ 'has-error': $v.role.$error }")
        .col-xs-8
          span.inline-flex-form-label-div
            span.control-label {{ $t("teachers_quote.primary_role_label") }}
            span.form-error(v-if="!$v.role.required") {{ $t(validationMessages.errorRequired.i18n) }}
          select#role-input.form-control(name="role", v-model="$v.role.$model", @change="onChangeValue($event)", :class="{ 'placeholder-text': !role }")
            option(disabled selected value="") {{ $t("signup.select_your_role") }}
            option(v-for="role in roleOptions" v-bind:value="role.value") {{ $t(role.i18n) }}
      .buttons.form-group.row
        .col-xs-offset-5
          secondary-button(type="submit", :inactive="!isFormValid") {{ $t("common.next") }}
</template>

<style lang="sass" scoped>
#role-info-component
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
