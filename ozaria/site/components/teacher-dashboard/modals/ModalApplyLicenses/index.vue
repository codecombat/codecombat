<script>
import Modal from '../../../common/Modal'
import ModalApplyLicense from './ModalApplyLicense'

export default Vue.extend({
  name: 'ModalApplyLicenseIndex',
  components: {
    Modal,
    ModalApplyLicense,
  },
})
</script>

<template>
  <modal
    :title="'Apply License'"
    @close="$emit('close')"
  >
    <modal-apply-license @close="$emit('close')" />
  </modal>
</template>
