<script>
import Modal from '../../../common/Modal'
import ModalAssignForm from './ModalAssignForm'

export default Vue.extend({
  components: {
    Modal,
    ModalAssignForm
  }
})
</script>

<template>
  <modal
    :title="$t('teacher_dashboard.assign_content')"
    @close="$emit('close')"
  >
    <modal-assign-form @close="$emit('close')" />
  </modal>
</template>
