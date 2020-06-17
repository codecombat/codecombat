<script>
  import Panel from '../Panel/index.vue'
  import ModalNewClass from '../modals/ModalNewClass/index'
  import ModalAssignContent from '../modals/ModalAssignContent/index'
  import ModalAddStudents from '../modals/ModalAddStudents'
  import ModalRemoveStudents from '../modals/ModalRemoveStudents'

  import BaseSingleClass from '../../../store/BaseSingleClass'
  import BaseCurriculumGuide from '../BaseCurriculumGuide'
  import BaseCurriculumGuideModule from '../../../store/BaseCurriculumGuide'

  import { mapMutations } from 'vuex'

  export default {
    components: {
      Panel,
      ModalNewClass,
      ModalAssignContent,
      ModalAddStudents,
      ModalRemoveStudents,
      BaseCurriculumGuide
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

    watch: {
      $route (to, from) {
        if (to.params.classroomId !== from.params.classroomId && to.params.classroomId) {
          this.updateStoreOnNavigation()
        }
      }
    },

    beforeCreate () {
      this.$store.registerModule('baseSingleClass', BaseSingleClass)
      this.$store.registerModule('baseCurriculumGuide', BaseCurriculumGuideModule)
    },

    created () {
      this.updateStoreOnNavigation()
    },

    destroyed () {
      this.$store.unregisterModule('baseSingleClass')
      this.$store.unregisterModule('baseCurriculumGuide')
    },

    metaInfo () {
      return {
        title: 'ADMIN ONLY - Teacher Dashboard'
      }
    },

    methods: {
      ...mapMutations({
        setClassroomId: 'teacherDashboard/setClassroomId',
        setTeacherId: 'teacherDashboard/setTeacherId'
      }),

      updateStoreOnNavigation () {
        if (this.$route.params.classroomId) {
          this.setClassroomId(this.$route.params.classroomId)
        }
        this.setTeacherId(me.get('_id'))
      }
    }
  }
</script>

<template>
  <div>
    <base-curriculum-guide />
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
