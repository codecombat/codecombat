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
    newClass: {
      name: {
        required: requiredIf(function () { return !this.isGoogleClassroomForm && !this.isOtherProductForm && !this.isLmsProductForm }),
      },
    },
  },
  data () {
    return {
      showGoogleClassroom: me.useGoogleClassroom(),
      newClass: {
        name: this.classroom?.name || this.value?.name || '',
        initCourse: this.classroom?.initialFreeCourses?.[0] || this.value?.initCourse || (utils.isCodeCombat ? utils.courseIDs.INTRODUCTION_TO_COMPUTER_SCIENCE : undefined),
        googleClassroomId: this.classroom?.googleClassroomId,
        otherProductId: this.classroom?.otherProductId,
        lmsClassroomId: this.classroom?.lmsClassroom?.classId,
      },
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
    lmsKey () {
      if (me.isSchoology()) {
        return 'schoology'
      } else if (me.isClassLink()) {
        return 'classlink'
      }
      return null
    },
    getProvider () {
      return this.lmsKey
    },
    lmsClassroom () {
      return this.lmsClassrooms?.find((c) => c.id === this.lmsClassroomId)
    },
  },
  watch: {
    newClass: {
      deep: true,
      handler (newV) {
        this.$emit('input', newV)
      },
    },
  },
  methods: {
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
    validate () {
      this.$v.$touch()
      return !this.$v.$invalid
    },
    updateGoogleClassroomId (newVal) {
      this.newClass.googleClassroomId = newVal
      this.newClass.name = this.googleClassrooms.find((c) => c.id === newVal).name
    },
    updateOtherProductClassroomId (newVal) {
      this.newClass.otherProductClassroomId = newVal
      this.newClass.name = (this.otherProductClassrooms || [])
        .find((classroom) => classroom._id === newVal)
    },
    updateLmsClassroomId (newVal) {
      this.newClass.lmsClassroomId = newVal
      this.newClass.name = (this.lmsClassrooms || []).find((c) => c.id === newVal)
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
          v-if="classroomInstance.isNew()"
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
            :class="{ 'has-error': $v.newClass.name.$error }"
          >
            <label for="form-class-name">
              <span class="control-label"> {{ $t("teachers.class_name") }} </span>
              <span
                v-if="!$v.newClass.name.required"
                class="form-error"
              >
                {{ $t("form_validation_errors.required") }}
              </span>
            </label>
            <input
              id="form-class-name"
              v-model="$v.newClass.name.$model"
              type="text"
              class="form-control"
            >
          </div>
        </div>
      </template>
      <div
        class="form-group row"
      >
        <CourseSelect v-model="newClass.initCourse" />
      </div>
    </div>
  </div>
</template>