<script>
  import Panel from '../Panel/index.vue'
  import ModalNewClass from '../modals/ModalNewClass/index'
  export default {
    components: {
      Panel,
      ModalNewClass
    },
    data () {
      return {
        showNewClassModal: false
      }
    },
    metaInfo () {
      return {
        title: 'ADMIN ONLY - Teacher Dashboard'
      }
    }
  }
</script>

<template>
  <div>
    <panel />
    <router-view @newClass="showNewClassModal = true" />
    <modal-new-class
      v-if="showNewClassModal"
      @close="showNewClassModal = false"
    />
  </div>
</template>
