<script>
import { mapActions, mapGetters } from 'vuex'
import Modal from '../../common/Modal'
import SecondaryButton from '../common/buttons/SecondaryButton'
import TertiaryButton from '../common/buttons/TertiaryButton'
import Classroom from 'models/Classroom'
import utils from 'core/utils'
import _ from 'lodash'
import { validationMixin } from 'vuelidate'
import { required, requiredIf } from 'vuelidate/lib/validators'
import GoogleClassroomHandler from 'core/social-handlers/GoogleClassroomHandler'
import ButtonGoogleClassroom from 'ozaria/site/components/teacher-dashboard/modals/common/ButtonGoogleClassroom.vue'
import ButtonImportClassroom from 'ozaria/site/components/teacher-dashboard/modals/common/ButtonImportClassroom.vue'
import ClassroomsApi from 'app/core/api/classrooms.js'
import moment from 'moment'
import { COMPONENT_NAMES } from 'ozaria/site/components/teacher-dashboard/common/constants.js'
import ClassStartEndDateComponent from './modal-edit-class-components/ClassStartEndDateComponent.vue'
import CourseCodeLanguageFormatComponent from './modal-edit-class-components/CourseCodeLanguageFormatComponent.vue'

export default Vue.extend({
  components: {
    Modal,
    SecondaryButton,
    TertiaryButton,
    ButtonGoogleClassroom,
    ButtonImportClassroom,
    ClassStartEndDateComponent,
    CourseCodeLanguageFormatComponent,
  },

  mixins: [validationMixin],

  props: {
    classroom: {
      type: Object,
      required: true,
      default: () => {},
    },
    asClub: {
      type: Boolean,
      default: false,
    },
  },

  data: function () {
    const cItems = this.classroom?.classroomItems
    const cLiveCompletion = this.classroom?.aceConfig?.liveCompletion
    const cFormats = this.classroom?.aceConfig?.codeFormats
    const cFormatDefault = this.classroom?.aceConfig?.codeFormatDefault
    const cLevelChat = this.classroom?.aceConfig?.levelChat
    const cGrades = this.classroom?.grades || []
    return {
      showGoogleClassroom: me.showGoogleClassroom(),
      newClassName: this.classroom?.name || '',
      newProgrammingLanguage: this.classroom?.aceConfig?.language || 'python',
      newLiveCompletion: typeof cLiveCompletion === 'undefined' ? true : cLiveCompletion,
      newClassroomItems: typeof cItems === 'undefined' ? true : cItems,
      cocoDefaultClassroomItems: true,
      newCodeFormats: typeof cFormats === 'undefined' ? ['text-code'] : cFormats,
      newCodeFormatDefault: typeof cFormatDefault === 'undefined' ? 'text-code' : cFormatDefault,
      newLevelChat: typeof cLevelChat === 'undefined' ? true : cLevelChat === 'fixed_prompt_only',
      newRemix: this.classroom?.hackstackConfig?.remixAllowed || false,
      cocoDefaultLevelChat: true,
      newClassroomDescription: this.classroom?.description || '',
      newAverageStudentExp: this.classroom?.averageStudentExp || '',
      newClassroomType: this.classroom?.type || '',
      newClassDateStart: this.classroom?.classDateStart || '',
      newClassDateEnd: this.classroom?.classDateEnd || '',
      newClassesPerWeek: this.classroom?.classesPerWeek || '',
      newMinutesPerClass: this.classroom?.minutesPerClass || '',
      newClubType: this.classroom?.type || '',
      saving: false,
      classGrades: (utils.isOzaria && !me.isCodeNinja()) ? cGrades : null,
      googleClassId: '',
      otherProductClassroomId: '',
      googleClassrooms: null,
      otherProductClassrooms: null,
      isGoogleClassroomForm: false,
      isOtherProductForm: false,
      otherProductSyncInProgress: false,
      googleSyncInProgress: false,
      moreOptions: false,
      newInitialFreeCourses: utils.isCodeCombat ? [utils.courseIDs.INTRODUCTION_TO_COMPUTER_SCIENCE] : [],
      archived: this.classroom?.archived || false,
      errMsg: '',
    }
  },

  validations: {
    newClassName: {
      required: requiredIf(function () { return !this.isGoogleClassroomForm && !this.isOtherProductForm }),
    },
    googleClassId: {
      required: requiredIf(function () { return this.isGoogleClassroomForm }),
    },
    otherProductClassroomId: {
      required: requiredIf(function () { return this.isOtherProductForm }),
    },
    newProgrammingLanguage: {
      required,
    },
    newClassDateStart: {
      required: requiredIf(function () { return this.asClub }),
    },
    newClassDateEnd: {
      required: requiredIf(function () { return this.asClub }),
    },
    newClubType: {
      required: requiredIf(function () { return this.asClub }),
    },
  },
  computed: {
    ...mapGetters({
      getSessionsMapForClassroom: 'levelSessions/getSessionsMapForClassroom',
      courses: 'courses/sorted',
      getCourseInstances: 'courseInstances/getCourseInstancesOfClass',
      activeClassrooms: 'teacherDashboard/getActiveClassrooms',
      allClassrooms: 'teacherDashboard/getAllClassrooms',
    }),
    title () {
      let title = ''
      if (this.classroomInstance.isNew()) {
        title += $.i18n.t('courses.create_new_class')
      } else {
        title += $.i18n.t('courses.edit_settings1')
      }
      if (this.asClub) {
        title += ' (As Club / Camp)'
      }
      return title
    },
    moreOptionsText () {
      const i18n = this.moreOptions ? 'hide_options' : 'more_options'
      return this.$t(`courses.${i18n}`)
    },
    moreOptionsIcon () {
      return this.moreOptions ? '&nbsp;&and;' : '&nbsp;&or;'
    },
    googleClassroomDisabled () {
      return !me.googleClassroomEnabled()
    },
    isFormValid () {
      return !this.$v.$invalid
    },
    me () {
      return me
    },
    range () {
      return _.range
    },
    isCodeCombat () {
      return utils.isCodeCombat
    },
    isOzaria () {
      return utils.isOzaria
    },
    i18n () {
      return utils.i18n
    },
    capitalLanguages () {
      return utils.capitalLanguages
    },
    classroomInstance () {
      return new Classroom(this.classroom)
    },
    otherProductClassroom () {
      return (this.otherProductClassrooms || [])
        .find((classroom) => classroom._id === this.otherProductClassroomId)
    },

    clubTypes () {
      if (utils.isOzaria) {
        return Classroom.codeNinjaClassroomTypes().filter(type => type.id === 'club-ozaria' || type.disabled)
      }
      return Classroom.codeNinjaClassroomTypes()
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
  },

  watch: {
    availableCodeFormats () {
      const ava = this.availableCodeFormats.filter(cf => !cf.disabled).map(cf => cf.id)
      this.newCodeFormats = this.newCodeFormats.filter(cf => ava.includes(cf))
      if (!this.newCodeFormats.includes(this.newCodeFormatDefault)) {
        this.newCodeFormatDefault = this.newCodeFormats[0]
      }
    },
    otherProductClassroom (newOtherProductClassroom) {
      // update settings that are available on both coco and ozar
      const { language, levelChat, liveCompletion } = newOtherProductClassroom.aceConfig
      this.newProgrammingLanguage = utils.allowedLanguages.includes(language) ? language : 'python'
      this.newLevelChat = levelChat === 'fixed_prompt_only'
      this.newLiveCompletion = liveCompletion
    },
  },

  async mounted () {
    if (this.classroomInstance?._id || this.classroomInstance?.id) {
      await this.fetchCourseInstances(this.classroomInstance?._id || this.classroomInstance?.id)
    }
    await this.fetchCourses()
  },

  methods: {
    ...mapActions({
      updateClassroom: 'classrooms/updateClassroom',
      createClassroom: 'classrooms/createClassroom',
      addMembersToClassroom: 'classrooms/addMembersToClassroom',
      fetchClassroomSessions: 'levelSessions/fetchForClassroomMembers',
      createFreeCourseInstances: 'courseInstances/createFreeCourseInstances',
      fetchCourses: 'courses/fetchReleased',
      fetchCourseInstances: 'courseInstances/fetchCourseInstancesForClassroom',
    }),
    updateGrades (event) {
      const grade = event.target.name
      if (this.classGrades.includes(grade)) {
        this.classGrades.splice(this.classGrades.indexOf(grade), 1)
      } else {
        this.classGrades.push(grade)
      }
    },
    archiveClass () {
      this.updateClassroom({ classroom: this.classroom, updates: { archived: true } })
      this.classroomInstance.revokeStudentLicenses()
      this.$emit('close')
    },
    unarchiveClass () {
      this.updateClassroom({ classroom: this.classroom, updates: { archived: false } })
      if (!this.getSessionsMapForClassroom(this.classroom._id)) {
        this.fetchClassroomSessions({ classroom: this.classroom })
      }
      this.$emit('close')
    },
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
    toggleMoreOptions () {
      this.moreOptions = !this.moreOptions
    },
    enableBlocks () {
      return ['python', 'javascript', 'lua'].includes(this.newProgrammingLanguage || 'python')
    },
    async saveClass () {
      this.saving = true
      this.errMsg = ''
      if (!this.isFormValid) {
        this.$v.$touch() // $touch updates the validation state of all fields and scroll to the wrong input
        this.errMsg = 'Please fill out all required fields'
        this.saving = false
        return
      }
      const updates = {}

      if (this.asClub) {
        let errorMsg
        if (this.newClubType === 'club-ozaria' && this.isCodeCombat) {
          errorMsg = 'Error creating ozaria club in CodeCombat'
        } else if (moment(this.newClassDateEnd).isBefore(moment(this.newClassDateStart))) {
          errorMsg = 'End date should be after start date'
        } else if (this.newClubType.includes('camp') && moment(this.newClassDateEnd).diff(moment(this.newClassDateStart), 'days') > 7) {
          errorMsg = 'Camp should be at most 7 days'
        } else if (this.newClubType.includes('club') && moment(this.newClassDateEnd).diff(moment(this.newClassDateStart), 'weeks') > 14) {
          errorMsg = 'Club should be at most 14 weeks'
        }

        if (errorMsg) {
          this.errMsg = errorMsg
          this.saving = false
          return
        }
        updates.type = this.newClubType
      } else {
        updates.type = this.newClassroomType
      }

      if (this.newClassDateStart && this.newClassDateEnd && moment(this.newClassDateEnd).isBefore(moment(this.newClassDateStart))) {
        this.errMsg = 'End date should be after start date'
        this.saving = false
        return
      }

      updates.name = this.newClassName
      const aceConfig = _.clone((this.classroom || {}).aceConfig || {})
      const hackstackConfig = _.clone((this.classroom || {}).hackstackConfig || {})
      aceConfig.language = this.newProgrammingLanguage
      aceConfig.liveCompletion = this.newLiveCompletion
      updates.classroomItems = this.newClassroomItems

      // Make sure that codeFormats includes codeFormatDefault, including when these aren't specified
      if (!this.newCodeFormats.includes(this.newCodeFormatDefault)) {
        this.newCodeFormats.push(this.newCodeFormatDefault)
      }
      aceConfig.codeFormats = this.newCodeFormats
      aceConfig.codeFormatDefault = this.newCodeFormatDefault

      if (this.newLevelChat) {
        aceConfig.levelChat = 'fixed_prompt_only'
      } else {
        aceConfig.levelChat = 'none'
      }

      if (this.newRemix) {
        hackstackConfig.remixAllowed = true
      } else {
        hackstackConfig.remixAllowed = false
      }

      updates.aceConfig = aceConfig
      updates.hackstackConfig = hackstackConfig

      updates.description = this.newClassroomDescription
      updates.averageStudentExp = this.newAverageStudentExp
      updates.classDateStart = this.newClassDateStart
      updates.classDateEnd = this.newClassDateEnd
      updates.classesPerWeek = String(this.newClassesPerWeek)
      updates.minutesPerClass = String(this.newMinutesPerClass)

      if (this.isGoogleClassroomForm) {
        updates.googleClassroomId = this.googleClassId
        updates.name = this.googleClassrooms.find((c) => c.id === this.googleClassId).name
      }

      if (this.isOtherProductForm) {
        updates.name = this.otherProductClassroom.name
        updates.members = this.otherProductClassroom.members
        updates.otherProductId = this.otherProductClassroom._id
      }

      if (this.classGrades?.length > 0) {
        updates.grades = this.classGrades
      }

      if (utils.isCodeCombat) {
        if (this.newInitialFreeCourses?.length === 0 && this.classroomInstance.isNew()) {
          this.errMsg = 'Please select at least one course'
          this.saving = false
          return
        }
        updates.initialFreeCourses = this.newInitialFreeCourses
      }

      let savedClassroom
      if (this.classroomInstance.isNew()) {
        try {
          savedClassroom = await this.createClassroom({ ...this.classroom.attributes, ...updates })
        } catch (err) {
          console.error('failed to create classroom', err)
          this.errMsg = err?.message || 'Failed to create classroom'
          this.saving = false
          return
        }
        await this.createFreeCourseInstances({ classroom: savedClassroom, courses: this.courses })

        this.$emit('created')
      } else {
        try {
          savedClassroom = await this.updateClassroom({ classroom: this.classroom, updates })
        } catch (err) {
          console.error('failed to update classroom', err)
          this.errMsg = err?.message || 'Failed to update classroom'
          this.saving = false
          return
        }
        this.$emit('updated')
      }

      if (this.isGoogleClassroomForm) {
        await GoogleClassroomHandler.markAsImported(this.googleClassId)
        GoogleClassroomHandler.importStudentsToClassroom(savedClassroom)
          .then((importedMembers) => {
            if (importedMembers.length > 0) {
              console.debug('Students imported to classroom:', importedMembers)
            }
          })
          .catch((e) => {
            this.errMsg = e?.message || 'Error in importing students'
            noty({ text: 'Error in importing students', layout: 'topCenter', type: 'error', timeout: 2000 })
          })
      }

      if (this.isOtherProductForm) {
        const members = updates.members
          .map(memberId => ({
            _id: memberId,
            role: 'student',
          }))

        // set linkink in both classrooms
        ClassroomsApi.update({
          classroomID: this.otherProductClassroom._id,
          updates: { otherProductId: savedClassroom._id },
        }, { callOz: true }).catch(console.log)
        if (members.length > 0) {
          await this.addMembersToClassroom({ classroom: savedClassroom, members, componentName: COMPONENT_NAMES.MY_CLASSES_ALL })
        }
      }

      this.$emit('close')
      this.saving = false
      // redirect to classes if user was not on classes page when creating a new class
      if (this.classroomInstance.isNew()) {
        const path = window.location.pathname
        if (path !== '/teachers' && !path.match('/teachers/classes')) {
          window.location.href = '/teachers/classes'
        }
      }
    },
    updateClassDateStart (newVal) {
      this.newClassDateStart = newVal
    },
    updateClassDateEnd (newVal) {
      this.newClassDateEnd = newVal
    },
    updateProgrammingLanguage (newVal) {
      this.newProgrammingLanguage = newVal
    },
    updateInitialFreeCourses (newVal) {
      this.newInitialFreeCourses = newVal
    },
    updateCodeFormats (newVal) {
      this.newCodeFormats = newVal
    },
    updateCodeFormatDefault (newVal) {
      this.newCodeFormatDefault = newVal
    },
  },
})
</script>

<template>
  <modal
    :title="title"
    @close="$emit('close')"
  >
    <div
      class="style-ozaria teacher-form edit-class container"
      :class="{ 'edit-class-coco': isCodeCombat }"
    >
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
      </div>
      <div class="form-container container">
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
        <div
          v-else
          class="form-group row class-name"
          :class="{ 'has-error': $v.newClassName.$error }"
        >
          <div class="col-xs-12">
            <label for="form-class-name">
              <span class="control-label"> {{ $t("teachers.class_name") }} </span>
              <span
                v-if="!$v.newClassName.required"
                class="form-error"
              >
                {{ $t("form_validation_errors.required") }}
              </span>
            </label>
            <input
              id="form-class-name"
              v-model="$v.newClassName.$model"
              type="text"
              class="form-control"
            >
          </div>
        </div>
        <div
          v-if="asClub"
          class="form-group row class-club-type"
        >
          <div
            class="col-xs-12"
            :class="{ 'has-error': $v.newClubType.$error }"
          >
            <label for="club-type-select">
              <span class="control-label"> {{ $t("teachers.club_type") }} </span>
            </label>
            <select
              id="club-type-select"
              v-model="newClubType"
              class="form-control"
              name="clubType"
              :disabled="!classroomInstance.isNew()"
            >
              <option
                v-for="clubType in clubTypes"
                :key="clubType.id"
                :value="clubType.id"
                :disabled="clubType.disabled"
              >
                {{ clubType.name }}
              </option>
            </select>
            <span
              v-if="isCodeCombat && newClubType === 'club-ozaria'"
              class="error"
            >
              Please login on <a
                href="https://www.ozaria.com/teachers/classes"
                target="_blank"
              >ozaria.com</a> instead with same credentials to create ozaria club and continue playing
            </span>
          </div>
        </div>
        <class-start-end-date-component
          v-if="asClub"
          :class-date-start="newClassDateStart"
          :class-date-end="newClassDateEnd"
          @classDateStartUpdated="updateClassDateStart"
          @classDateEndUpdated="updateClassDateEnd"
        />
        <course-code-language-format-component
          :is-code-combat="isCodeCombat"
          :is-new-classroom="classroomInstance.isNew()"
          :as-club="asClub"
          :new-club-type="newClubType"
          :classroom-id="classroomInstance.get('_id')"
          :courses="courses"
          :code-formats="newCodeFormats"
          :code-format-default="newCodeFormatDefault"
          :code-language="newProgrammingLanguage"
          @programmingLanguageUpdated="updateProgrammingLanguage"
          @initialFreeCoursesUpdated="updateInitialFreeCourses"
          @codeFormatsUpdated="updateCodeFormats"
          @codeFormatDefaultUpdated="updateCodeFormatDefault"
        />
        <div
          v-if="isOzaria && !me.isCodeNinja()"
          class="form-group row class-grades"
        >
          <div class="col-xs-12">
            <span class="control-label"> {{ $t("teachers.grades") }} </span>
            <span class="control-label-desc"> {{ $t("teachers.select_all_that_apply") }} </span>
            <div class="btn-group class-grades-input">
              <button
                type="button"
                class="btn elementary"
                name="elementary"
                :class="{ selected: classGrades.includes('elementary')}"
                @click="updateGrades"
              >
                {{ $t('teachers.elementary') }}
              </button>
              <button
                type="button"
                class="btn middle"
                name="middle"
                :class="{ selected: classGrades.includes('middle')}"
                @click="updateGrades"
              >
                {{ $t('teachers.middle') }}
              </button>
              <button
                type="button"
                class="btn high"
                name="high"
                :class="{ selected: classGrades.includes('high')}"
                @click="updateGrades"
              >
                {{ $t('teachers.high_school') }}
              </button>
            </div>
          </div>
        </div>
        <div
          v-if="moreOptions && isCodeCombat"
          class="form-group row classroom-items"
        >
          <div class="col-xs-12">
            <label for="classroom-items">
              <span class="control-label">{{ $t('courses.classroom_items') }}:</span>
            </label>
            <input
              id="classroom-items"
              v-model="newClassroomItems"
              name="classroomItems"
              type="checkbox"
            >
            <div class="help-block small text-navy">
              {{ $t('teachers.classroom_items_description') }}
            </div>
          </div>
        </div>
        <div
          v-if="moreOptions"
          class="form-group row autoComplete"
        >
          <div class="col-xs-12">
            <label for="liveCompletion">
              <span class="control-label"> {{ $t('courses.classroom_live_completion') }}</span>
            </label>
            <input
              id="liveCompletion"
              v-model="newLiveCompletion"
              type="checkbox"
            >
            <span class="help-block small text-navy">{{ $t("teachers.classroom_live_completion") }}</span>
          </div>
        </div>
        <div
          v-if="moreOptions && isCodeCombat"
          class="form-group row remix"
        >
          <div class="col-xs-12">
            <label for="level-chat">
              <span class="control-label"> {{ $t("teachers.ai_hs_remix") }} </span>
            </label>
            <input
              id="level-chat"
              v-model="newRemix"
              type="checkbox"
              name="remix"
            >
            <span class="help-block small text-navy">{{ $t("teachers.ai_hs_remix_blurb") }}</span>
          </div>
        </div>
        <div
          v-if="moreOptions"
          class="form-group row level-chat"
        >
          <div class="col-xs-12">
            <label for="level-chat">
              <span class="control-label"> {{ $t("teachers.classroom_level_chat") }} </span>
            </label>
            <input
              id="level-chat"
              v-model="newLevelChat"
              type="checkbox"
              name="levelChat"
            >
            <span class="help-block small text-navy">{{ $t("teachers.classroom_level_chat_blurb") }}</span>
          </div>
        </div>
        <div
          v-if="moreOptions && isCodeCombat"
          class="form-group row announcement"
        >
          <div class="col-md-12">
            <label>
              <span class="control-label"> {{ $t("courses.classroom_announcement") }} </span>
              <i class="spl text-muted">{{ $t("signup.optional") }}</i>
              <button class="pick-image-button btn btn-middle btn-forest">{{ $t("common.pick_image") }}</button>
            </label>
            <textarea
              id="classroom-announcement"
              v-model="newClassroomDescription"
              name="description"
              rows="2"
              class="form-control"
            />
          </div>
        </div>
        <div
          v-if="moreOptions && isCodeCombat"
          class="form-group row hide"
        >
          <div class="col-md-12">
            <label>
              <span class="control-label"> {{ $t("courses.avg_student_exp_label") }} </span>
              <i class="spl text-muted">{{ $t("signup.optional") }}</i>
            </label>
            <select
              id="average-student-exp"
              v-model="newAverageStudentExp"
              name="averageStudentExp"
              class="form-control"
            >
              <option value="">
                {{ $t('courses.avg_student_exp_select') }}
              </option>
              <option value="none">
                {{ $t('courses.avg_student_exp_none') }}
              </option>
              <option value="beginner">
                {{ $t('courses.avg_student_exp_beginner') }}
              </option>
              <option value="intermediate">
                {{ $t('courses.avg_student_exp_intermediate') }}
              </option>
              <option value="advanced">
                {{ $t('courses.avg_student_exp_advanced') }}
              </option>
              <option value="varied">
                {{ $t('courses.avg_student_exp_varied') }}
              </option>
            </select>
          </div>
        </div>
        <div
          v-if="!asClub && (moreOptions && isCodeCombat || me.isCodeNinja())"
          class="form-group row"
        >
          <div class="col-md-12">
            <label for="type">
              <span class="control-label"> {{ $t("courses.class_type_label") }} </span>
              <i
                v-if="!me.isILK()"
                class="spl text-muted"
              >{{ $t("signup.optional") }}</i>
            </label>
            <select
              id="type"
              v-model="newClassroomType"
              name="type"
              class="form-control"
            >
              <option value="">
                {{ $t('courses.avg_student_exp_select') }}
              </option>
              <option
                v-if="!me.isCodeNinja()"
                value="in-school"
              >
                {{ $t('courses.class_type_in_school') }}
              </option>
              <option value="after-school">
                {{ $t('courses.class_type_after_school') }}
              </option>
              <option
                v-if="!me.isCodeNinja()"
                value="online"
              >
                {{ $t('courses.class_type_online') }}
              </option>
              <option
                v-if="!me.isCodeNinja()"
                value="camp"
              >
                {{ $t('courses.class_type_camp') }}
              </option>
              <option
                v-if="!me.isCodeNinja()"
                value="homeschool"
              >
                {{ $t('courses.class_type_homeschool') }}
              </option>
              <option
                v-if="!me.isCodeNinja()"
                value="other"
              >
                {{ $t('courses.class_type_other') }}
              </option>
            </select>
          </div>
        </div>
        <class-start-end-date-component
          v-if="!asClub && (moreOptions && isCodeCombat || me.isCodeNinja())"
          :class-date-start="newClassDateStart"
          :class-date-end="newClassDateEnd"
          @classDateStartUpdated="updateClassDateStart"
          @classDateEndUpdated="updateClassDateEnd"
        />
        <div
          v-if="moreOptions && isCodeCombat && !me.isCodeNinja()"
          class="form-group row"
        >
          <div class="col-sm-12">
            <label for="form-new-classes-per-week">
              <span class="control-label"> {{ $t("courses.estimated_class_frequency_label") }} </span>
            </label>
          </div>
          <div class="col-sm-12 new-classes-per-week-container">
            <div>
              <select
                id="form-new-classes-per-week"
                v-model="newClassesPerWeek"
                class="form-control"
              >
                <option
                  v-for="i in range(1,6)"
                  :key="i"
                  :value="i"
                >
                  {{ i }}
                </option>
              </select>
              <span class="help-block small text-navy m-l-1">{{ $t("courses.classes_per_week") }}</span>
            </div>
            <div>
              <select
                v-model="newMinutesPerClass"
                class="form-control"
              >
                <option value="<30">
                  &lt;30
                </option>
                <option value="30">
                  30
                </option>
                <option value="50">
                  50
                </option>
                <option value="75">
                  75
                </option>
                <option value=">75">
                  &gt;75
                </option>
              </select>
              <span class="help-block small text-navy m-l-1">{{ $t("courses.minutes_per_class") }}</span>
            </div>
          </div>
        </div>
        <div
          class="more-options-text-container"
        >
          <!-- eslint-disable vue/no-v-html -->
          <a
            class="more-options-text"
            @click="toggleMoreOptions"
          >
            {{ moreOptionsText }}
            <span v-html="moreOptionsIcon" />
          </a>
          <!--eslint-enable-->
        </div>
        <div class="form-group row">
          <div class="col-xs-12 buttons">
            <tertiary-button
              v-if="archived"
              class="class-unarchive"
              @click="unarchiveClass"
            >
              <img src="/images/ozaria/teachers/dashboard/svg_icons/IconUnarchive.svg">
              {{ $t("teacher.unarchive_class") }}
            </tertiary-button>
            <tertiary-button
              v-if="!classroomInstance.isNew() && !archived"
              class="class-archive"
              @click="archiveClass"
            >
              <img src="/images/ozaria/teachers/dashboard/svg_icons/IconArchive.svg">
              {{ $t("teacher.archive_class") }}
            </tertiary-button>
            <div
              class="submit-button"
            >
              <secondary-button
                :disabled="saving"
                class="class-submit"
                @click="saveClass"
              >
                {{ classroomInstance.isNew() ? $t("courses.create_class") : $t("common.save_changes") }}
              </secondary-button>
              <span
                v-if="saving"
                class="saving-text"
              >
                {{ $t('common.saving') }}
              </span>
              <span
                v-if="errMsg"
                class="error-msg error"
              >
                {{ errMsg }}
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </modal>
</template>

<style lang="scss" scoped>
@import "app/styles/ozaria/_ozaria-style-params.scss";

.link-buttons-container {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 20px;
  margin-bottom: 15px;
}

.edit-class {
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  margin: 5px 5px 0px 5px;
  width: 600px;
}
.edit-class-coco {
  width: 650px;
}

.form-container {
  width: 100%;
  min-width: 600px;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;

  &.container {
    max-width: 100%;
    .row {
      width: 100%;
    }
  }

  .form-group .control-label-desc {
    display: inline-block;
    text-align: justify;
    line-height: 19px;
    margin-top: 3px;
  }
}

.class-name, .language, .autoComplete {
  width: 100%;
}

.language input {
  text-transform: capitalize;
}

.buttons {
  display: flex;
  justify-content: flex-end;
  margin-top: 15px;

  button {
    width: 180px;
    height: 35px;
    margin: 0 10px;
    text-transform: capitalize;
    display: flex;
    align-items: center;
    justify-content: space-evenly;
  }
}

.new-classes-per-week-container {
  display: flex;
  flex-direction: row;
  justify-content: space-between;
  align-items: center;
  width: 100%;

  > div {
    width: 45%;
  }
}

.class-grades-input {
  display: block;

  .elementary {
    border-radius: 0px;
    border: 2px solid #D4B235;
    color: #D4B235;
    &.selected, &:hover {
      background: #D4B235;
      color: #131B25;
    }
  }
  .middle {
    border-radius: 0px;
    border: 2px solid #74C6DF;
    color: #74C6DF;
    &.selected, &:hover {
      background: #74C6DF;
      color: #131B25;
    }
  }
  .high {
    border-radius: 0px;
    border: 2px solid #FF8600;
    color: #FF8600;
    &.selected, &:hover {
      background: #FF8600;
      color: #131B25;
    }
  }
}

.form-group {
  &.has-error {
    .form-error {
      @include font-p-4-paragraph-smallest-gray;
      display: inline-block;
      color: $color-concept-flag-color !important;
    }
    .form-control {
      color: $color-concept-flag-color !important;
    }
  }
}

.has-error {
  .form-control {
    border-color: #a94442 !important;
    -webkit-box-shadow: inset 0 1px 1px rgba(0, 0, 0, 0.075);
    box-shadow: inset 0 1px 1px rgba(0, 0, 0, 0.075);
  }
  .control-label {
    color: #a94442 !important;
  }
}

.form-error {
  display: none;
}

.ozaria-primary-button {
  color: #000000;
}

.form-checkbox-input {
  @include font-p-4-paragraph-smallest-gray;
  input {
    width: 6%;
  }
}

.ml-small {
  margin-left: 5px;
}

.more-options-text-container {
  margin-bottom: -5px;
  margin-top: -5px;
}

.more-options-text {
  font-size: 15px;

  span {
    font-size: 18px;
    line-height: 15px;
  }
}
p.help-block {
  margin-bottom: 0;
}
.error {
  color: red;
  font-size: 14px;
  line-height: 16px;
}
.submit-button {
  display: flex;
  align-items: center;
  justify-content: center;
  flex-direction: column;

  .saving-text {
    @include font-p-4-paragraph-smallest-gray;
    margin-top: 5px;
  }

  .error-msg {
    margin-top: 5px;
  }
}
</style>
