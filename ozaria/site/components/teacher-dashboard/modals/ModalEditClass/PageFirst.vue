<script>
import { validationMixin } from 'vuelidate'
import { requiredIf } from 'vuelidate/lib/validators'

import utils from 'core/utils'
import ClassroomsApi from 'app/core/api/classrooms.js'
import OAuth2Api from 'app/core/api/oauth2.js'
import GoogleClassroomHandler from 'core/social-handlers/GoogleClassroomHandler'
import ButtonGoogleClassroom from 'ozaria/site/components/teacher-dashboard/modals/common/ButtonGoogleClassroom.vue'
import ButtonImportClassroom from 'ozaria/site/components/teacher-dashboard/modals/common/ButtonImportClassroom.vue'
import CourseSelect from './CourseSelect'
import ClassroomImportComponent from '../modal-edit-class-components/ClassroomImportComponent.vue'
import BackgroundJobApi from 'app/core/api/background-job.js'

export default Vue.extend({
  components: {
    ButtonGoogleClassroom,
    ButtonImportClassroom,
    CourseSelect,
    ClassroomImportComponent,
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
  },
  validations: {
    name: {
      required: requiredIf(function () { return !this.isGoogleClassroomForm && !this.isOtherProductForm && !this.isLmsProductForm }),
    },
  },
  data () {
    return {
      showGoogleClassroom: me.useGoogleClassroom(),
      isSyncInProgress: false,
      // one of null, 'google', 'otherProduct', 'lms'
      lmsSelected: null,
      googleClassrooms: null,
      otherProductClassrooms: null,
      lmsClassrooms: null,
    }
  },
  computed: {
    isCodeCombat () {
      return utils.isCodeCombat
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
    googleClassroomId: {
      get () { return this.value.googleClassroomId },
      set (val) { this.updateDraft({ googleClassroomId: val }) },
    },
    otherProductClassroomId: {
      get () { return this.value.otherProductClassroomId },
      set (val) { this.updateDraft({ otherProductClassroomId: val }) },
    },
    lmsClassroomId: {
      get () { return this.value.lmsClassroomId },
      set (val) { this.updateDraft({ lmsClassroomId: val }) },
    },
    members: {
      get () { return this.value.members },
      set (val) { this.updateDraft({ members: val }) },
    },
    // kept as computed for compatibility with existing validations/template bindings
    isGoogleClassroomForm () {
      return this.lmsSelected === 'google'
    },
    isOtherProductForm () {
      return this.lmsSelected === 'otherProduct'
    },
    isLmsProductForm () {
      return this.lmsSelected === 'lms'
    },
    linkGoogleButtonAllowed () {
      return this.showGoogleClassroom && !this.isGoogleClassroomForm && !this.isOtherProductForm
    },
    linkOtherProductButtonAllowed () {
      return utils.isCodeCombat &&
        !this.classroom.otherProductId &&
        !this.isGoogleClassroomForm &&
        !this.isOtherProductForm
    },
    googleClassroomDisabled () {
      return !me.googleClassroomEnabled()
    },
    showLmsButton () {
      return me.isSchoology() || me.isClassLink()
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
    getProvider () {
      return this.lmsKey
    },
    lmsKey () {
      if (me.isSchoology()) {
        return 'schoology'
      } else if (me.isClassLink()) {
        return 'classlink'
      }
      return null
    },
    lmsClassroom () {
      return this.lmsClassrooms?.find((c) => c.id === this.lmsClassroomId)
    },
    isNewClassroom () {
      return !this.classroom?._id
    },
  },
  methods: {
    updateDraft (patch) {
      this.$emit('input', { ...this.value, ...patch })
    },
    async linkGoogleClassroom () {
      window.tracker?.trackEvent('Add New Class: Link Google Classroom Clicked', { category: 'Teachers' })
      this.isSyncInProgress = true
      await new Promise((resolve, reject) =>
        application.gplusHandler.loadAPI({
          success: resolve,
          error: reject,
        }))
      GoogleClassroomHandler.importClassrooms()
        .then(() => {
          this.googleClassrooms = me.get('googleClassrooms').filter((c) => !c.importedToOzaria && !c.deletedFromGC)
          this.lmsSelected = 'google'
          window.tracker?.trackEvent('Add New Class: Link Google Classroom Successful', { category: 'Teachers' })
        })
        .catch((e) => {
          noty({ text: $.i18n.t('teachers.error_in_importing_classrooms'), layout: 'topCenter', type: 'error', timeout: 2000 })
        })
      this.isSyncInProgress = false
    },
    async linkOtherProductClassroom () {
      window.tracker?.trackEvent('Add New Class: Link Other Product Classroom Clicked', { category: 'Teachers' })
      this.isSyncInProgress = true

      try {
        this.otherProductClassrooms = (await ClassroomsApi.fetchByOwner(me.get('_id'), { callOz: true }))
          .filter(otherClassroom => !otherClassroom.otherProductId)
        this.lmsSelected = 'otherProduct'
        window.tracker?.trackEvent('Add New Class: Link Other Product Classroom Successful', { category: 'Teachers' })
      } catch (error) {
        console.log(error)
        noty({ text: $.i18n.t('teachers.error_in_importing_classrooms'), layout: 'topCenter', type: 'error', timeout: 2000 })
      }
      this.isSyncInProgress = false
    },

    async linkLmsClassroom () {
      this.isSyncInProgress = true
      try {
        this.lmsClassrooms = await OAuth2Api.getLmsClassrooms(this.getProvider)
        this.lmsSelected = 'lms' // schoology, classlink based on edlink
      } catch (error) {
        console.log(error)
        noty({ text: $.i18n.t('teachers.error_in_importing_classrooms'), layout: 'topCenter', type: 'error', timeout: 2000 })
      }
      this.isSyncInProgress = false
    },
    async reImportExistingLmsClassroom () {
      this.lmsSyncInProgress = true
      noty({ text: 'Re-Importing classroom...', layout: 'topCenter', type: 'info', timeout: 3000 })
      await this.handleLmsClassroomImport(this.classroom)
      this.lmsSyncInProgress = false
      this.$emit('close')
      window.location.reload()
    },
    async handleLmsClassroomImport (savedClassroom) {
      const job = await BackgroundJobApi.create('oauth2-roster-class', {
        classroomId: savedClassroom._id,
        lmsClassroomId: savedClassroom.lmsClassroom.classId,
        provider: savedClassroom.lmsClassroom.provider,
      })
      await BackgroundJobApi.pollTillResult(job.job, {
        showNotification: true,
      })
      window.location.reload()
    },
    validate () {
      this.$v.$touch()
      return !this.$v.$invalid
    },
    updateGoogleClassroomId (newVal) {
      const name = this.googleClassrooms.find((c) => c.id === newVal).name
      this.updateDraft({ googleClassroomId: newVal, name })
    },
    updateOtherProductClassroomId (newVal) {
      const otherProductClassroom = (this.otherProductClassrooms || [])
        .find((classroom) => classroom._id === newVal)
      this.updateDraft({
        otherProductClassroomId: newVal,
        name: otherProductClassroom.name,
        members: otherProductClassroom.members,
      })
    },
    updateLmsClassroomId (newVal) {
      const name = (this.lmsClassrooms || []).find((c) => c.id === newVal).name
      this.updateDraft({ lmsClassroomId: newVal, name })
    },
  },
})
</script>

<template>
  <div class="page-first">
    <div class="link-buttons-container">
      <div
        v-if="linkGoogleButtonAllowed"
        class="google-classroom-div"
      >
        <button-google-classroom
          :inactive="googleClassroomDisabled"
          :in-progress="isSyncInProgress"
          text="Link Google Classroom"
          @click="linkGoogleClassroom"
        />
      </div>
      <div
        v-if="linkOtherProductButtonAllowed"
        class="google-classroom-div"
      >
        <button-import-classroom
          :in-progress="isSyncInProgress"
          icon-src="/images/ozaria/home/ozaria-logo.png"
          :icon-src-inactive="isCodeCombat ? '/images/ozaria/home/ozaria-logo.png' : '/images/pages/base/logo_square_250.png'"
          :text="$t(isCodeCombat ? 'teachers.import_ozaria_classroom' : 'teachers.import_codecombat_classroom')"
          @click="linkOtherProductClassroom"
        />
      </div>
      <div
        v-if="showLmsButton"
        class="lms-classroom-div"
      >
        <button-import-classroom
          v-if="isNewClassroom"
          :in-progress="isSyncInProgress"
          :icon-src="lmsProductImage"
          :icon-src-alt-text="lmsProductText"
          :icon-src-inactive="lmsProductImage"
          :text="$t('teachers.import_classroom')"
          @click="linkLmsClassroom"
        />
        <button-import-classroom
          v-else
          :in-progress="isSyncInProgress"
          :icon-src="lmsProductImage"
          :icon-src-alt-text="lmsProductText"
          :icon-src-inactive="lmsProductImage"
          :text="$t('teachers.re_import_classroom')"
          @click="reImportExistingLmsClassroom"
        />
      </div>
    </div>
    <div class="form-container container">
      <classroom-import-component
        v-if="isOtherProductForm || isGoogleClassroomForm || isLmsProductForm"
        :is-google-classroom-form="isGoogleClassroomForm"
        :is-other-product-form="isOtherProductForm"
        :lms-product-form="isLmsProductForm"
        :other-product-classrooms="otherProductClassrooms"
        :google-classrooms="googleClassrooms"
        :lms-classrooms="lmsClassrooms"
        @googleClassroomIdUpdated="updateGoogleClassroomId"
        @otherProductClassroomIdUpdated="updateOtherProductClassroomId"
        @lmsClassroomIdUpdated="updateLmsClassroomId"
      />
      <template
        v-else
      >
        <div
          class="form-group row class-name"
        >
          <div
            class="col-xs-12"
            :class="{ 'has-error': $v.name.$error }"
          >
            <label for="form-class-name">
              <span class="control-label"> {{ $t("teachers.class_name") }} </span>
              <span
                v-if="!$v.name.required"
                class="form-error"
              >
                {{ $t("form_validation_errors.required") }}
              </span>
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
    </div>
  </div>
</template>