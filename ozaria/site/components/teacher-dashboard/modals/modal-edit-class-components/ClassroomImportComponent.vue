<template>
  <div class="class-import-component">
    <div
      v-if="isGoogleClassroomForm"
      class="form-group row google-class-id"
      :class="{ 'has-error': $v.googleClassId.$error }"
    >
      <div class="col-xs-12">
        <span class="control-label">
          <img
            class="small-google-icon"
            src="/images/ozaria/teachers/dashboard/svg_icons/IconGoogleClassroom.svg"
          >
          {{ $t("teachers.select_class") }}
        </span>
        <select
          v-model="$v.googleClassId.$model"
          class="form-control"
          :class="{ 'placeholder-text': !googleClassId }"
          name="googleClassId"
          :disabled="googleClassrooms.length === 0"
        >
          <option
            v-if="googleClassrooms.length === 0"
            disabled
            selected
            value=""
          >
            All google classrooms already imported
          </option>
          <option
            v-else
            disabled
            selected
            value=""
          >
            Select to Import from Google Classroom
          </option>
          <option
            v-for="gClassroom in googleClassrooms"
            :key="gClassroom.id"
            :value="gClassroom.id"
          >
            {{ gClassroom.name }}
          </option>
        </select>
        <span
          v-if="!$v.googleClassId.required"
          class="form-error"
        >
          {{ $t("form_validation_errors.required") }}
        </span>
      </div>
    </div>
    <div v-else-if="isOtherProductForm">
      {{ $t(isCodeCombat? "teachers.select_ozaria_classroom": "teachers.select_codecombat_classroom") }}
      <select
        v-model="$v.otherProductClassroomId.$model"
        class="form-control"
        :class="{ 'placeholder-text': !otherProductClassroomId }"
        name="otherProductClassroomId"
        :disabled="otherProductClassrooms.length === 0"
      >
        <option
          v-if="otherProductClassrooms.length === 0"
          disabled
          selected
          value=""
        >
          {{ $t('teachers.all_classrooms_imported') }}
        </option>
        <option
          v-else
          disabled
          selected
          value=""
        >
          {{ $t(isCodeCombat? 'teachers.select_to_import_from_ozaria': 'teachers.select_to_import_from_codecombat') }}
        </option>
        <option
          v-for="imortableClassroom in otherProductClassrooms"
          :key="imortableClassroom._id"
          :value="imortableClassroom._id"
        >
          {{ imortableClassroom.name }}
        </option>
      </select>
      <span
        v-if="!$v.otherProductClassroomId.required"
        class="form-error"
      >
        {{ $t("form_validation_errors.required") }}
      </span>
    </div>
    <div v-else-if="lmsProductForm">
      {{ $t('teachers.import_classroom') }}
      <select
        v-model="$v.lmsClassroomId.$model"
        class="form-control"
        :class="{ 'placeholder-text': !lmsClassroomId }"
        name="lmsClassroomId"
        :disabled="lmsClassrooms.length === 0"
        placeholder="Select Class"
      >
        <option
          v-if="lmsClassrooms.length === 0"
          disabled
          selected
          value=""
        >
          {{ $t('courses.no_classrooms_found') }}
        </option>
        <option
          v-for="importableClassroom in lmsClassrooms"
          :key="importableClassroom.id"
          :value="importableClassroom.id"
        >
          {{ importableClassroom.name }}
        </option>
      </select>
      <span
        v-if="!$v.lmsClassroomId.required"
        class="form-error"
      >
        {{ $t("form_validation_errors.required") }}
      </span>
    </div>
  </div>
</template>

<script>
import { validationMixin } from 'vuelidate'
import { requiredIf } from 'vuelidate/lib/validators'
import utils from 'core/utils'

export default Vue.extend({
  name: 'ClassroomImportComponent',
  mixins: [validationMixin],
  props: {
    isGoogleClassroomForm: {
      type: Boolean,
      required: false,
      default: false,
    },
    isOtherProductForm: {
      type: Boolean,
      required: false,
      default: false,
    },
    lmsProductForm: {
      type: Boolean,
      required: false,
      default: false,
    },
    otherProductClassrooms: {
      type: Array,
      required: false,
      default: () => [],
    },
    googleClassrooms: {
      type: Array,
      required: false,
      default: () => [],
    },
    lmsClassrooms: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data () {
    return {
      googleClassId: '',
      otherProductClassroomId: '',
      lmsClassroomId: '',
    }
  },
  computed: {
    isCodeCombat () {
      return utils.isCodeCombat
    },
  },
  validations: {
    googleClassId: {
      required: requiredIf(function () { return this.isGoogleClassroomForm }),
    },
    otherProductClassroomId: {
      required: requiredIf(function () { return this.isOtherProductForm }),
    },
    lmsClassroomId: {
      required: requiredIf(function () { return this.lmsProductForm }),
    },
  },
  watch: {
    googleClassId (newVal) {
      this.$emit('googleClassroomIdUpdated', newVal)
    },
    otherProductClassroomId (newVal) {
      this.$emit('otherProductClassroomIdUpdated', newVal)
    },
    lmsClassroomId (newVal) {
      this.$emit('lmsClassroomIdUpdated', newVal)
    },
  },
})
</script>

<style lang="scss" scoped>
@import "app/styles/ozaria/_ozaria-style-params.scss";

.form-error {
  @include font-p-4-paragraph-smallest-gray;
  display: inline-block;
  color: $color-concept-flag-color !important;
}
</style>
