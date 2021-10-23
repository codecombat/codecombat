<script>
  import Modal from '../../common/Modal'
  import PrimaryButton from '../common/buttons/PrimaryButton'
  import SecondaryButton from '../common/buttons/SecondaryButton'
  import User from 'models/User'
  import Classroom from 'models/Classroom'

  import { mapMutations, mapGetters } from 'vuex'
  export default {
    components: {
      Modal,
      PrimaryButton,
      SecondaryButton
    },

    props: {
      displayOnly: {
        type: Boolean,
        default: false
      }
    },

    data: () => ({
      newPassword: '',
      changingPassword: false
    }),

    computed: {
      ...mapGetters({
        classroomMembers: 'teacherDashboard/getMembersCurrentClassroom',
        editingStudent: 'baseSingleClass/currentEditingStudent',
        classroom: 'teacherDashboard/getCurrentClassroom'
      }),

      selectedStudent () {
        const resultStudent = this.classroomMembers.find(({ _id }) => _id === this.editingStudent)
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
      }
    },

    methods: {
      ...mapMutations({
        closeModalEditStudent: 'baseSingleClass/closeModalEditStudent'
      }),

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
            text: `Password Changed successfully!`,
            type: 'success',
            layout: 'center',
            timeout: 6000
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
            timeout: 6000
          })
        } finally {
          this.changingPassword = false
        }
      }
    }
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
