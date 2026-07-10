<template>
  <section class="auth-parent-add-child-screen">
    <div class="auth-card">
      <div class="wordmark-row">
        <mixed-color-label
          class="wordmark"
          text="Code**Combat"
          :inherit-default-color="true"
        />
      </div>

      <div class="copy-block">
        <span class="path-pill">Parent</span>
        <h1>Add your child</h1>
        <p>Set up their profile. You can add more kids later.</p>
      </div>

      <form
        class="child-form"
        @submit.prevent="submitForm"
      >
        <label
          class="field-label"
          for="child-first-name"
        >Child's first name</label>
        <input
          id="child-first-name"
          v-model.trim="form.childFirstName"
          class="field-input"
          type="text"
          autocomplete="off"
          placeholder="Sofia"
        >

        <label
          class="field-label mt"
          for="child-username"
        >Child's username</label>
        <input
          id="child-username"
          v-model.trim="form.childUsername"
          class="field-input"
          type="text"
          autocomplete="off"
          placeholder="Choose a username"
        >

        <label
          class="field-label mt"
          for="child-grade"
        >Grade</label>
        <select
          id="child-grade"
          v-model="form.grade"
          class="field-input field-select"
        >
          <option value="">
            Select grade
          </option>
          <option value="kindergarten">
            Kindergarten
          </option>
          <option value="1">
            1st grade
          </option>
          <option value="2">
            2nd grade
          </option>
          <option value="3">
            3rd grade
          </option>
          <option value="4">
            4th grade
          </option>
          <option value="5">
            5th grade
          </option>
          <option value="6">
            6th grade
          </option>
          <option value="7">
            7th grade
          </option>
          <option value="8">
            8th grade
          </option>
          <option value="9">
            9th grade
          </option>
          <option value="10">
            10th grade
          </option>
          <option value="11">
            11th grade
          </option>
          <option value="12">
            12th grade
          </option>
          <option value="13+">
            College+
          </option>
        </select>

        <p
          v-if="errorMessage"
          class="error-copy"
        >
          {{ errorMessage }}
        </p>

        <button
          class="primary-action"
          type="submit"
          :disabled="submitting || !isValid"
        >
          {{ submitting ? 'Creating profile...' : 'Create child profile' }}
        </button>
      </form>
    </div>
  </section>
</template>

<script>
import MixedColorLabel from 'app/components/common/labels/MixedColorLabel.vue'

export default Vue.extend({
  name: 'AuthParentAddChildScreen',
  components: { MixedColorLabel },
  props: {
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
      form: {
        childFirstName: '',
        childUsername: '',
        grade: '',
      },
    }
  },
  computed: {
    isValid () {
      return Boolean(this.form.childFirstName && this.form.childUsername && this.form.grade)
    },
  },
  methods: {
    submitForm () {
      this.$emit('submit', { ...this.form })
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
  align-items: center;
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

.child-form {
  margin-top: 16px;
}

.field-label {
  display: block;
  color: #17314d;
  font-size: 12px;
  font-weight: 600;
  margin-bottom: 5px;
}

.field-label.mt {
  margin-top: 14px;
}

.field-input {
  width: 100%;
  border-radius: 10px;
  border: 1px solid #d9ddf6;
  background: #fbfbff;
  padding: 11px 13px;
  color: #17314d;
  font-size: 14px;
  line-height: 1.3;
}

.field-select {
  appearance: none;
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='8' viewBox='0 0 12 8'%3E%3Cpath d='M1 1l5 5 5-5' stroke='%238b95a7' stroke-width='1.5' fill='none' stroke-linecap='round'/%3E%3C/svg%3E");
  background-repeat: no-repeat;
  background-position: right 13px center;
  padding-right: 36px;
}

.field-input:focus {
  outline: 2px solid rgba(122, 101, 252, 0.22);
  border-color: #7a65fc;
}

.error-copy {
  color: #cc3846;
  font-size: 12px;
  margin-top: 8px;
}

.primary-action {
  width: 100%;
  margin-top: 16px;
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
</style>
