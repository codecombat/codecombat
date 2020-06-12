<script>
  import { mapGetters } from 'vuex'
  import BaseModalTeacherDashboard from './BaseModalTeacherDashboard'
  import ModalClassInfo from './ModalClassInfo'
  import ModalInviteStudents from './ModalInviteStudents'
  import GoogleClassroomHandler from 'core/social-handlers/GoogleClassroomHandler'

  export default Vue.extend({
    components: {
      BaseModalTeacherDashboard,
      ModalClassInfo,
      ModalInviteStudents
    },
    data: () => {
      return {
        showInviteStudentsModal: false
      }
    },
    computed: {
      ...mapGetters({
        classroomsByTeacher: 'classrooms/getClassroomsByTeacher',
        selectedStudentIds: 'baseSingleClass/selectedStudentIds',
        courses: 'courses/sorted'
      }),

      teacherId () {
        return me.get('_id')
      },
      classroomId () {
        return this.$route.params.classroomId
      },
      activeClassrooms () {
        return (this.classroomsByTeacher(this.teacherId) || {}).active || []
      },
      classroom () {
        return this.activeClassrooms.find((c) => c._id === this.classroomId) || {}
      },
      showClassInfoModal () {
        return !this.showInviteStudentsModal
      },
      showGoogleClassroom () {
        return me.showGoogleClassroom() && (this.classroom.googleClassroomId || '').length > 0
      },
      modalTitle () {
        if (this.showInviteStudentsModal) {
          return 'Invite Students by Email'
        } else {
          return 'Add Students to Class'
        }
      }
    },
    methods: {
      async syncGoogleClassroom () {
        try {
          await new Promise((resolve, reject) =>
            application.gplusHandler.loadAPI({
              success: resolve,
              error: reject
            }))
          await new Promise((resolve, reject) =>
            application.gplusHandler.connect({
              scope: GoogleClassroomHandler.scopes,
              context: this,
              success: resolve
            }))
          const importedMembers = await GoogleClassroomHandler.importStudentsToClassroom(this.classroom)
          if (importedMembers.length > 0) {
            console.debug('Students imported to classroom:', importedMembers)
          }
          this.$emit('close')
        } catch (e) {
          console.log(e)
          noty({ text: 'Error in importing students', layout: 'topCenter', type: 'error', timeout: 2000 })
        }
      }
    }
  })
</script>

<template>
  <base-modal-teacher-dashboard
    :title="modalTitle"
    @close="$emit('close')"
  >
    <modal-class-info
      v-if="showClassInfoModal"
      :classroom-code="classroom.codeCamel"
      :classroom="classroom"
      :show-google-classroom="showGoogleClassroom"
      @inviteStudents="showInviteStudentsModal = true"
      @syncGoogleClassroom="syncGoogleClassroom"
      @done="$emit('close')"
    />
    <modal-invite-students
      v-if="showInviteStudentsModal"
      :classroom-code="classroom.codeCamel"
      :classroom-id="classroom._id"
      @back="showInviteStudentsModal = false"
      @done="$emit('close')"
    />
  </base-modal-teacher-dashboard>
</template>
