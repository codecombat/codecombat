<script>
import Modal from "../../common/Modal";
import {mapActions, mapGetters} from "vuex";
import SecondaryButton from "../common/buttons/SecondaryButton";
import Dropdown from "../common/Dropdown";
import NcesSearchInput from "../../sign-up/PageEducatorSignup/PageSchoolInfo/NcesSearchInput";
import { SCHOOL_NCES_KEYS } from "../../../../../app/core/trialRequestUtil"

const countryList = require('country-list')();
const UsaStates = require('usa-states').UsaStates

export default Vue.extend({
  name: "ModalTeacherDetails",
  components: {
    Modal,
    SecondaryButton,
    Dropdown,
    NcesSearchInput,
  },
  props: {
    initialOrganization: String,
    initialDistrict: String,
    initialCity: String,
    initialState: String,
    initialCountry: String,
  },
  data() {
    return {
      countries: countryList.getNames(),
      usaStates: new UsaStates().states,
      organization: this.initialOrganization,
      district: this.initialDistrict,
      city: this.initialCity,
      state: this.initialState,
      country: this.initialCountry,
      ncesData: null
    };
  },
  computed: {
    showUsStatesDropDown() {
      return this.country === 'United States'
    },
  },
  watch: {
    country() {
      if (!this.showUsStatesDropDown)
        this.ncesData = null
    }
  },
  methods: {
    ...mapActions({
      updateTrialRequest: 'trialRequest/updateProperties',
    }),
    onClose() {
      this.$emit('close');
    },
    async submitDetails(_e) {
      const updates = {
        organization: this.organization,
        district: this.district,
        state: this.state,
        city: this.city,
        country: this.country,
        ...this.ncesData
      }
      try {
        await this.updateTrialRequest(updates);
      } catch (err) {
        console.error('Error in updating account details - TeacherDetails', err);
      }
      this.$emit('close');
    },
    updateState(e) {
      this.state = e.target.value;
    },
    updateCountry(e) {
      this.country = e.target.value;
    },
    onNcesSchoolChoose(displayKey, choice) {
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
    onNcesSchoolInput(name, newValue) {
      this.organization = newValue
    }
  }
})
</script>

<template>
  <modal
      title="Teacher Account Details"
      @close="onClose"
  >
    <div class="teacher-details-modal">
      <form class="teacher-details-form" @submit.prevent="submitDetails">
        <div class="form-group">
          <label for="schoolName">{{$t("teachers_quote.school_name")}}</label>
          <nces-search-input
            @updateValue="onNcesSchoolInput"
            @navSearchChoose="onNcesSchoolChoose"
            :initial-value="organization"
            display-key="name"
            v-if="showUsStatesDropDown"
          />
          <input
            id="schoolName" class="form-control" v-model="organization" type="text" required
            v-else
          />
        </div>
        <div class="form-group row">
          <div class="col-lg-6">
            <label for="district">{{$t("teachers_quote.district_name")}}</label>
            <input id="district" class="form-control" v-model="district" type="text" required />
          </div>
          <div class="col-lg-6">
            <label for="city">{{$t("teachers_quote.city")}}</label>
            <input id="city" class="form-control" v-model="city" type="text" required />
          </div>
        </div>
        <div class="form-group row">
          <div class="col-lg-6">
            <label class="dropdown-label" for="country">{{$t('teachers_quote.country')}}</label>
            <select @change="updateCountry" id="country" class="select-dropdown">
              <option value="" :selected="country === ''" disabled hidden>Select</option>
              <option
                  v-for="option in countries"
                  :key="option"
                  :selected="country === option"
              >
                {{option}}
              </option>
            </select>
          </div>
          <div v-if="showUsStatesDropDown" class="col-lg-6">
            <label class="dropdown-label" for="stateDropDown">{{$t('teachers_quote.state')}}</label>
            <div>
              <select @change="updateState" id="stateDropDown" class="select-dropdown w-100">
                <option value="" :selected="state === ''" disabled hidden>Select</option>
                <option
                    v-for="option in usaStates"
                    :key="option.abbreviation"
                    :selected="state === option.abbreviation"
                    :value="option.abbreviation"
                >
                  {{option.name}}
                </option>
              </select>
            </div>
          </div>
          <div v-else class="col-lg-6">
            <label for="state">{{$t("teachers_quote.state")}}</label>
            <input id="state" class="form-control" v-model="state" type="text" required />
          </div>
        </div>
        <div class="buttons">
          <secondary-button class="next pull-right">
            {{ $t("common.next") }}
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
