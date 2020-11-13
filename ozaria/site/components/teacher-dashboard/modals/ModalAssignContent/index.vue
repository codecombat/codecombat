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
    :title="'Assign Content'"
    @close="$emit('close')"
  >
    <modal-assign-form @close="$emit('close')" />
  </modal>
</template>
