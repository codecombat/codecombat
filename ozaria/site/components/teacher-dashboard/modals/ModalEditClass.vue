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
import ModalDivider from 'ozaria/site/components/common/ModalDivider.vue'
import ClassroomsApi from 'app/core/api/classrooms.js'
import moment from 'moment'
import { COMPONENT_NAMES } from 'ozaria/site/components/teacher-dashboard/common/constants.js'

export default Vue.extend({
  components: {
    Modal,
    SecondaryButton,
    TertiaryButton,
    ButtonGoogleClassroom,
    ButtonImportClassroom,
    ModalDivider
  },

  mixins: [validationMixin],

  props: {
    classroom: {
      type: Object,
      required: true,
      default: () => {}
    },
    asClub: {
      type: Boolean,
      default: false
    }
  },

  data: () => {
    return {
      showGoogleClassroom: me.showGoogleClassroom(),
      newClassName: '',
      newProgrammingLanguage: 'python',
      newLiveCompletion: true,
      newClassroomItems: true,
      cocoDefaultClassroomItems: true,
      newCodeFormats: ['text-code'],
      newCodeFormatDefault: 'text-code',
      newLevelChat: false,
      cocoDefaultLevelChat: true,
      newClassroomDescription: '',
      newAverageStudentExp: '',
      newClassroomType: '',
      newClassDateStart: '',
      newClassDateEnd: '',
      newClassesPerWeek: '',
      newMinutesPerClass: '',
      saving: false,
      classGrades: (utils.isOzaria && !me.isCodeNinja()) ? [] : null,
      googleClassId: '',
      otherProductClassroomId: '',
      googleClassrooms: null,
      otherProductClassrooms: null,
      isGoogleClassroomForm: false,
      isOtherProductForm: false,
      otherProductSyncInProgress: false,
      googleSyncInProgress: false,
      moreOptions: false,
      newInitialFreeCourses: [utils.courseIDs.INTRODUCTION_TO_COMPUTER_SCIENCE],
      newClubType: '',
    }
  },

  validations: {
    newClassName: {
      required: requiredIf(function () { return !this.isGoogleClassroomForm && !this.isOtherProductForm })
    },
    googleClassId: {
      required: requiredIf(function () { return this.isGoogleClassroomForm })
    },
    otherProductClassroomId: {
      required: requiredIf(function () { return this.isOtherProductForm })
    },
    newProgrammingLanguage: {
      required
    },
    ...(utils.isOzaria && !me.isCodeNinja()
      ? {
        classGrades: {
          required
        }
      }
      : {}),
    newClubType: {
      required: requiredIf(function () { return this.asClub })
    },
    newClassDateStart: {
      required: requiredIf(function () { return this.asClub })
    },
    newClassDateEnd: {
      required: requiredIf(function () { return this.asClub })
    },
  },
  computed: {
    ...mapGetters({
      getSessionsMapForClassroom: 'levelSessions/getSessionsMapForClassroom',
      courses: 'courses/sorted',
      getCourseInstances: 'courseInstances/getCourseInstancesOfClass'
    }),
    title () {
      let title = ''
      if (this.classroomInstance.isNew()) {
        title += $.i18n.t('courses.create_new_class')
      } else {
        title += $.i18n.t('courses.edit_settings1')
      }
      if (this.asClub) {
        title += '(As Club)'
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
    classroomName () {
      return (this.classroom || {}).name
    },
    language () {
      return ((this.classroom || {}).aceConfig || {}).language
    },
    archived () {
      return (this.classroom || {}).archived
    },
    liveCompletion () {
      return _.assign({ liveCompletion: true }, (this.classroom || {}).aceConfig).liveCompletion
    },
    classroomItems () {
      return (this.classroom || {}).classroomItems
    },
    hasJunior () {
      if (this.classroomInstance.isNew()) {
        return this.newInitialFreeCourses.includes(utils.courseIDs.JUNIOR)
      } else {
        return this.getCourseInstances(this.classroomInstance._id)?.some(ci => ci.courseID === utils.courseIDs.JUNIOR)
      }
    },
    codeLanguageObject () {
      return utils.getCodeLanguages()
    },
    codeFormatObject () {
      return utils.getCodeFormats()
    },
    enableBlocks () {
      return ['python', 'javascript', 'lua'].includes(this.newProgrammingLanguage || 'python')
    },
    availableCodeFormats () {
      const codeFormats = JSON.parse(JSON.stringify(this.codeFormatObject))
      if (!this.hasJunior) {
        codeFormats['blocks-icons'].disabled = true
      }
      if (!this.enableBlocks) {
        codeFormats['blocks-and-code'].disabled = true
        codeFormats['blocks-text'].disabled = true
      }
      return Object.values(codeFormats)
    },
    availableLanguages () {
      const languages = JSON.parse(JSON.stringify(this.codeLanguageObject))
      // ozaria do not have these 2 langs
      delete languages.coffeescript
      delete languages.lua

      return Object.values(languages)
    },
    enabledCodeFormats () {
      return this.availableCodeFormats.filter(cf => !cf.disabled && this.newCodeFormats.includes(cf.id))
    },
    codeFormats () {
      // Later, we can turn everything on by default
      // const defaultCodeFormats = isJunior ? this.allCodeFormats : _.omit(this.allCodeFormats, 'blocks-icons')
      const defaultCodeFormats = ['text-code']
      return ((this.classroom || {}).aceConfig || {}).codeFormats || defaultCodeFormats
    },
    codeFormatDefault () {
      return ((this.classroom || {}).aceConfig || {}).codeFormatDefault || 'text-code'
    },
    levelChat () {
      return _.assign({ levelChat: 'none' }, (this.classroom || {}).aceConfig).levelChat
    },
    classroomDescription () {
      return (this.classroom || {}).description
    },
    averageStudentExp () {
      return (this.classroom || {}).averageStudentExp
    },
    classroomType () {
      return (this.classroom || {}).type
    },
    classDateStart () {
      return (this.classroom || {}).classDateStart
    },
    classDateEnd () {
      return (this.classroom || {}).classDateEnd
    },
    classesPerWeek () {
      return (this.classroom || {}).classesPerWeek
    },
    minutesPerClass () {
      return (this.classroom || {}).minutesPerClass
    },
    classroomInstance () {
      return new Classroom(this.classroom)
    },
    initialFreeCourses () {
      return [
        ...utils.freeCocoCourseIDs.map(id => {
          const course = this.courses.find(({ _id }) => _id === id)
          return {
            id,
            name: utils.i18n(course, 'name'),
            blurb: $.i18n.t(`teachers.free_course_blurb_${course.slug}`)
          }
        }),
      ]
    },
    otherProductClassroom () {
      return (this.otherProductClassrooms || [])
        .find((classroom) => classroom._id === this.otherProductClassroomId)
    },

    clubTypes () {
      return [
        { id: 'club-ozaria', name: 'Ozaria' },
        { id: 'club-esports', name: 'Esports' },
        { id: 'club-roblox', name: 'Roblox' },
        { id: 'club-hackstack', name: 'Hackstack' },
      ]
    },

    linkGoogleButtonAllowed () {
      return this.showGoogleClassroom && !this.isGoogleClassroomForm && !this.isOtherProductForm
    },

    linkOtherProductButtonAllowed () {
      return utils.isCodeCombat &&
        !this.classroom.otherProductId &&
        !this.isGoogleClassroomForm &&
        !this.isOtherProductForm
    }
  },

  watch: {
    newInitialFreeCourses (newInitialFreeCourses) {
      if (newInitialFreeCourses.length === 0) {
        this.$nextTick(() => {
          this.$set(this, 'newInitialFreeCourses', [utils.courseIDs.INTRODUCTION_TO_COMPUTER_SCIENCE])
        })
      }
    },
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
    }
  },

  async mounted () {
    this.newClassName = this.classroomName
    this.newLiveCompletion = this.liveCompletion
    this.newClassroomItems = this.classroomItems
    this.newCodeFormats = this.codeFormats
    this.newCodeFormatDefault = this.codeFormatDefault
    this.newLevelChat = this.levelChat === 'fixed_prompt_only'
    this.newClassroomDescription = this.classroomDescription
    this.newAverageStudentExp = this.averageStudentExp
    this.newClassroomType = this.classroomType
    this.newClassDateStart = this.classDateStart
    this.newClassDateEnd = this.classDateEnd
    this.newClassesPerWeek = this.classesPerWeek
    this.newMinutesPerClass = this.minutesPerClass
    this.classGrades = this.classroom.grades || []
    if (!this.classroomInstance.isNew()) {
      this.moreOptions = true
      await this.fetchCourseInstances(this.classroomInstance?._id || this.classroomInstance?.id)
    } else if (utils.isCodeCombat) {
      this.newClassroomItems = this.cocoDefaultClassroomItems
      this.newLevelChat = this.cocoDefaultLevelChat
    }
    if (this.language) {
      this.newProgrammingLanguage = this.language
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
      fetchCourseInstances: 'courseInstances/fetchCourseInstancesForClassroom'
    }),
    updateGrades (event) {
      const grade = event.target.name
      if (this.classGrades.includes(grade)) {
        this.classGrades.splice(this.classGrades.indexOf(grade), 1)
      } else {
        this.classGrades.push(grade)
      }
      this.$v.classGrades.$touch()
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
          error: reject
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
    async saveClass () {
      this.saving = true
      if (!this.isFormValid) {
        this.$v.$touch() // $touch updates the validation state of all fields and scroll to the wrong input
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
        }

        if (errorMsg) {
          noty({ text: errorMsg, layout: 'topCenter', type: 'error', timeout: 2000 })
          this.saving = false
          return
        }
        if (this.newClubType) {
          updates.type = this.newClubType
        }
      }
      if (this.newClassName && this.newClassName !== this.classroomName) {
        updates.name = this.newClassName
      }
      const aceConfig = _.clone((this.classroom || {}).aceConfig || {})
      if (this.newProgrammingLanguage && this.newProgrammingLanguage !== this.language) {
        aceConfig.language = this.newProgrammingLanguage
      }
      if (this.newLiveCompletion !== this.liveCompletion) {
        aceConfig.liveCompletion = this.newLiveCompletion
      }

      if (this.newClassroomItems !== this.classroomItems) {
        updates.classroomItems = this.newClassroomItems
      }

      if (!this.enableBlocks) {
        this.newCodeFormats = ['text-code']
        this.newCodeFormatDefault = 'text-code'
      }

      // Make sure that codeFormats includes codeFormatDefault, including when these aren't specified
      if (!this.newCodeFormats.includes(this.newCodeFormatDefault)) {
        this.newCodeFormats.push(this.newCodeFormatDefault)
      }
      if (this.newCodeFormats !== this.codeFormats) {
        aceConfig.codeFormats = this.newCodeFormats
        updates.aceConfig = aceConfig
      }
      if (this.newCodeFormatDefault !== this.codeFormatDefault) {
        aceConfig.codeFormatDefault = this.newCodeFormatDefault
        updates.aceConfig = aceConfig
      }

      if (this.newLevelChat) {
        aceConfig.levelChat = 'fixed_prompt_only'
      } else {
        aceConfig.levelChat = 'none'
      }
      updates.aceConfig = aceConfig

      if (this.newClassroomDescription !== this.classroomDescription) {
        updates.description = this.newClassroomDescription
      }
      if (this.newAverageStudentExp !== this.averageStudentExp) {
        updates.averageStudentExp = this.newAverageStudentExp
      }
      if (this.newClassroomType !== this.classroomType) {
        updates.type = this.newClassroomType
      }
      if (this.newClassDateStart !== this.classDateStart) {
        updates.classDateStart = this.newClassDateStart
      }
      if (this.newClassDateEnd !== this.classDateEnd) {
        updates.classDateEnd = this.newClassDateEnd
      }
      if (this.newClassesPerWeek !== this.classesPerWeek) {
        updates.classesPerWeek = String(this.newClassesPerWeek)
      }
      if (this.newMinutesPerClass !== this.minutesPerClass) {
        updates.minutesPerClass = String(this.newMinutesPerClass)
      }

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
        updates.initialFreeCourses = this.newInitialFreeCourses
      }

      if (_.size(updates)) {
        let savedClassroom
        if (this.classroomInstance.isNew()) {
          try {
            savedClassroom = await this.createClassroom({ ...this.classroom.attributes, ...updates })
          } catch (err) {
            console.error('failed to create classroom', err)
            noty({
              type: 'error',
              text: err?.message || 'Failed to create classroom',
              timeout: 5000
            })
            return
          }
          await this.createFreeCourseInstances({ classroom: savedClassroom, courses: this.courses })

          this.$emit('created')
        } else {
          await this.updateClassroom({ classroom: this.classroom, updates })
          savedClassroom = this.classroom
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
              noty({ text: 'Error in importing students', layout: 'topCenter', type: 'error', timeout: 2000 })
            })
        }

        if (this.isOtherProductForm) {
          const members = updates.members
            .map(memberId => ({
              _id: memberId,
              role: 'student'
            }))

          // set linkink in both classrooms
          ClassroomsApi.update({
            classroomID: this.otherProductClassroom._id,
            updates: { otherProductId: savedClassroom._id }
          }, { callOz: true }).catch(console.log)
          if (members.length > 0) {
            await this.addMembersToClassroom({ classroom: savedClassroom, members, componentName: COMPONENT_NAMES.MY_CLASSES_ALL })
          }
        }

        this.$emit('close')

        // redirect to classes if user was not on classes page when creating a new class
        if (this.classroomInstance.isNew()) {
          const path = window.location.pathname
          if (path !== '/teachers' && !path.match('/teachers/classes')) {
            window.location.href = '/teachers/classes'
          }
        }
      }
      this.saving = false
    }
  }
})
</script>

<template>
  <modal
    :title="title"
    @close="$emit('close')"
  >
    <div class="style-ozaria teacher-form edit-class container">
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
      <modal-divider v-if="linkGoogleButtonAllowed || linkOtherProductButtonAllowed" />
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
            </label>
            <input
              id="form-class-name"
              v-model="$v.newClassName.$model"
              type="text"
              class="form-control"
            >
            <span
              v-if="!$v.newClassName.required"
              class="form-error"
            >
              {{ $t("form_validation_errors.required") }}
            </span>
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
            <label for="default-code-format-select">
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
              >
                {{ clubType.name }}
              </option>
            </select>
            <span
              v-if="isCodeCombat && newClubType === 'club-ozaria'"
              class="error"
            >
              Please login on <a
                href="https://www.ozaria.com"
                target="_blank"
              >ozaria.com</a> instead with same credentials to create ozaria club and continue playing
            </span>
          </div>
        </div>
        <div
          v-if="asClub"
          class="form-group row"
        >
          <div class="col-xs-12">
            <label for="form-new-class-date-start">
              <span class="control-label"> {{ $t("courses.estimated_class_dates_label") }} </span>
            </label>
            <div
              class="estimated-date-fields"
              :class="{ 'has-error': $v.newClassDateStart.$error || $v.newClassDateEnd.$error }"
            >
              <input
                id="form-new-class-date-start"
                v-model="newClassDateStart"
                type="date"
                class="form-control"
              >
              <label for="form-new-class-date-end">
                <span class="spl.spr">{{ $t("courses.student_age_range_to") }}</span>
              </label>
              <input
                id="form-new-class-date-end"
                v-model="newClassDateEnd"
                type="date"
                class="form-control"
              >
            </div>
          </div>
        </div>
        <div
          v-if="isCodeCombat && classroomInstance.isNew() && !asClub"
          class="form-group row initial-free-courses"
        >
          <div class="col-xs-12">
            <label class="control-label">
              {{ $t("teachers.initial_free_courses") }}
            </label>
            <div
              v-for="initialFreeCourse in initialFreeCourses"
              :key="initialFreeCourse.id"
              class="form-group"
            >
              <label
                class="checkbox-inline"
              >
                <input
                  v-model="newInitialFreeCourses"
                  :value="initialFreeCourse.id"
                  type="checkbox"
                  name="initialFreeCourses"
                >
                <span class="initial-course-name">{{ initialFreeCourse.name }}</span>
                <p class="initial-course-blurb help-block small text-navy">{{ initialFreeCourse.blurb }}</p>
              </label>
            </div>
          </div>
        </div>
        <div
          class="form-group row language"
          :class="{ 'has-error': $v.newProgrammingLanguage.$error }"
        >
          <div class="col-xs-12">
            <label for="form-lang-item">
              <span class="control-label"> {{ $t("teachers.programming_language") }} </span>
            </label>
            <select
              id="form-lang-item"
              v-model="$v.newProgrammingLanguage.$model"
              class="form-control"
              :class="{ 'placeholder-text': !newProgrammingLanguage }"
              name="classLanguage"
            >
              <option
                v-for="enabledLanguage in availableLanguages"
                :key="enabledLanguage.id"
                :value="enabledLanguage.id"
                :disabled="enabledLanguage.disabled"
              >
                {{ enabledLanguage.name }}
              </option>
            </select>
            <span
              v-if="!$v.newProgrammingLanguage.required"
              class="form-error"
            >
              {{ $t("form_validation_errors.required") }}
            </span>
            <span class="help-block small text-navy"> {{ $t("teachers.programming_language_edit_desc_new") }} </span>
          </div>
        </div>

        <div
          v-if="isCodeCombat"
          class="form-group row code-format"
        >
          <div class="col-xs-12">
            <label>
              <span class="control-label"> {{ $t("teachers.code_formats") }} </span>
            </label>
            <div class="form-group">
              <label
                v-for="codeFormat in availableCodeFormats"
                :key="codeFormat.id"
                class="checkbox-inline"
                :disabled="codeFormat.disabled"
              >
                <input
                  v-model="newCodeFormats"
                  :value="codeFormat.id"
                  :disabled="codeFormat.disabled"
                  name="codeFormats"
                  type="checkbox"
                >
                <span>{{ codeFormat.name }}</span>
              </label>
              <span class="help-block small text-navy">{{ $t("teachers.code_formats_description") }}</span>
              <p
                v-if="!enableBlocks"
                class="help-block small text-navy"
              >
                {{ $t("teachers.code_formats_disabled_by", { language: codeLanguageObject[newProgrammingLanguage]?.name }) }}
              </p>
              <p class="help-block small text-navy">
                {{ $t('teachers.code_formats_mobile') }}
              </p>
              <p class="help-block small text-navy">
                {{ $t('teachers.code_formats_fallback') }}
              </p>
            </div>
          </div>
        </div>
        <div
          v-if="isCodeCombat"
          class="form-group row default-code-format"
        >
          <div class="col-xs-12">
            <label for="default-code-format-select">
              <span class="control-label"> {{ $t("teachers.default_code_format") }} </span>
            </label>
            <select
              id="default-code-format-select"
              v-model="newCodeFormatDefault"
              class="form-control"
              name="codeFormatDefault"
            >
              <option
                v-for="codeFormat in enabledCodeFormats"
                :key="codeFormat.id"
                :value="codeFormat.id"
              >
                {{ codeFormat.name }}
              </option>
            </select>
            <span class="help-block small text-navy">{{ $t("teachers.default_code_format_description") }}</span>
          </div>
        </div>
        <div
          v-if="isOzaria && !me.isCodeNinja()"
          class="form-group row class-grades"
          :class="{ 'has-error': $v.classGrades.$error }"
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
            <span
              v-if="!$v.classGrades.required"
              class="form-error ml-small"
            >
              {{ $t("form_validation_errors.required") }}
            </span>
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
                v-if="me.isCodeNinja()"
                value="camp-esports"
              >
                {{ $t('courses.class_type_camp_esports') }}
              </option>
              <option
                v-if="me.isCodeNinja()"
                value="camp-junior"
              >
                {{ $t('courses.class_type_camp_junior') }}
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
        <div
          v-if="!asClub && (moreOptions && isCodeCombat || me.isCodeNinja())"
          class="form-group row"
        >
          <div class="col-xs-12">
            <label for="form-new-class-date-start">
              <span class="control-label"> {{ $t("courses.estimated_class_dates_label") }} </span>
            </label>
            <div class="estimated-date-fields">
              <input
                id="form-new-class-date-start"
                v-model="newClassDateStart"
                type="date"
                class="form-control"
              >
              <label for="form-new-class-date-end">
                <span class="spl.spr">{{ $t("courses.student_age_range_to") }}</span>
              </label>
              <input
                id="form-new-class-date-end"
                v-model="newClassDateEnd"
                type="date"
                class="form-control"
              >
            </div>
          </div>
        </div>
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
        <div>
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
            <secondary-button
              :disabled="saving"
              class="class-submit"
              @click="saveClass"
            >
              {{ classroomInstance.isNew() ? $t("courses.create_class") : $t("common.save_changes") }}
            </secondary-button>
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
}

.edit-class {
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  margin: 15px 15px 0px 15px;
  width: 600px;
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

.estimated-date-fields {
  display: flex;
  flex-direction: row;
  justify-content: space-between;
  align-items: center;
  width: 100%;

  input {
    width: 45%;
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

.checkbox-inline {
  input[type=checkbox] {
    margin-top: 8px;
  }
}

.ml-small {
  margin-left: 5px;
}

.more-options-text {
  font-size: 15px;

  span {
    font-size: 18px;
    line-height: 15px;
  }
}
.initial-free-courses {
  .initial-course-blurb {
    margin-bottom: 0;
  }
  .initial-course-name {
    font-size: 0.85em;
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
</style>
