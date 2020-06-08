<script>
  import BaseModalTeacherDashboard from '../BaseModalTeacherDashboard'
  import ModalAssignForm from './ModalAssignForm'

  export default Vue.extend({
    components: {
      BaseModalTeacherDashboard,
      ModalAssignForm
    }
  })
</script>

<template>
  <base-modal-teacher-dashboard
    :title="'Assign Content'"
    @close="$emit('close')"
  >
    <modal-assign-form @close="$emit('close')" />
  </base-modal-teacher-dashboard>
</template>
