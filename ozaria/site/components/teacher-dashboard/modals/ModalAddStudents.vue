<script>
  import { mapGetters } from 'vuex'
  import Modal from '../../common/Modal'
  import ModalClassInfo from './ModalClassInfo'
  import ModalInviteStudents from './ModalInviteStudents'
  import GoogleClassroomHandler from 'core/social-handlers/GoogleClassroomHandler'

  export default Vue.extend({
    components: {
      Modal,
      ModalClassInfo,
      ModalInviteStudents
    },
    props: {
      classroom: {
        type: Object,
        required: true
      }
    },
    data: () => {
      return {
        showInviteStudentsModal: false,
        googleSyncInProgress: false
      }
    },
    computed: {
      ...mapGetters({
        // TODO: Almost certain this can be cut, but leaving in as this will be quickly merged
        // for HoC and there's no one around to review... :)
        selectedStudentIds: 'baseSingleClass/selectedStudentIds'
      }),
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
    created () {
      if (!this.classroom) {
        console.error('Classroom not set')
        this.$emit('close')
      }
    },
    methods: {
      async syncGoogleClassroom () {
        window.tracker?.trackEvent('Add Students: Sync Google Classroom Clicked', { category: 'Teachers' })
        this.googleSyncInProgress = true
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
          window.tracker?.trackEvent('Add Students: Sync Google Classroom Successful', { category: 'Teachers' })
          this.$emit('close')
        } catch (e) {
          console.error(e)
          noty({ text: $.i18n.t('teachers.error_in_importing_students'), layout: 'topCenter', type: 'error', timeout: 2000 })
        }
        this.googleSyncInProgress = false
      }
    }
  })
</script>

<template>
  <modal
    :title="modalTitle"
    @close="$emit('close')"
  >
    <modal-class-info
      v-if="showClassInfoModal"
      :classroom-code="classroom.codeCamel"
      :classroom="classroom"
      :show-google-classroom="showGoogleClassroom"
      :google-sync-in-progress="googleSyncInProgress"
      from="ModalAddStudents"
      @inviteStudents="showInviteStudentsModal = true"
      @syncGoogleClassroom="syncGoogleClassroom"
      @done="$emit('close')"
    />
    <modal-invite-students
      v-if="showInviteStudentsModal"
      :classroom-code="classroom.codeCamel"
      :classroom-id="classroom._id"
      from="ModalAddStudents"
      @back="showInviteStudentsModal = false"
      @done="$emit('close')"
    />
  </modal>
</template>
