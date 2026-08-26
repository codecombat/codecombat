<script>
import GoogleClassroomHandler from 'core/social-handlers/GoogleClassroomHandler'
import ButtonGoogleClassroom from 'ozaria/site/components/teacher-dashboard/modals/common/ButtonGoogleClassroom.vue'

export default Vue.extend({
  name: 'GoogleClassroomImportSource',
  components: {
    ButtonGoogleClassroom,
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
      showGoogleClassroom: me.useGoogleClassroom(),
      isSyncInProgress: false,
      googleClassrooms: null,
    }
  },
  computed: {
    allowed () {
      return this.showGoogleClassroom && !this.hiddenByOther
    },
    googleClassroomDisabled () {
      return !me.googleClassroomEnabled()
    },
    showRequiredError () {
      return this.active && this.showValidation && !this.selectedExternalId
    },
    selectedId: {
      get () { return this.selectedExternalId },
      set (newVal) {
        const found = (this.googleClassrooms || []).find((c) => c.id === newVal)
        this.$emit('linked', { source: 'google', externalId: newVal, name: found?.name })
      },
    },
  },
  methods: {
    async link () {
      window.tracker?.trackEvent('Add New Class: Link Google Classroom Clicked', { category: 'Teachers' })
      this.isSyncInProgress = true
      try {
        await new Promise((resolve, reject) =>
          application.gplusHandler.loadAPI({
            success: resolve,
            error: reject,
          }))
        await GoogleClassroomHandler.importClassrooms()
        this.googleClassrooms = me.get('googleClassrooms').filter((c) => !c.importedToOzaria && !c.deletedFromGC)
        this.$emit('activate')
        window.tracker?.trackEvent('Add New Class: Link Google Classroom Successful', { category: 'Teachers' })
      } catch (err) {
        noty({ text: $.i18n.t('teachers.error_in_importing_classrooms'), layout: 'topCenter', type: 'error', timeout: 2000 })
      }
      this.isSyncInProgress = false
    },
  },
})
</script>

<template>
  <div
    v-if="allowed"
    class="google-classroom-import-source"
  >
    <div
      v-if="!active"
      class="google-classroom-div"
    >
      <button-google-classroom
        :inactive="googleClassroomDisabled"
        :in-progress="isSyncInProgress"
        text="Link Google Classroom"
        @click="link"
      />
    </div>
    <div
      v-else
      class="form-group row google-class-id"
      :class="{ 'has-error': showRequiredError }"
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
          v-model="selectedId"
          class="form-control"
          :class="{ 'placeholder-text': !selectedId }"
          name="googleClassId"
          :disabled="(googleClassrooms || []).length === 0"
        >
          <option
            v-if="(googleClassrooms || []).length === 0"
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
          v-if="showRequiredError"
          class="form-error"
        >
          {{ $t("form_validation_errors.required") }}
        </span>
      </div>
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
