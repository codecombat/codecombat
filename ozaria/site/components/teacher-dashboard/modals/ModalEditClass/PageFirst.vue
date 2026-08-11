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

export default Vue.extend({
  components: {
    ButtonGoogleClassroom,
    ButtonImportClassroom,
    CourseSelect,
  },
  mixins: [validationMixin],
  props: {
    classroom: {
      type: Object,
      required: true,
    },
    asClub: {
      type: Boolean,
      default: false,
    },
    value: {
      type: Object,
      required: true,
    },
  },
  validations: {
    newClass: {
      name: {
        required: requiredIf(function () { return !this.isGoogleClassroomForm && !this.isOtherProductForm && !this.lmsProductForm }),
      },
    },
  },
  data () {
    return {
      showGoogleClassroom: me.useGoogleClassroom(),
      newClass: {
        name: this.classroom?.name || this.value?.name || '',
        initCourse: this.classroom?.initialFreeCourses?.[0] || this.value?.initCourse || (utils.isCodeCombat ? utils.courseIDs.INTRODUCTION_TO_COMPUTER_SCIENCE : undefined),
      },
      googleSyncInProgress: false,
      otherProductSyncInProgress: false,
      lmsSyncInProgress: false,
      lmsProductForm: false,
      isGoogleClassroomForm: false,
      isOtherProductForm: false,
    }
  },
  computed: {
    isCodeCombat () {
      return utils.isCodeCombat
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
      this.googleSyncInProgress = true
      await new Promise((resolve, reject) =>
        application.gplusHandler.loadAPI({
          success: resolve,
          error: reject,
        }))
      GoogleClassroomHandler.importClassrooms()
        .then(() => {
          this.googleClassrooms = me.get('googleClassrooms').filter((c) => !c.importedToOzaria && !c.deletedFromGC)
          this.isGoogleClassroomForm = true
          window.tracker?.trackEvent('Add New Class: Link Google Classroom Successful', { category: 'Teachers' })
        })
        .catch((e) => {
          noty({ text: $.i18n.t('teachers.error_in_importing_classrooms'), layout: 'topCenter', type: 'error', timeout: 2000 })
        })
      this.googleSyncInProgress = false
    },
    async linkOtherProductClassroom () {
      window.tracker?.trackEvent('Add New Class: Link Other Product Classroom Clicked', { category: 'Teachers' })
      this.otherProductSyncInProgress = true

      try {
        this.otherProductClassrooms = (await ClassroomsApi.fetchByOwner(me.get('_id'), { callOz: true }))
          .filter(otherClassroom => !otherClassroom.otherProductId)
        this.isOtherProductForm = true
        window.tracker?.trackEvent('Add New Class: Link Other Product Classroom Successful', { category: 'Teachers' })
      } catch (error) {
        console.log(error)
        noty({ text: $.i18n.t('teachers.error_in_importing_classrooms'), layout: 'topCenter', type: 'error', timeout: 2000 })
      }
      this.otherProductSyncInProgress = false
    },

    async linkLmsClassroom () {
      this.lmsSyncInProgress = true
      try {
        this.lmsClassrooms = await OAuth2Api.getLmsClassrooms(this.getProvider)
        this.lmsProductForm = true
      } catch (error) {
        console.log(error)
        noty({ text: $.i18n.t('teachers.error_in_importing_classrooms'), layout: 'topCenter', type: 'error', timeout: 2000 })
      }
    },
    validate () {
      this.$v.$touch()
      return !this.$v.$invalid
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
          :in-progress="googleSyncInProgress"
          text="Link Google Classroom"
          @click="linkGoogleClassroom"
        />
      </div>
      <div
        v-if="linkOtherProductButtonAllowed"
        class="google-classroom-div"
      >
        <button-import-classroom
          :in-progress="otherProductSyncInProgress"
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
          :in-progress="lmsSyncInProgress"
          :icon-src="lmsProductImage"
          :icon-src-alt-text="lmsProductText"
          :icon-src-inactive="lmsProductImage"
          :text="$t('teachers.import_classroom')"
          @click="linkLmsClassroom"
        />
        <button-import-classroom
          v-else
          :in-progress="lmsSyncInProgress"
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
        v-if="isOtherProductForm || isGoogleClassroomForm || lmsProductForm"
        :is-google-classroom-form="isGoogleClassroomForm"
        :is-other-product-form="isOtherProductForm"
        :lms-product-form="lmsProductForm"
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
        <div
          class="form-group row"
        >
          <CourseSelect v-model="newClass.initCourse" />
        </div>
      </template>
    </div>
  </div>
</template>