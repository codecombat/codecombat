<script>
import OAuth2Api from 'app/core/api/oauth2.js'
import LmsRosterImportHandler from 'core/social-handlers/LmsRosterImportHandler'
import ButtonImportClassroom from 'ozaria/site/components/teacher-dashboard/modals/common/ButtonImportClassroom.vue'

export default Vue.extend({
  name: 'LmsImportSource',
  components: {
    ButtonImportClassroom,
  },
  props: {
    classroom: {
      type: Object,
      required: true,
    },
    active: {
      type: Boolean,
      default: false,
    },
    // true when a different import source is currently active, so this one should hide entirely.
    hiddenByOther: {
      type: Boolean,
      default: false,
    },
    showValidation: {
      type: Boolean,
      default: false,
    },
    selectedExternalId: {
      type: String,
      default: null,
    },
  },
  data () {
    return {
      isSyncInProgress: false,
      lmsClassrooms: null,
    }
  },
  computed: {
    showLmsButton () {
      return me.isSchoology() || me.isClassLink()
    },
    allowed () {
      return this.showLmsButton && !this.hiddenByOther
    },
    isNewClassroom () {
      return !this.classroom?._id
    },
    lmsKey () {
      if (me.isSchoology()) {
        return 'schoology'
      } else if (me.isClassLink()) {
        return 'classlink'
      }
      return null
    },
    lmsProductImage () {
      const imageMap = {
        schoology: '/images/pages/modal/auth/schoology.png',
        classlink: '/images/pages/modal/auth/classlink-logo-small.png',
      }
      return imageMap[this.lmsKey]
    },
    lmsProductText () {
      const textMap = {
        schoology: 'Schoology',
        classlink: 'ClassLink',
      }
      return textMap[this.lmsKey]
    },
    showRequiredError () {
      return this.active && this.showValidation && !this.selectedExternalId
    },
    selectedId: {
      get () { return this.selectedExternalId },
      set (newVal) {
        const found = (this.lmsClassrooms || []).find((c) => c.id === newVal)
        this.$emit('linked', { source: 'lms', externalId: newVal, name: found?.name })
      },
    },
  },
  methods: {
    async link () {
      this.isSyncInProgress = true
      try {
        this.lmsClassrooms = await OAuth2Api.getLmsClassrooms(this.lmsKey)
        this.$emit('activate')
      } catch (error) {
        console.log(error)
        noty({ text: $.i18n.t('teachers.error_in_importing_classrooms'), layout: 'topCenter', type: 'error', timeout: 5000 })
      }
      this.isSyncInProgress = false
    },
    async reImport () {
      this.isSyncInProgress = true
      noty({ text: 'Re-Importing classroom...', layout: 'topCenter', type: 'info', timeout: 3000 })
      try {
        await LmsRosterImportHandler.importClassroom(this.classroom)
      } catch (err) {
        noty({ text: `Importing classroom failed: ${err?.message}`, layout: 'topCenter', type: 'error', timeout: 5000 })
      }
      this.isSyncInProgress = false
    },
  },
})
</script>

<template>
  <div
    v-if="allowed"
    class="lms-import-source"
  >
    <div
      v-if="!active"
      class="lms-classroom-div"
    >
      <button-import-classroom
        v-if="isNewClassroom"
        :in-progress="isSyncInProgress"
        :icon-src="lmsProductImage"
        :icon-src-alt-text="lmsProductText"
        :icon-src-inactive="lmsProductImage"
        :text="$t('teachers.import_classroom')"
        @click="link"
      />
      <button-import-classroom
        v-else
        :in-progress="isSyncInProgress"
        :icon-src="lmsProductImage"
        :icon-src-alt-text="lmsProductText"
        :icon-src-inactive="lmsProductImage"
        :text="$t('teachers.re_import_classroom')"
        @click="reImport"
      />
    </div>
    <div
      v-else
      class="form-group row"
      :class="{ 'has-error': showRequiredError }"
    >
      {{ $t('teachers.import_classroom') }}
      <select
        v-model="selectedId"
        class="form-control"
        :class="{ 'placeholder-text': !selectedId }"
        name="lmsClassroomId"
        :disabled="(lmsClassrooms || []).length === 0"
        placeholder="Select Class"
      >
        <option
          v-if="(lmsClassrooms || []).length === 0"
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
        v-if="showRequiredError"
        class="form-error"
      >
        {{ $t("form_validation_errors.required") }}
      </span>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "app/styles/ozaria/_ozaria-style-params.scss";

.form-error {
  @include font-p-4-paragraph-smallest-gray;
  display: inline-block;
  color: $color-concept-flag-color !important;
}
</style>
