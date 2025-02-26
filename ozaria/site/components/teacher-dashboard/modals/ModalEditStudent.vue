<script>
import Modal from '../../common/Modal'
import PrimaryButton from '../common/buttons/PrimaryButton'
import SecondaryButton from '../common/buttons/SecondaryButton'
import User from 'models/User'
import Classroom from 'models/Classroom'
import Level from 'models/Level'
import RobloxButton from 'app/views/account/robloxButton'
import { getStudentCredits } from 'app/core/api/user-credits'
import { USER_CREDIT_HACKSTACK_KEY } from 'app/core/constants'

import { mapMutations, mapGetters, mapActions } from 'vuex'
export default {
  components: {
    Modal,
    PrimaryButton,
    SecondaryButton,
    RobloxButton,
  },

  props: {
    displayOnly: {
      type: Boolean,
      default: false,
    },
  },

  data: () => ({
    newPassword: '',
    changingPassword: false,
    levels: [],
    studentCredits: null,
  }),

  computed: {
    ...mapGetters({
      classroomMembers: 'teacherDashboard/getMembersCurrentClassroom',
      getLevelsForClassroom: 'levels/getLevelsForClassroom',
      editingStudentId: 'baseSingleClass/currentEditingStudent',
      classroom: 'teacherDashboard/getCurrentClassroom',
      levelSessionsMapByUser: 'teacherDashboard/getLevelSessionsMapCurrentClassroom',
      aiProjectsMapForClassroom: 'teacherDashboard/getAiProjectsMapCurrentClassroom',
    }),

    creditMessage () {
      if (this.studentCredits && this.studentCredits.result?.length > 0) {
        const credit = this.studentCredits.result[0]
        const durAmount = credit.durationAmount > 1 ? credit.durationAmount : $.i18n.t('hackstack.creditMessage_the')
        return $.i18n.t('hackstack.creditMessage_creditcreditsleft-creditinitialcredits-c', {
          creditCreditsLeft: credit.creditsLeft,
          creditInitialCredits: credit.initialCredits,
          durAmount,
          creditDurationKey: credit.durationKey,
        })
      } else {
        return $.i18n.t('common.loading')
      }
    },

    selectedStudent () {
      const resultStudent = this.classroomMembers.find(({ _id }) => _id === this.editingStudentId)
      return new User(resultStudent)
    },

    studentName () {
      return this.selectedStudent.broadName()
    },

    username () {
      return this.selectedStudent.displayName()
    },

    email () {
      return this.selectedStudent.get('email')
    },

    studentId () {
      return this.selectedStudent.get('_id')
    },

    lastPlayed () {
      const levels = this.levels
      const playedSessions = this.levelSessionsMapByUser[this.editingStudentId] || {}
      const playedProjects = this.aiProjectsMapForClassroom[this.editingStudentId] || {}
      const sessions = Object.values(playedSessions)
      const projects = _.flatten(Object.values(playedProjects))
      const lastPlayed = [
        ...sessions,
        ...projects].reduce((acc, sessionOrProject) => {
          if (!acc) {
            return sessionOrProject
          }
          return sessionOrProject.changed > acc.changed ? sessionOrProject : acc
        }, null)

      const isLastPlayedSession = sessions.includes(lastPlayed)
      const isLastPlayedProject = projects.includes(lastPlayed)

      if (!isLastPlayedProject && !isLastPlayedSession) {
        return null
      }

      return {
        session: isLastPlayedSession ? lastPlayed : null,
        project: isLastPlayedProject ? lastPlayed : null,
        level: isLastPlayedSession ? levels.find(l => l.original === lastPlayed?.level?.original) : null,
      }
    },

    isEnglish () {
      return me.get('preferredLanguage', true) === 'en-US'
    },

    lastPlayedString () {
      let lastPlayedString = ''
      if (this.lastPlayed.level) {
        const level = new Level(this.lastPlayed.level)
        lastPlayedString += level.getTranslatedName()
      }

      if (this.lastPlayed.project) {
        lastPlayedString += this.lastPlayed.project.name
      }

      if (lastPlayedString !== '') {
        if (this.isEnglish) {
          lastPlayedString += ', on '
        } else {
          lastPlayedString += ', '
        }
      }

      let lastPlayedEntity = null
      if (this.lastPlayed.session) {
        lastPlayedEntity = this.lastPlayed.session
      } else if (this.lastPlayed.project) {
        lastPlayedEntity = this.lastPlayed.project
      }

      if (lastPlayedEntity) { lastPlayedString += this.formatDate(lastPlayedEntity.changed) }
      return lastPlayedString
    },
  },

  async mounted () {
    await this.fetchLevelsForClassroom(this.classroom._id)
    this.levels = this.getLevelsForClassroom(this.classroom._id)
    await this.getCredits()
  },

  methods: {
    ...mapMutations({
      closeModalEditStudent: 'baseSingleClass/closeModalEditStudent',
    }),

    ...mapActions({
      fetchLevelsForClassroom: 'levels/fetchForClassroom',
    }),

    formatDate (date) {
      return moment(date).format('LLLL')
    },

    async getCredits () {
      this.studentCredits = await getStudentCredits(USER_CREDIT_HACKSTACK_KEY, this.studentId)
    },

    async changePassword () {
      // Don't change password if there is no new password, or if the teacher
      // is in the process of currently changing a password.
      if (!this.newPassword || this.changingPassword) {
        return
      }

      try {
        this.changingPassword = true
        await (new Classroom(this.classroom)).setStudentPassword(this.selectedStudent, this.newPassword)
        noty({
          text: 'Password Changed successfully!',
          type: 'success',
          layout: 'center',
          timeout: 6000,
        })
        this.newPassword = ''
      } catch (e) {
        // TODO: Error copy.
        console.error(e)
        let errorText = `Error: ${e.message || 'Could not change password.'}`
        if (/verified their email address/.test(errorText)) {
          errorText += ' Ask the student to get a password reset email from the login screen.'
        }
        if (/Data matches schema from "not"/.test(errorText)) {
          errorText = $.i18n.t('signup.invalid_password')
        }
        noty({
          text: errorText,
          type: 'error',
          layout: 'center',
          timeout: 6000,
        })
      } finally {
        this.changingPassword = false
      }
    },
  },
}
</script>

<template>
  <modal
    :title="$t('teacher.student_details')"
    @close="closeModalEditStudent"
  >
    <div
      id="modal-edit-student"
      class="style-ozaria teacher-form"
    >
      <div>
        <p><b>{{ $t('teacher.student_name') }}:</b> {{ studentName }}</p>
        <p><b>{{ $t('general.username') }}:</b> {{ username }}</p>
        <p
          v-if="email"
        >
          <b>{{ $t('general.email') }}:</b> {{ email }}
        </p>
        <p>
          <b>{{ $t('user.last_played') }}:</b> {{ lastPlayed ?
            lastPlayedString :
            $t('teacher.never_played') }}
        </p>
        <p>
          <b>{{ $t('hackstack.hackstack_credits') }}:</b> {{ creditMessage }}
        </p>

        <form
          class="form-container"
          @submit.prevent="() => {}"
        >
          <div class="form-group row">
            <div class="col-xs-12">
              <label
                class="control-label"
                for="changePassword"
              >{{ $t('teacher.change_password') }} <small>&nbsp; ({{ $t('signup.password_requirements') }})</small></label>
              <input
                v-model="newPassword"
                :disabled="displayOnly"
                name="changePassword"
                type="text"
                autocomplete="off"
                class="input-large form-control"
                required
              >
              <primary-button
                style="padding: 9px 22px;"
                :inactive="displayOnly"
                @click="changePassword"
              >
                {{ $t('teacher.change_password') }}
              </primary-button>
            </div>
          </div>
        </form>
        <roblox-button
          size="small"
          :user-id="studentId"
          :use-oauth="false"
          :use-roblox-id="true"
        />
      </div>
      <secondary-button
        class="right-button"
        @click="closeModalEditStudent"
      >
        <b>{{ $t('common.done') }}</b>
      </secondary-button>
    </div>
  </modal>
</template>

<style lang="scss" scoped>
  @import "app/styles/ozaria/_ozaria-style-params.scss";
  #modal-edit-student {
    width: 598px;
    padding: 26px 31px 20px;
    min-height: 435px;

    display: flex;
    flex-direction: column;
    justify-content: space-between;
  }

  #modal-edit-student.style-ozaria {
    p {
      @include font-p-2-paragraph-medium-gray;
      font-size: 16px;
      margin: 0 0 5px 0;
    }

    label {
      @include font-p-2-paragraph-medium-gray;
      margin-top: 28px;
      margin-bottom: 5px;
      font-size: 16px;
      line-height: 19px;
    }

    input {
      margin-bottom: 16px;
    }

    .right-button {
      min-width: 150px;
      padding: 11px 12px;
      align-self: end;
      align-self: flex-end;
    }
  }
</style>
