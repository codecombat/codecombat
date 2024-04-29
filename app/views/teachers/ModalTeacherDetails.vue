<script>
import Modal from '../../components/common/Modal'
import { mapActions, mapGetters } from 'vuex'
import SecondaryButton from '../../components/common/SecondaryButton'
import { SCHOOL_NCES_KEYS } from '../../lib/trialRequestUtils'
const NcesSearchInput = require('../../views/core/CreateAccountModal/teacher/NcesSearchInput')

const countryList = require('country-list')()
const UsaStates = require('usa-states').UsaStates

export default Vue.extend({
  name: 'ModalTeacherDetails',
  components: {
    Modal,
    SecondaryButton,
    NcesSearchInput
  },
  props: {
    initialOrganization: String,
    initialDistrict: String,
    initialCity: String,
    initialState: String,
    initialCountry: String
  },
  data () {
    return {
      countries: countryList.getNames(),
      usaStates: new UsaStates().states,
      organization: this.initialOrganization,
      district: this.initialDistrict,
      city: this.initialCity,
      state: this.initialState,
      country: this.initialCountry,
      ncesData: null,
      hideModal: false
    }
  },
  computed: {
    showUsStatesDropDown () {
      return this.country === 'United States'
    }
  },
  watch: {
    country () {
      if (!this.showUsStatesDropDown) { this.ncesData = null }
    },
    hideModal () {
      if (this.hideModal) {
        $('#coco-modal-header-close-button').click()
      }
    }
  },
  created () {
    this.$store.dispatch('trialRequest/fetchCurrentTrialRequest')
      .then((_res) => {
        const trialRequest = this.fetchedTrialRequest()
        if (!trialRequest) {
          return
        }
        this.district = trialRequest.district
        this.state = trialRequest.state
        this.country = trialRequest.country || 'United States'
        this.city = trialRequest.city
        this.organization = trialRequest.organization
      })
  },
  methods: {
    ...mapActions({
      updateTrialRequest: 'trialRequest/updateProperties'
    }),
    ...mapGetters({
      fetchedTrialRequest: 'trialRequest/properties'
    }),
    onClose () {
      this.$emit('close')
    },
    async submitDetails (_e) {
      const updates = {
        organization: this.organization,
        district: this.district,
        state: this.state,
        city: this.city,
        country: this.country,
        ...this.ncesData
      }
      try {
        await this.updateTrialRequest(updates)
      } catch (err) {
        console.error('Error in updating account details - TeacherDetails', err)
      }
      this.$emit('close')
      this.hideModal = true
    },
    updateState (e) {
      this.state = e.target.value
    },
    updateCountry (e) {
      this.country = e.target.value
    },
    onNcesSchoolChoose (displayKey, choice) {
      const data = {}
      for (const [key, value] of Object.entries(choice)) {
        if (SCHOOL_NCES_KEYS.includes(key)) {
          data[`nces_${key}`] = value
        }
      }
      this.ncesData = data
      this.organization = choice.name
      this.state = choice.state
      this.city = choice.city
      this.district = choice.district
    },
    onNcesSchoolInput (name, newValue) {
      this.organization = newValue
    }
  }
})
</script>

<template>
  <modal
    :title="$t('teachers_quote.teacher_account_details')"
    :backbone-dismiss-modal="true"
    @close="onClose"
  >
    <div class="teacher-details-modal">
      <form
        class="teacher-details-form"
        @submit.prevent="submitDetails"
      >
        <div class="form-group">
          <label for="schoolName">{{ $t("teachers_quote.school_name") }}</label>
          <nces-search-input
            v-if="showUsStatesDropDown"
            :initial-value="organization"
            display-key="name"
            @updateValue="onNcesSchoolInput"
            @navSearchChoose="onNcesSchoolChoose"
          />
          <input
            v-else
            id="schoolName"
            v-model="organization"
            class="form-control"
            type="text"
            required
          >
        </div>
        <div class="form-group row">
          <div class="col-lg-6">
            <label for="district">{{ $t("teachers_quote.district_name") }}</label>
            <input
              id="district"
              v-model="district"
              class="form-control"
              type="text"
              required
            >
          </div>
          <div class="col-lg-6">
            <label for="city">{{ $t("teachers_quote.city") }}</label>
            <input
              id="city"
              v-model="city"
              class="form-control"
              type="text"
              required
            >
          </div>
        </div>
        <div class="form-group row">
          <div class="col-lg-6">
            <label
              class="dropdown-label"
              for="country"
            >{{ $t('teachers_quote.country') }}</label>
            <select
              id="country"
              class="select-dropdown"
              @change="updateCountry"
            >
              <option
                value=""
                :selected="country === ''"
                disabled
                hidden
              >
                Select
              </option>
              <option
                v-for="option in countries"
                :key="option"
                :selected="country === option"
              >
                {{ option }}
              </option>
            </select>
          </div>
          <div
            v-if="showUsStatesDropDown"
            class="col-lg-6"
            z
          >
            <label
              class="dropdown-label"
              for="stateDropDown"
            >{{ $t('teachers_quote.state') }}</label>
            <div>
              <select
                id="stateDropDown"
                class="select-dropdown w-100"
                @change="updateState"
              >
                <option
                  value=""
                  :selected="state === ''"
                  disabled
                  hidden
                >
                  Select
                </option>
                <option
                  v-for="option in usaStates"
                  :key="option.abbreviation"
                  :selected="state === option.abbreviation"
                  :value="option.abbreviation"
                >
                  {{ option.name }}
                </option>
              </select>
            </div>
          </div>
          <div
            v-else
            class="col-lg-6"
          >
            <label for="state">{{ $t("teachers_quote.state") }}</label>
            <input
              id="state"
              v-model="state"
              class="form-control"
              type="text"
              required
            >
          </div>
        </div>
        <div class="buttons">
          <secondary-button class="next pull-right">
            {{ $t("common.submit") }}
          </secondary-button>
        </div>
      </form>
    </div>
  </modal>
</template>

<style lang="scss" scoped>
.teacher-details-modal {
  width: 700px;
  padding: 10px;
}

.buttons {
  margin-top: 30px;
  .next {
    width: 150px;
    height: 35px;
    margin: 0 10px;
  }
}
.select-dropdown {
  font-size: 14px;
  line-height: 20px;

  height: 30px;
  width: 100%;
}
</style>
