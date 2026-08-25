<template>
  <modal
    :title="title"
    @close="$emit('close')"
  >
    <div
      class="teacher-form edit-class"
      :class="{ 'edit-class-coco': isCodeCombat }"
    >
      <PageFirst
        v-if="currentPage === 1"
        v-model="newClass.pageFirst"
        :classroom="classroom"
        :show-validation="pageFirstShowValidation"
        :valid.sync="pageFirstValid"
      />
      <PageSecond
        v-else
        ref="pageSecond"
        v-model="newClass.pageSecond"
        :page-first="newClass.pageFirst"
        :is-new-classroom="classroomInstance.isNew()"
      />
      <div class="form-group row buttons-row">
        <div class="col-xs-12 buttons">
          <div class="buttons-left">
            <purple-secondary-button
              v-if="currentPage === 2"
              class="back"
              @click="back"
            >
              {{ $t('common.back') }}
            </purple-secondary-button>
            <purple-secondary-button
              v-if="archived"
              class="class-unarchive"
              @click="unarchiveClass"
            >
              <img src="/images/ozaria/teachers/dashboard/svg_icons/IconUnarchive.svg">
              {{ $t("teacher.unarchive_class") }}
            </purple-secondary-button>
            <purple-secondary-button
              v-if="!classroomInstance.isNew() && !archived"
              class="class-archive"
              @click="archiveClass"
            >
              <img src="/images/ozaria/teachers/dashboard/svg_icons/IconArchive.svg">
              {{ $t("teacher.archive_class") }}
            </purple-secondary-button>
          </div>
          <div
            class="submit-button"
          >
            <purple-button
              :inactive="saving"
              class="class-submit"
              @click="clickedCTA"
            >
              {{ ctaButtonText }}
            </purple-button>
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
  </modal>
</template>

<script>
import { mapActions, mapGetters } from 'vuex'
import utils from 'core/utils'
import Classroom from 'models/Classroom'
import ClassroomsApi from 'app/core/api/classrooms.js'
import GoogleClassroomHandler from 'core/social-handlers/GoogleClassroomHandler'
import LmsRosterImportHandler from 'core/social-handlers/LmsRosterImportHandler'

import Modal from '../../common/Modal'
import PageFirst from './edit-class-components-v2/PageFirst'
import PageSecond from './edit-class-components-v2/PageSecond'
import PurpleButton from '../common/buttons/PurpleButton'
import PurpleSecondaryButton from '../common/buttons/PurpleSecondaryButton'
import { COMPONENT_NAMES } from 'ozaria/site/components/teacher-dashboard/common/constants.js'

// A classroom is linked to at most one external source at a time.
function initialImportLink (classroom) {
  if (classroom?.googleClassroomId) {
    return { source: 'google', externalId: classroom.googleClassroomId, members: null }
  }
  if (classroom?.otherProductId) {
    return { source: 'otherProduct', externalId: classroom.otherProductId, members: null }
  }
  if (classroom?.lmsClassroom?.classId) {
    return { source: 'lms', externalId: classroom.lmsClassroom.classId, members: null }
  }
  return { source: null, externalId: null, members: null }
}

function initialPageSecond (classroom) {
  const aceConfig = classroom?.aceConfig || {}
  return {
    codeLanguage: aceConfig.language || 'python',
    codeFormats: aceConfig.codeFormats ?? ['text-code'],
    codeFormatDefault: aceConfig.codeFormatDefault ?? 'text-code',
    classroomItems: classroom?.classroomItems ?? true,
    disablePaste: aceConfig.disablePaste ?? false,
    liveCompletion: aceConfig.liveCompletion ?? true,
    remix: classroom?.hackstackConfig?.remixAllowed || false,
    levelChat: aceConfig.levelChat === undefined ? true : aceConfig.levelChat === 'fixed_prompt_only',
    classroomDescription: classroom?.description || '',
    averageStudentExp: classroom?.averageStudentExp || '',
    classroomType: classroom?.type || '',
    classesPerWeek: classroom?.classesPerWeek || '',
    minutesPerClass: classroom?.minutesPerClass || '',
    classDateStart: classroom?.classDateStart || '',
    classDateEnd: classroom?.classDateEnd || '',
    grades: classroom?.grades || [],
  }
}

export default Vue.extend({
  components: {
    Modal,
    PageFirst,
    PageSecond,
    PurpleButton,
    PurpleSecondaryButton,
  },
  props: {
    classroom: {
      type: Object,
      required: true,
      default: () => {},
    },
  },
  data () {
    return {
      currentPage: 1,
      saving: false,
      errMsg: '',
      archived: this.classroom?.archived || false,
      pageFirstValid: false,
      pageFirstShowValidation: false,
      newClass: {
        pageFirst: {
          name: this.classroom?.name || '',
          initCourse: this.classroom?.initialFreeCourses?.[0] || (utils.isCodeCombat ? utils.courseIDs.INTRODUCTION_TO_COMPUTER_SCIENCE : undefined),
          importLink: initialImportLink(this.classroom),
        },
        pageSecond: initialPageSecond(this.classroom),
      },
    }
  },
  computed: {
    ...mapGetters({
      courses: 'courses/sorted',
      getSessionsMapForClassroom: 'levelSessions/getSessionsMapForClassroom',
    }),
    isCodeCombat () {
      return utils.isCodeCombat
    },
    title () {
      let title = ''
      if (this.classroomInstance.isNew()) {
        title += $.i18n.t('courses.create_new_class')
      } else {
        title += $.i18n.t('courses.edit_settings1')
      }
      return title
    },
    ctaButtonText () {
      if (this.currentPage === 1 && this.newClass.pageFirst.initCourse !== utils.courseIDs.INTRO_TO_AI) {
        return $.i18n.t('common.next')
      } else {
        return this.classroomInstance.isNew() ? $.i18n.t('courses.create_class') : $.i18n.t('common.save_changes')
      }
    },
    classroomInstance () {
      return new Classroom(this.classroom)
    },
    lmsKey () {
      if (me.isSchoology()) {
        return 'schoology'
      } else if (me.isClassLink()) {
        return 'classlink'
      }
      return null
    },
    // Keyed the same way as the import-source components' `source`, so saveClass/
    // handleClassroomImport don't need a per-source if-block for each one.
    importLinkHandlers () {
      return {
        google: {
          applyToUpdates: (updates, importLink) => {
            updates.googleClassroomId = importLink.externalId
          },
          afterSave: async (savedClassroom, importLink) => {
            await GoogleClassroomHandler.markAsImported(importLink.externalId)
            try {
              const importedMembers = await GoogleClassroomHandler.importStudentsToClassroom(savedClassroom)
              if (importedMembers.length > 0) {
                console.debug('Students imported to classroom:', importedMembers)
              }
            } catch (e) {
              this.errMsg = e || 'Error in importing students'
              noty({ text: this.errMsg, layout: 'topCenter', type: 'error', timeout: 5000 })
            }
          },
        },
        otherProduct: {
          applyToUpdates: (updates, importLink) => {
            updates.otherProductId = importLink.externalId
            if (importLink.members) {
              updates.members = importLink.members
            }
          },
          afterSave: async (savedClassroom, importLink, updates) => {
            const members = (updates.members || [])
              .map(memberId => ({
                _id: memberId,
                role: 'student',
              }))

            // set linking in both classrooms
            ClassroomsApi.update({
              classroomID: importLink.externalId,
              updates: { otherProductId: savedClassroom._id },
            }, { callOz: true }).catch(console.log)
            if (members.length > 0) {
              await this.addMembersToClassroom({ classroom: savedClassroom, members, componentName: COMPONENT_NAMES.MY_CLASSES_ALL })
            }
          },
        },
        lms: {
          applyToUpdates: (updates, importLink, newClass) => {
            updates.lmsClassroom = {
              classId: importLink.externalId,
              name: newClass.name,
              provider: this.lmsKey,
            }
          },
          afterSave: async (savedClassroom) => {
            noty({ text: 'Importing classroom...', layout: 'topCenter', type: 'info', timeout: 3000 })
            await LmsRosterImportHandler.importClassroom(savedClassroom)
          },
        },
      }
    },
  },
  watch: {
    newClass: {
      deep: true,
      handler (newV) {
      },
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
      createClassroom: 'classrooms/createClassroom',
      createFreeCourseInstances: 'courseInstances/createFreeCourseInstances',
      updateClassroom: 'classrooms/updateClassroom',
      fetchClassroomSessions: 'levelSessions/fetchForClassroomMembers',
      fetchCourses: 'courses/fetchReleased',
      fetchCourseInstances: 'courseInstances/fetchCourseInstancesForClassroom',
      addMembersToClassroom: 'classrooms/addMembersToClassroom',
    }),
    back () {
      this.currentPage = 1
    },
    async clickedCTA () {
      this.errMsg = ''
      if (this.currentPage === 1) {
        this.pageFirstShowValidation = true
        if (!this.pageFirstValid) {
          this.errMsg = 'Missing required data'
          return
        }
        if (this.newClass.pageFirst.initCourse !== utils.courseIDs.INTRO_TO_AI) {
          this.currentPage = 2
          return
        }
      }
      await this.saveClass()
    },
    async saveClass () {
      this.saving = true
      this.errMsg = ''
      const newClass = { ...this.newClass.pageFirst, ...this.newClass.pageSecond }
      const updates = {}

      updates.type = newClass.classroomType

      if (newClass.classDateStart && newClass.classDateEnd && moment(newClass.classDateEnd).isBefore(moment(newClass.classDateStart))) {
        this.errMsg = 'End date should be after start date'
        this.saving = false
        return
      }

      updates.name = newClass.name
      const aceConfig = _.clone((this.classroom || {}).aceConfig || {})
      const hackstackConfig = _.clone((this.classroom || {}).hackstackConfig || {})
      aceConfig.language = newClass.codeLanguage
      aceConfig.liveCompletion = newClass.liveCompletion
      aceConfig.disablePaste = newClass.disablePaste
      updates.classroomItems = newClass.classroomItems

      // Make sure that codeFormats includes codeFormatDefault, including when these aren't specified
      if (!newClass.codeFormats.includes(newClass.codeFormatDefault)) {
        newClass.codeFormats.push(newClass.codeFormatDefault)
      }
      aceConfig.codeFormats = newClass.codeFormats
      aceConfig.codeFormatDefault = newClass.codeFormatDefault

      if (newClass.levelChat) {
        aceConfig.levelChat = 'fixed_prompt_only'
      } else {
        aceConfig.levelChat = 'none'
      }

      if (newClass.remix) {
        hackstackConfig.remixAllowed = true
      } else {
        hackstackConfig.remixAllowed = false
      }

      updates.aceConfig = aceConfig
      updates.hackstackConfig = hackstackConfig

      updates.description = newClass.classroomDescription
      updates.averageStudentExp = newClass.averageStudentExp
      updates.classDateStart = newClass.classDateStart
      updates.classDateEnd = newClass.classDateEnd
      updates.classesPerWeek = String(newClass.classesPerWeek)
      updates.minutesPerClass = String(newClass.minutesPerClass)

      if (newClass.importLink?.source) {
        this.importLinkHandlers[newClass.importLink.source].applyToUpdates(updates, newClass.importLink, newClass)
      }

      const grades = newClass.grades || []
      if (grades.length > 0 || !this.classroomInstance.isNew()) {
        updates.grades = grades
      }

      if (utils.isCodeCombat) {
        if (!newClass.initCourse && this.classroomInstance.isNew()) {
          this.errMsg = 'Please select at least one course'
          this.saving = false
          return
        }
        updates.initialFreeCourses = [newClass.initCourse]
      }

      let savedClassroom
      if (this.classroomInstance.isNew()) {
        try {
          const classReqData = { ...this.classroom.attributes, ...updates }
          savedClassroom = await this.createClassroom(classReqData)
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
        await this.createFreeCourseInstances({ classroom: savedClassroom, courses: this.courses })
        this.$emit('updated')
      }
      try {
        await this.handleClassroomImport(savedClassroom, updates)
      } catch (err) {
        noty({
          type: 'error',
          message: `Classroom import failed: ${err?.message}`,
          timeout: 5000,
        })
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
    async handleClassroomImport (savedClassroom, updates) {
      const importLink = this.newClass.pageFirst.importLink
      if (importLink?.source) {
        await this.importLinkHandlers[importLink.source].afterSave(savedClassroom, importLink, updates)
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
  },
})
</script>
<style scoped lang="scss">
@import "app/styles/ozaria/_ozaria-style-params.scss";
::v-deep {

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

  .buttons-row {
    width: 100%;
  }

  .buttons {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-top: 5px;

    .buttons-left {
      display: flex;
      align-items: center;
    }

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
}
</style>
