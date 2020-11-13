<script>
  import Modal from '../../../common/Modal'
  import ModalClassForm from './ModalClassForm'
  import ModalClassInfo from '../ModalClassInfo'
  import ModalInviteStudents from '../ModalInviteStudents'

  export default Vue.extend({
    components: {
      Modal,
      ModalClassForm,
      ModalClassInfo,
      ModalInviteStudents
    },
    data: () => {
      return {
        classroomInfo: null,
        showInviteStudentsModal: false
      }
    },
    computed: {
      showClassInfoModal () {
        return !this.showClassFormModal && this.classroomInfo && !this.showInviteStudentsModal
      },
      showClassFormModal () {
        return !this.classroomInfo
      },
      modalTitle () {
        if (this.showInviteStudentsModal) {
          return 'Invite Students by Email'
        } else {
          return 'Add a new class'
        }
      }
    },
    methods: {
      classCreated (classroom) {
        this.classroomInfo = classroom
        this.$emit('class-created')
      }
    }
  })
</script>

<template>
  <modal
    :title="modalTitle"
    @close="$emit('close')"
  >
    <modal-class-form
      v-if="showClassFormModal"
      @done="classCreated"
    />
    <modal-class-info
      v-if="showClassInfoModal"
      :classroom-code="classroomInfo.codeCamel"
      from="ModalNewClass"
      @inviteStudents="showInviteStudentsModal = true"
      @done="$emit('close')"
    />
    <modal-invite-students
      v-if="showInviteStudentsModal && classroomInfo"
      :classroom-code="classroomInfo.codeCamel"
      :classroom-id="classroomInfo._id"
      from="ModalNewClass"
      @back="showInviteStudentsModal = false"
      @done="$emit('close')"
    />
  </modal>
</template>
