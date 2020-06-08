<script>
  import Panel from '../Panel/index.vue'
  import ModalNewClass from '../modals/ModalNewClass/index'
  import ModalAssignContent from '../modals/ModalAssignContent/index'
  import BaseSingleClass from '../../../store/BaseSingleClass'
  export default {
    components: {
      Panel,
      ModalNewClass,
      ModalAssignContent
    },
    data () {
      return {
        showNewClassModal: false,
        showAssignContentModal: false
      }
    },
    beforeCreate () {
      this.$store.registerModule('baseSingleClass', BaseSingleClass)
    },
    destroyed () {
      this.$store.unregisterModule('baseSingleClass')
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
    <router-view
      @newClass="showNewClassModal = true"
      @assignContent="showAssignContentModal = true"
    />
    <modal-new-class
      v-if="showNewClassModal"
      @close="showNewClassModal = false"
    />
    <modal-assign-content
      v-if="showAssignContentModal"
      @close="showAssignContentModal = false"
    />
  </div>
</template>
