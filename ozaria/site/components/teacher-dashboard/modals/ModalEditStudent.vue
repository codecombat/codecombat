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
          noty({
            text: `An error occurred.`,
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
    title="Student Details"
    @close="closeModalEditStudent"
  >
    <div
      id="modal-edit-student"
      class="style-ozaria teacher-form"
    >
      <div>
        <p><b>Student Name:</b> {{ studentName }}</p>
        <p><b>Username:</b> {{ username }}</p>
        <p
          v-if="email"
        >
          <b>Email:</b> {{ email }}
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
              >Change Password</label>
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
                Change Password
              </primary-button>
            </div>
          </div>
        </form>
      </div>
      <secondary-button
        class="right-button"
        @click="closeModalEditStudent"
      >
        <b>Done</b>
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
