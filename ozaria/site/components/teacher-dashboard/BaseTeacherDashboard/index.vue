<script>
  import Panel from '../Panel/index.vue'
  import ModalNewClass from '../modals/ModalNewClass/index'
  import ModalAssignContent from '../modals/ModalAssignContent/index'
  import ModalAddStudents from '../modals/ModalAddStudents'
  import ModalRemoveStudents from '../modals/ModalRemoveStudents'

  import BaseSingleClass from '../../../store/BaseSingleClass'
  export default {
    components: {
      Panel,
      ModalNewClass,
      ModalAssignContent,
      ModalAddStudents,
      ModalRemoveStudents
    },
    data () {
      // TODO: move the logic to open/close modals to teacherDashboard store instead of driving by events,
      // as it might grow a lot and become hard to maintain.
      return {
        showNewClassModal: false,
        showAssignContentModal: false,
        showAddStudentsModal: false,
        showRemoveStudentsModal: false
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
      @addStudents="showAddStudentsModal = true"
      @removeStudents="showRemoveStudentsModal = true"
    />
    <modal-new-class
      v-if="showNewClassModal"
      @close="showNewClassModal = false"
    />
    <modal-assign-content
      v-if="showAssignContentModal"
      @close="showAssignContentModal = false"
    />
    <modal-add-students
      v-if="showAddStudentsModal"
      @close="showAddStudentsModal = false"
    />
    <modal-remove-students
      v-if="showRemoveStudentsModal"
      @close="showRemoveStudentsModal = false"
    />
  </div>
</template>
