<script>
import utils from 'core/utils'
import ClassroomsApi from 'app/core/api/classrooms.js'
import ButtonImportClassroom from 'ozaria/site/components/teacher-dashboard/modals/common/ButtonImportClassroom.vue'

export default Vue.extend({
  name: 'OtherProductImportSource',
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
      otherProductClassrooms: null,
    }
  },
  computed: {
    isCodeCombat () {
      return utils.isCodeCombat
    },
    allowed () {
      return utils.isCodeCombat && !this.classroom.otherProductId && !this.hiddenByOther
    },
    showRequiredError () {
      return this.active && this.showValidation && !this.selectedExternalId
    },
    selectedId: {
      get () { return this.selectedExternalId },
      set (newVal) {
        const otherProductClassroom = (this.otherProductClassrooms || []).find((c) => c._id === newVal)
        this.$emit('linked', {
          source: 'otherProduct',
          externalId: newVal,
          name: otherProductClassroom.name,
          members: otherProductClassroom.members,
        })
      },
    },
  },
  methods: {
    async link () {
      window.tracker?.trackEvent('Add New Class: Link Other Product Classroom Clicked', { category: 'Teachers' })
      this.isSyncInProgress = true
      try {
        this.otherProductClassrooms = (await ClassroomsApi.fetchByOwner(me.get('_id'), { callOz: true }))
          .filter(otherClassroom => !otherClassroom.otherProductId)
        this.$emit('activate')
        window.tracker?.trackEvent('Add New Class: Link Other Product Classroom Successful', { category: 'Teachers' })
      } catch (error) {
        console.log(error)
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
    class="other-product-import-source"
  >
    <div
      v-if="!active"
      class="other-product-classroom-div"
    >
      <button-import-classroom
        :in-progress="isSyncInProgress"
        icon-src="/images/ozaria/home/ozaria-logo.png"
        :icon-src-inactive="isCodeCombat ? '/images/ozaria/home/ozaria-logo.png' : '/images/pages/base/logo_square_250.png'"
        :text="$t(isCodeCombat ? 'teachers.import_ozaria_classroom' : 'teachers.import_codecombat_classroom')"
        @click="link"
      />
    </div>
    <div
      v-else
      class="form-group row"
      :class="{ 'has-error': showRequiredError }"
    >
      <p
        class="label-text"
      >
        {{ $t(isCodeCombat? "teachers.select_ozaria_classroom": "teachers.select_codecombat_classroom") }}
      </p>
      <select
        v-model="selectedId"
        class="form-control"
        :class="{ 'placeholder-text': !selectedId }"
        name="otherProductClassroomId"
        :disabled="(otherProductClassrooms || []).length === 0"
      >
        <option
          v-if="(otherProductClassrooms || []).length === 0"
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
          v-for="importableClassroom in otherProductClassrooms"
          :key="importableClassroom._id"
          :value="importableClassroom._id"
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
.label-text {
  font-size: 15px;
  line-height: 20px;
  margin-bottom: 5px;
}
</style>
