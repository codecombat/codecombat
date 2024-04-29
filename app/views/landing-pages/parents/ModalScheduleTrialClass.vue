<template>
  <modal
    title="Schedule a Trial Class"
    @close="$emit('close')"
  >
    <scheduler-view />
  </modal>
</template>

<script>
import Modal from 'app/components/common/Modal'
import SchedulerView from 'app/views/online-class/scheduler'

export default {
  name: 'ModalScheduleTrialClass',
  components: {
    Modal,
    SchedulerView
  }
}
</script>

<style scoped lang="scss">
@import "app/styles/bootstrap/variables";
</style>
