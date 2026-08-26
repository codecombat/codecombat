<script>
import { validationMixin } from 'vuelidate'
import { requiredIf } from 'vuelidate/lib/validators'

import utils from 'core/utils'
import CourseSelect from './CourseSelect'
import GoogleClassroomImportSource from './import-sources/GoogleClassroomImportSource.vue'
import OtherProductImportSource from './import-sources/OtherProductImportSource.vue'
import LmsImportSource from './import-sources/LmsImportSource.vue'

// Each entry's component owns its own button, fetch, and picker for that source,
// and emits a normalized `linked` payload: { source, externalId, name, members? }.
const IMPORT_SOURCES = [
  { key: 'google', component: GoogleClassroomImportSource },
  { key: 'otherProduct', component: OtherProductImportSource },
  { key: 'lms', component: LmsImportSource },
]

export default Vue.extend({
  components: {
    CourseSelect,
  },
  mixins: [validationMixin],
  props: {
    classroom: {
      type: Object,
      required: true,
    },
    value: {
      type: Object,
      required: true,
    },
    // Parent sets this to true once it has attempted to move past this page,
    // so validation errors are only revealed on a submit attempt rather than while typing.
    showValidation: {
      type: Boolean,
      default: false,
    },
  },
  validations: {
    name: {
      required: requiredIf(function () { return !this.activeSource }),
    },
    importLink: {
      externalId: {
        required: requiredIf(function () { return !!this.activeSource }),
      },
    },
  },
  data () {
    return {
      // one of null, 'google', 'otherProduct', 'lms'
      activeSource: null,
    }
  },
  computed: {
    isCodeCombat () {
      return utils.isCodeCombat
    },
    importSources () {
      return IMPORT_SOURCES
    },
    // Proxies onto the single draft object owned by the parent (this.value) -
    // no local copy, so there is only ever one source of truth for the draft.
    name: {
      get () { return this.value.name },
      set (val) { this.updateDraft({ name: val }) },
    },
    initCourse: {
      get () { return this.value.initCourse },
      set (val) { this.updateDraft({ initCourse: val }) },
    },
    importLink: {
      get () { return this.value.importLink || { source: null, externalId: null, members: null } },
      set (val) { this.updateDraft({ importLink: val }) },
    },
    isValid () {
      return !this.$v.$invalid
    },
  },
  watch: {
    isValid: {
      immediate: true,
      handler (valid) {
        this.$emit('update:valid', valid)
      },
    },
    // Reveal validation errors only once the parent has attempted to move past this page.
    showValidation: {
      immediate: true,
      handler (shouldShow) {
        if (shouldShow) {
          this.$v.$touch()
        }
      },
    },
  },
  methods: {
    updateDraft (patch) {
      this.$emit('input', { ...this.value, ...patch })
    },
    onLinked (payload) {
      this.updateDraft({
        name: payload.name,
        importLink: { source: payload.source, externalId: payload.externalId, members: payload.members || null },
      })
    },
  },
})
</script>

<template>
  <div class="page-first">
    <div class="form-container container">
      <div class="link-buttons-container">
        <component
          :is="source.component"
          v-for="source in importSources"
          :key="source.key"
          :classroom="classroom"
          :active="activeSource === source.key"
          :hidden-by-other="!!activeSource && activeSource !== source.key"
          :show-validation="showValidation"
          :selected-external-id="activeSource === source.key ? importLink.externalId : null"
          @activate="activeSource = source.key"
          @linked="onLinked"
        />
      </div>
      <template v-if="!activeSource">
        <div
          class="form-group row class-name"
        >
          <div
            class="col-xs-12"
            :class="{ 'has-error': $v.name.$error }"
          >
            <label for="form-class-name">
              <h5 class="control-label">
                {{ $t("teachers.class_name") }}
              </h5>
            </label>
            <input
              id="form-class-name"
              v-model="$v.name.$model"
              type="text"
              class="form-control"
            >
          </div>
        </div>
      </template>
      <div
        class="form-group row"
      >
        <CourseSelect v-model="initCourse" />
      </div>
      <div
        class="form-group row help-info-row"
      >
        <div class="help-info">
          <p class="question help-text help-bold">
            {{ $t('teachers.recommended_courses_helptext_question') }}
          </p>
          <p class="answer help-text">
            {{ $t('teachers.recommended_courses_helptext_answer') }}
          </p>
          <p class="answer help-text help-bold">
            {{ $t('teachers.recommended_courses_helptext_info') }}
          </p>
        </div>
      </div>
    </div>
  </div>
</template>
<style lang="scss" scoped>
@import "ozaria/site/styles/common/variables.scss";
.help-text {
  font-size: 14px;
  line-height: 20px;
  margin-bottom: 1px;
}
.help-bold {
  font-weight: bold;
}
.help-info-row {
  text-align: center;
  margin-top: -10px;
  margin-bottom: 5px;
}
.help-info {
  display: inline-block;
  text-align: center;
  background-color: $mist;
  padding: 5px 15px;
}
.link-buttons-container {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 20px;
  margin-bottom: 5px;
}
</style>
