<script>
  import BaseModal from 'ozaria/site/components/common/BaseModal'
  import { mapActions, mapMutations } from 'vuex'
  import NcesSearchInput from 'app/views/core/CreateAccountModal/teacher/NcesSearchInput'
  const DISTRICT_NCES_KEYS = ['district', 'district_id', 'district_schools', 'district_students']
  const SCHOOL_NCES_KEYS = DISTRICT_NCES_KEYS.concat(['id', 'name', 'students', 'phone'])
  const countryList = require('country-list')()
  const UsaStates = require('usa-states').UsaStates

  export default Vue.extend({
    components: {
      BaseModal,
      NcesSearchInput
    },
    data: function () {
      let ncesData = {}
      let formData = {}
      let ncesKeys = []
      SCHOOL_NCES_KEYS.forEach(key => {
        ncesKeys.push('nces_' + key, '')
      })
      ncesData = _.zipObject(ncesKeys)
      formData = _.pick(this.$store.state.modal.trialRequestProperties, ncesKeys.concat([ 'organization', 'district', 'city', 'state', 'country', 'role' ]))

      return _.assign(ncesData, formData, {
        showRequired: false,
        countries: countryList.getNames(),
        usaStates: new UsaStates().states,
        usaStatesAbbreviations: new UsaStates().arrayOf('abbreviations')
      })
    },
    methods: {
      ...mapMutations({
        updateTrialRequestProperties: 'modal/updateTrialRequestProperties'
      }),
      ...mapActions({
        updateAccount: 'modal/updateAccount',
        saveMe: 'me/save'
      }),
      updateValue (name, value) {
        this[name] = value
        // Clear relevant NCES fields if they type a custom value instead of an autocompleted value
        if (name === 'organization') {
          this.clearSchoolNcesValues()
        }
        if (name === 'district') {
          this.clearSchoolNcesValues()
          this.clearDistrictNcesValues()
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
        let NCES_KEYS = []
        if (displayKey === 'name') {
          this.organization = suggestion.name
          NCES_KEYS = SCHOOL_NCES_KEYS
        } else {
          NCES_KEYS = DISTRICT_NCES_KEYS
        }
        this.country = 'United States'
        this.clearSchoolNcesValues()
        this.clearDistrictNcesValues()
        NCES_KEYS.forEach(key => {
          this['nces_' + key] = suggestion[key]
        })
      },

      onChangeCountry () {
        if (this.country == 'United States' && !this.usaStatesAbbreviations.includes(this.state))
          this.state = ''
      },

      async clickSave () {
        const requiredAttrs = _.pick(this, 'district', 'city', 'state', 'country', 'role')
        if (!_.all(requiredAttrs)) {
          this.showRequired = true
          return
        }
        const attrs = _.pick(this, 'organization', 'district', 'city', 'state', 'country', 'role')
        SCHOOL_NCES_KEYS.forEach(key => {
          const ncesKey = 'nces_' + key
          attrs[ncesKey] = this[ncesKey].toString()
        })
        this.updateTrialRequestProperties(attrs)
        try {
          await this.updateAccount()
          await this.saveMe({ hourOfCodeOptions: { showCompleteSignupModal: false } })
          window.$('.modal').modal('hide')
          noty({ text: 'Account details updated', layout: 'topCenter', type: 'success', timeout: 2000 })
        } catch (err) {
          console.error('Error in updating account details', err)
          noty({ text: 'Error in updating account details', layout: 'topCenter', type: 'error', timeout: 2000 })
        }
      }
    }
  })
</script>

<template lang="pug">
  base-modal#complete-signup-modal.style-ozaria.style-flat
    div
      span.glyphicon.glyphicon-remove.close(data-dismiss="modal", aria-hidden="true")
    div
      h2 {{ $t("teachers_quote.finish_signup") }}
    div
      div.teacher-info-panel
        .container-fluid.text-left
          .row.m-y-2
            .col-xs-offset-2.col-xs-8
              nces-search-input(
                v-bind:label='$t("teachers_quote.school_name")'
                v-on:navSearchChoose="applySuggestion"
                name="organization"
                displayKey="name"
                v-bind:initialValue="organization"
                v-on:updateValue="updateValue"
              )
          .row.m-y-2
            .col-xs-offset-2.col-xs-4
              nces-search-input(
                v-bind:label='$t("teachers_quote.district_name")'
                v-on:navSearchChoose="applySuggestion"
                name="district"
                displayKey="district"
                v-bind:initialValue="district"
                v-bind:showRequired="showRequired"
                v-on:updateValue="updateValue"
              )
            .col-xs-4
              .form-group(v-bind:class="{ 'has-error': showRequired && !city }")
                span.control-label
                  | {{ $t("teachers_quote.city") }}
                  =" "
                  strong(v-if="showRequired && !city") {{ $t("common.required_field") }}
                input.form-control(name="city", v-model="city")

          .row.m-y-2
            .col-xs-offset-2.col-xs-4
              .form-group(v-bind:class="{ 'has-error': showRequired && !state }")
                span.control-label
                  | {{ $t("teachers_quote.state") }}
                  =" "
                  strong(v-if="showRequired && !state") {{ $t("common.required_field") }}
                select.form-control(name="state", v-model="state", v-if="country == 'United States'")
                  option(v-for="state in usaStates" v-bind:value="state.abbreviation")
                    | {{ state.abbreviation }}
                    = ", "
                    | {{ state.name }}
                input.form-control(name="state", v-model="state", v-else)
            .col-xs-4
              .form-group(v-bind:class="{ 'has-error': showRequired && !country }")
                span.control-label
                  | {{ $t("teachers_quote.country") }}
                  =" "
                  strong(v-if="showRequired && !country") {{ $t("common.required_field") }}
                select.form-control(name="country", v-model="country", @change="onChangeCountry")
                  option(v-for="country in countries" v-bind:value="country")
                    | {{ country }}
          .row.m-y-2
            .col-xs-offset-2.col-xs-8
              .form-group(v-bind:class="{ 'has-error': showRequired && !role }")
                span.control-label
                  | {{ $t("teachers_quote.primary_role_label") }}
                  =" "
                  strong(v-if="showRequired && !role") {{ $t("common.required_field") }}
                select.form-control(v-model="role", name="role")
                  option(value='') {{ $t("teachers_quote.primary_role_default") }}
                  option(value="Teacher") {{ $t("courses.teacher") }}
                  option(value="Technology coordinator") {{ $t("teachers_quote.tech_coordinator") }}
                  option(value="Advisor") {{ $t("teachers_quote.advisor") }}
                  option(value="Principal") {{ $t("teachers_quote.principal") }}
                  option(value="Superintendent") {{ $t("teachers_quote.superintendent") }}
                  option(value="Parent") {{ $t("teachers_quote.parent") }}
    div
      button#update-account-btn.save-button.ozaria-button.ozaria-primary-button(v-on:click="clickSave") {{ $t("common.save") }}
</template>

<style lang="sass" scoped>
  #complete-signup-modal
    padding-top: 0

    ::v-deep .modal-container
      padding: 16px

  .teacher-info-panel
    width: 100%
</style>
