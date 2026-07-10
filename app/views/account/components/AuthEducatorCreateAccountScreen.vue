<template>
  <section class="auth-educator-create-screen">
    <div class="auth-card">
      <div class="wordmark-row">
        <mixed-color-label
          class="wordmark"
          text="Code**Combat"
          :inherit-default-color="true"
        />
      </div>

      <auth-step-progress
        :current-step="currentStep"
        :total-steps="4"
      />

      <div class="copy-block">
        <span class="path-pill">Educator</span>
        <h1>{{ stepTitle }}</h1>
        <p>{{ stepDescription }}</p>
      </div>

      <form
        v-if="currentStep === 2"
        @submit.prevent="goToRoleStep"
      >
        <div class="name-row">
          <div class="field-group">
            <label
              class="field-label"
              for="edu-first-name"
            >First name</label>
            <input
              id="edu-first-name"
              v-model.trim="localForm.firstName"
              class="field-input"
              type="text"
              autocomplete="given-name"
              placeholder="Maria"
            >
          </div>
          <div class="field-group">
            <label
              class="field-label"
              for="edu-last-name"
            >Last name</label>
            <input
              id="edu-last-name"
              v-model.trim="localForm.lastName"
              class="field-input"
              type="text"
              autocomplete="family-name"
              placeholder="Rivera"
            >
          </div>
        </div>

        <label
          class="field-label mt"
          for="edu-email"
        >Email address</label>
        <input
          id="edu-email"
          v-model.trim="localForm.email"
          class="field-input"
          type="email"
          autocomplete="email"
          placeholder="you@school.edu"
        >

        <label
          class="field-label mt"
          for="edu-password"
        >Password</label>
        <input
          id="edu-password"
          v-model="localForm.password"
          class="field-input"
          type="password"
          autocomplete="new-password"
        >
        <p class="hint-copy">
          4 to 64 characters with no repeating.
        </p>

        <p
          v-if="errorMessage"
          class="error-copy"
        >
          {{ errorMessage }}
        </p>

        <button
          class="primary-action"
          type="submit"
          :disabled="!basicDetailsValid"
        >
          Continue
        </button>
      </form>

      <form
        v-else-if="currentStep === 3"
        @submit.prevent="goToProductStep"
      >
        <label
          class="field-label"
          for="edu-primary-role"
        >
          Your primary role
          <span class="required-mark">Required</span>
        </label>
        <select
          id="edu-primary-role"
          v-model="localForm.primaryRole"
          class="field-input"
        >
          <option value="">
            Select your role
          </option>
          <option
            v-for="role in roleOptions"
            :key="role.value"
            :value="role.value"
          >
            {{ role.label }}
          </option>
        </select>

        <div class="field-grid field-grid--double mt-grid">
          <div>
            <label
              class="field-label"
              for="edu-school-name"
            >
              {{ schoolFieldLabel }}
              <span
                v-if="roleRules.schoolName"
                class="required-mark"
              >Required</span>
              <span
                v-else
                class="optional-mark"
              >Optional</span>
            </label>
            <input
              id="edu-school-name"
              v-model.trim="localForm.schoolName"
              class="field-input"
              type="text"
              :placeholder="schoolFieldPlaceholder"
            >
          </div>

          <div>
            <label
              class="field-label"
              for="edu-district-name"
            >
              District name
              <span
                v-if="roleRules.districtName"
                class="required-mark"
              >Required</span>
              <span
                v-else
                class="optional-mark"
              >Optional</span>
            </label>
            <input
              id="edu-district-name"
              v-model.trim="localForm.districtName"
              class="field-input"
              type="text"
              placeholder="Jefferson Unified"
            >
          </div>
        </div>

        <div class="field-grid field-grid--double mt-grid">
          <div>
            <label
              class="field-label"
              for="edu-city"
            >
              City
              <span class="required-mark">Required</span>
            </label>
            <input
              id="edu-city"
              v-model.trim="localForm.city"
              class="field-input"
              type="text"
              placeholder="Oakland"
            >
          </div>

          <div>
            <label
              class="field-label"
              for="edu-state-region"
            >
              State / Region
              <span class="required-mark">Required</span>
            </label>
            <input
              id="edu-state-region"
              v-model.trim="localForm.stateRegion"
              class="field-input"
              type="text"
              placeholder="California"
            >
          </div>
        </div>

        <div class="field-grid field-grid--double mt-grid">
          <div>
            <label
              class="field-label"
              for="edu-country"
            >
              Country
              <span class="required-mark">Required</span>
            </label>
            <select
              id="edu-country"
              v-model="localForm.country"
              class="field-input"
            >
              <option value="">
                Select country
              </option>
              <option
                v-for="country in countries"
                :key="country"
                :value="country"
              >
                {{ country }}
              </option>
            </select>
          </div>

          <div>
            <label
              class="field-label"
              for="edu-students-playing"
            >
              Students playing
              <span class="required-mark">Required</span>
            </label>
            <select
              id="edu-students-playing"
              v-model="localForm.studentsPlaying"
              class="field-input"
            >
              <option value="">
                Select range
              </option>
              <option
                v-for="band in studentBands"
                :key="band"
                :value="band"
              >
                {{ band }}
              </option>
            </select>
          </div>
        </div>

        <label
          class="field-label mt"
          for="edu-phone-number"
        >
          Phone number
          <span class="optional-mark">Optional</span>
        </label>
        <input
          id="edu-phone-number"
          v-model.trim="localForm.phoneNumber"
          class="field-input"
          type="tel"
          autocomplete="tel"
          placeholder="(555) 123-4567"
        >

        <p class="role-note">
          {{ roleGuidanceCopy }}
        </p>

        <p
          v-if="errorMessage"
          class="error-copy"
        >
          {{ errorMessage }}
        </p>

        <button
          class="primary-action"
          type="submit"
          :disabled="!roleDetailsValid"
        >
          Continue
        </button>
      </form>

      <form
        v-else
        @submit.prevent="submitForm"
      >
        <div class="product-grid">
          <label
            v-for="product in productOptions"
            :key="product.value"
            :class="productCardClasses(product.value)"
          >
            <input
              v-model="localForm.selectedProduct"
              class="product-radio"
              type="radio"
              name="educator-product"
              :value="product.value"
            >
            <div class="product-meta">{{ product.gradeBand }}</div>
            <div class="product-header">
              <span class="product-title">{{ product.label }}</span>
              <span class="product-check">{{ localForm.selectedProduct === product.value ? 'Selected' : 'Choose' }}</span>
            </div>
            <p class="product-description">{{ product.description }}</p>
          </label>
        </div>

        <div class="dev-banner">
          TODO before ship: demo and quote checkboxes stay inert until sales pipe wiring lands.
        </div>

        <!--
          TODO(ENG-1268): wire demo/quote checkboxes + product selection into the sales/CRM pipe before shipping
        -->
        <div class="followup-box">
          <label
            class="checkbox-row"
            for="educator-request-demo"
          >
            <input
              id="educator-request-demo"
              v-model="localForm.requestDemo"
              type="checkbox"
            >
            <span>Request a demo</span>
          </label>
          <label
            class="checkbox-row"
            for="educator-request-quote"
          >
            <input
              id="educator-request-quote"
              v-model="localForm.requestQuote"
              type="checkbox"
            >
            <span>Request a quote</span>
          </label>
          <p class="demo-warning">
            DEMO - CHECKBOXES NOT YET IN USE
          </p>
        </div>

        <p
          v-if="errorMessage"
          class="error-copy"
        >
          {{ errorMessage }}
        </p>
        <p
          v-if="submitBlockedMessage"
          class="error-copy"
        >
          {{ submitBlockedMessage }}
        </p>

        <button
          class="primary-action"
          type="submit"
          :disabled="submitting || !localForm.selectedProduct"
        >
          {{ submitting ? 'Creating account…' : 'Create teacher account' }}
        </button>
      </form>
    </div>
  </section>
</template>

<script>
import MixedColorLabel from 'app/components/common/labels/MixedColorLabel.vue'
import AuthStepProgress from './AuthStepProgress.vue'

const roleOptions = [
  { value: 'Teacher', label: 'Teacher' },
  { value: 'Technology coordinator', label: 'Technology coordinator' },
  { value: 'School administrator', label: 'School administrator' },
  { value: 'District administrator', label: 'District administrator' },
  { value: 'Librarian', label: 'Librarian' },
  { value: 'Learning center educator', label: 'Learning center educator' },
  { value: 'Other', label: 'Other' },
]

const studentBands = ['1-10', '11-50', '51-100', '101-200', '201-500', '501-1000', '1000+']

const productOptions = [
  {
    value: 'junior',
    label: 'Junior',
    gradeBand: 'K-5',
    description: 'Flexible early coding with drag-and-drop, hybrid, and text-based paths.',
  },
  {
    value: 'codecombat',
    label: 'CodeCombat Classroom',
    gradeBand: '6-12',
    description: 'Core CS curriculum with pathways into AP CSP, web development, and game development.',
  },
  {
    value: 'ozaria',
    label: 'Ozaria',
    gradeBand: 'Middle School',
    description: 'Narrative-first computer science curriculum built to establish coding fundamentals.',
  },
  {
    value: 'hackstack',
    label: 'HackStack',
    gradeBand: '6-12',
    description: 'AI project workflows for prompt-to-project creation and responsible AI practice.',
  },
]

const orgRoleValues = ['Librarian', 'Learning center educator', 'Other']
const districtRoleValues = ['District administrator']

export default Vue.extend({
  name: 'AuthEducatorCreateAccountScreen',
  components: {
    MixedColorLabel,
    AuthStepProgress,
  },
  props: {
    form: {
      type: Object,
      required: true,
    },
    currentStep: {
      type: Number,
      default: 2,
    },
    submitting: {
      type: Boolean,
      default: false,
    },
    errorMessage: {
      type: String,
      default: '',
    },
  },
  data () {
    return {
      countries: require('country-list')().getNames(),
      roleOptions,
      studentBands,
      productOptions,
      submitBlockedMessage: '',
      localForm: {
        firstName: this.form.firstName || '',
        lastName: this.form.lastName || '',
        email: this.form.email || '',
        password: this.form.password || '',
        primaryRole: this.form.primaryRole || '',
        schoolName: this.form.schoolName || '',
        districtName: this.form.districtName || '',
        city: this.form.city || '',
        stateRegion: this.form.stateRegion || '',
        country: this.form.country || '',
        studentsPlaying: this.form.studentsPlaying || '',
        phoneNumber: this.form.phoneNumber || '',
        selectedProduct: this.form.selectedProduct || '',
        requestDemo: Boolean(this.form.requestDemo),
        requestQuote: Boolean(this.form.requestQuote),
      },
    }
  },
  computed: {
    stepTitle () {
      if (this.currentStep === 2) return 'Create a free educator account'
      if (this.currentStep === 3) return 'Tell us about yourself'
      return 'Which solution do you want to start with?'
    },
    stepDescription () {
      if (this.currentStep === 2) return 'Your turnkey CS solution is just a few clicks away.'
      if (this.currentStep === 3) return 'We use your role to tailor which organization details we require.'
      return 'Choose one product to open in your teacher dashboard after signup.'
    },
    basicDetailsValid () {
      return Boolean(
        this.localForm.firstName &&
          this.localForm.lastName &&
          this.localForm.email &&
          this.localForm.password.length >= 4,
      )
    },
    roleRules () {
      if (districtRoleValues.includes(this.localForm.primaryRole)) {
        return { schoolName: false, districtName: true }
      }
      if (orgRoleValues.includes(this.localForm.primaryRole)) {
        return { schoolName: true, districtName: false }
      }
      return { schoolName: true, districtName: true }
    },
    schoolFieldLabel () {
      return orgRoleValues.includes(this.localForm.primaryRole) ? 'Organization name' : 'School name'
    },
    schoolFieldPlaceholder () {
      return orgRoleValues.includes(this.localForm.primaryRole) ? 'Oakland Public Library' : 'Jefferson Middle School'
    },
    roleGuidanceCopy () {
      if (districtRoleValues.includes(this.localForm.primaryRole)) {
        return 'District administrators can leave school name blank, but district details stay required.'
      }
      if (orgRoleValues.includes(this.localForm.primaryRole)) {
        return 'For librarian, learning center, and other roles, use organization name instead of school name.'
      }
      return 'Teacher, technology coordinator, and school administrator roles require both school and district details.'
    },
    roleDetailsValid () {
      if (!this.localForm.primaryRole) return false
      if (this.roleRules.schoolName && !this.localForm.schoolName) return false
      if (this.roleRules.districtName && !this.localForm.districtName) return false
      return Boolean(
        this.localForm.city &&
          this.localForm.stateRegion &&
          this.localForm.country &&
          this.localForm.studentsPlaying,
      )
    },
  },
  watch: {
    form: {
      deep: true,
      handler (nextForm) {
        Object.assign(this.localForm, {
          firstName: nextForm.firstName || '',
          lastName: nextForm.lastName || '',
          email: nextForm.email || '',
          password: nextForm.password || '',
          primaryRole: nextForm.primaryRole || '',
          schoolName: nextForm.schoolName || '',
          districtName: nextForm.districtName || '',
          city: nextForm.city || '',
          stateRegion: nextForm.stateRegion || '',
          country: nextForm.country || '',
          studentsPlaying: nextForm.studentsPlaying || '',
          phoneNumber: nextForm.phoneNumber || '',
          selectedProduct: nextForm.selectedProduct || '',
          requestDemo: Boolean(nextForm.requestDemo),
          requestQuote: Boolean(nextForm.requestQuote),
        })
      },
    },
    localForm: {
      deep: true,
      handler () {
        this.submitBlockedMessage = ''
        this.$emit('update-form', { ...this.localForm })
      },
    },
  },
  methods: {
    goToRoleStep () {
      if (!this.basicDetailsValid) return
      this.$emit('step-change', 3)
    },
    goToProductStep () {
      if (!this.roleDetailsValid) return
      this.$emit('step-change', 4)
    },
    productCardClasses (value) {
      return {
        'product-card': true,
        'product-card--selected': this.localForm.selectedProduct === value,
      }
    },
    submitForm () {
      if (!this.localForm.selectedProduct) {
        this.submitBlockedMessage = 'Select a product before continuing.'
        return
      }
      this.$emit('submit', { ...this.localForm })
    },
  },
})
</script>

<style lang="scss" scoped>
@import "app/styles/component_variables.scss";

.auth-card {
  background: rgba(255, 255, 255, 0.98);
  border-radius: 28px;
  padding: 20px 18px 18px;
}

.wordmark-row {
  display: flex;
  justify-content: center;
}

.wordmark {
  font-size: 20px;
  font-weight: 800;
}

:deep(.wordmark .mixed-color-label__normal) { color: #17314d; }
:deep(.wordmark .mixed-color-label__highlight) { color: #7a65fc; }

.copy-block {
  margin-top: 12px;
  text-align: center;
}

.path-pill {
  display: inline-flex;
  margin-bottom: 10px;
  padding: 6px 14px;
  border-radius: 999px;
  background: rgba(122, 101, 252, 0.12);
  color: #6d5df6;
  font-size: 12px;
  font-weight: 800;
}

h1 {
  margin: 0;
  color: #17314d;
  font-size: 24px;
  font-weight: 800;
  line-height: 1.1;
}

p {
  margin: 5px 0 0;
  color: #5b6b7c;
  font-size: 13px;
  line-height: 1.4;
}

form {
  margin-top: 14px;
}

.name-row,
.field-grid--double {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px;
}

.field-group {
  display: flex;
  flex-direction: column;
}

.field-label {
  display: block;
  color: #17314d;
  font-size: 12px;
  font-weight: 600;
  margin-bottom: 5px;
}

.mt {
  margin-top: 12px;
}

.mt-grid {
  margin-top: 12px;
}

.required-mark,
.optional-mark {
  margin-left: 6px;
  font-size: 11px;
  font-weight: 700;
}

.required-mark {
  color: #6d5df6;
}

.optional-mark {
  color: #8b95a7;
}

.field-input {
  width: 100%;
  border-radius: 10px;
  border: 1px solid #d9ddf6;
  background: #fbfbff;
  padding: 10px 12px;
  color: #17314d;
  font-size: 14px;
  line-height: 1.3;
}

.field-input:focus {
  outline: 2px solid rgba(122, 101, 252, 0.22);
  border-color: #7a65fc;
}

.hint-copy {
  margin-top: 5px;
  font-size: 11px;
  color: #8b95a7;
}

.role-note {
  margin-top: 10px;
  color: #6a7590;
  font-size: 12px;
}

.product-grid {
  display: grid;
  gap: 10px;
}

.product-card {
  display: block;
  border: 1px solid rgba(122, 101, 252, 0.16);
  border-radius: 18px;
  background: linear-gradient(180deg, #fff 0%, #f9f7ff 100%);
  padding: 14px;
  cursor: pointer;
}

.product-card--selected {
  border-color: #7a65fc;
  box-shadow: 0 14px 32px rgba(122, 101, 252, 0.16);
}

.product-radio {
  position: absolute;
  opacity: 0;
  pointer-events: none;
}

.product-meta {
  display: inline-flex;
  margin-bottom: 10px;
  padding: 4px 10px;
  border-radius: 999px;
  background: rgba(122, 101, 252, 0.1);
  color: #6d5df6;
  font-size: 11px;
  font-weight: 800;
  text-transform: uppercase;
}

.product-header {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  gap: 12px;
}

.product-title {
  color: #17314d;
  font-size: 17px;
  font-weight: 800;
  line-height: 1.2;
}

.product-check {
  color: #6d5df6;
  font-size: 11px;
  font-weight: 800;
  text-transform: uppercase;
}

.product-description {
  margin-top: 8px;
  color: #5b6b7c;
  font-size: 13px;
  line-height: 1.5;
}

.dev-banner {
  margin-top: 14px;
  padding: 10px 12px;
  border-radius: 12px;
  border: 1px solid rgba(204, 56, 70, 0.24);
  background: rgba(204, 56, 70, 0.06);
  color: #a12632;
  font-size: 12px;
  font-weight: 700;
  line-height: 1.4;
}

.followup-box {
  margin-top: 12px;
  padding: 14px;
  border-radius: 16px;
  background: #f8f7ff;
  border: 1px solid rgba(122, 101, 252, 0.12);
}

.checkbox-row {
  display: flex;
  align-items: center;
  gap: 10px;
  color: #17314d;
  font-size: 14px;
  font-weight: 600;
}

.checkbox-row + .checkbox-row {
  margin-top: 10px;
}

.demo-warning {
  margin-top: 12px;
  color: #cc3846;
  font-size: 12px;
  font-style: italic;
  font-weight: 700;
}

.error-copy {
  color: #cc3846;
  font-size: 12px;
  margin-top: 8px;
}

.primary-action {
  width: 100%;
  margin-top: 14px;
  border: 0;
  border-radius: 12px;
  padding: 12px 20px;
  background: #7a65fc;
  color: #fff;
  font-size: 15px;
  font-weight: 700;
  cursor: pointer;
}

.primary-action:disabled {
  opacity: 0.5;
}

@media screen and (max-width: 640px) {
  .name-row,
  .field-grid--double,
  .product-header {
    grid-template-columns: 1fr;
    display: grid;
  }
}
</style>
