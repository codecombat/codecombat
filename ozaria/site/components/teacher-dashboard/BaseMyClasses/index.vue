<script>
  import { mapGetters, mapActions, mapMutations } from 'vuex'
  import { COMPONENT_NAMES, PAGE_TITLES } from '../common/constants.js'
  import ClassStatCalculator from './components/ClassStatCalculator'
  import ModalEditClass from '../modals/ModalEditClass'
  import ModalAddStudents from '../modals/ModalAddStudents'
  import moment from 'moment'

  import BannerWebinar from './components/BannerWebinar'

  import ButtonsSchoolAdmin from './ButtonsSchoolAdmin'

  export default {
    name: COMPONENT_NAMES.MY_CLASSES_ALL,
    components: {
      ClassStatCalculator,
      ModalEditClass,
      ButtonsSchoolAdmin,
      ModalAddStudents,
      BannerWebinar
    },

    props: {
      teacherId: { // sent from DSA
        type: String,
        default: ''
      },
      displayOnly: { // sent from DSA
        type: Boolean,
        default: false
      }
    },

    data: () => {
      return {
        showEditClassModal: false,
        showAddStudentsModal: false,
        editClassroomObject: {},
        archiveHidden: true
      }
    },

    computed: {
      ...mapGetters({
        activeClassrooms: 'teacherDashboard/getActiveClassrooms',
        archivedClassrooms: 'teacherDashboard/getArchivedClassrooms',
        getTrackCategory: 'teacherDashboard/getTrackCategory'
      }),

      sortedActiveClasses () {
        const classrooms = [...this.activeClassrooms]
        classrooms.sort((a, b) =>
          moment(parseInt(b._id.substring(0, 8), 16) * 1000).diff(moment(parseInt(a._id.substring(0, 8), 16) * 1000))
        )
        return classrooms
      },

      sortedArchivedClassrooms () {
        const classrooms = [...this.archivedClassrooms]
        classrooms.sort((a, b) =>
          moment(parseInt(b._id.substring(0, 8), 16) * 1000).diff(moment(parseInt(a._id.substring(0, 8), 16) * 1000))
        )
        return classrooms
      }
    },

    mounted () {
      this.setTeacherId(this.teacherId || me.get('_id'))
      this.setPageTitle(PAGE_TITLES[this.$options.name])
      this.fetchData({ componentName: this.$options.name, options: { loadedEventName: 'All Classes: Loaded' } })
    },

    destroyed () {
      this.resetLoadingState()
    },

    methods: {
      ...mapActions({
        fetchData: 'teacherDashboard/fetchData'
      }),

      ...mapMutations({
        resetLoadingState: 'teacherDashboard/resetLoadingState',
        setTeacherId: 'teacherDashboard/setTeacherId',
        setPageTitle: 'teacherDashboard/setPageTitle'
      }),

      openEditModal (classroom) {
        this.showEditClassModal = true
        this.editClassroomObject = classroom
      },

      openAddModal (classroom) {
        this.showAddStudentsModal = true
        this.editClassroomObject = classroom
      },

      clickArchiveArrow () {
        this.archiveHidden = !this.archiveHidden
        if (!this.archiveHidden) {
          window.tracker?.trackEvent('All Classes: Archived Classes Dropdown Opened', { category: this.getTrackCategory })
        }
      }
    }
  }
</script>

<template>
  <div>
    <banner-webinar />

    <div id="class-stats-area">
      <div
        v-for="clas in sortedActiveClasses"
        :key="clas._id"
        class="active-class"
      >
        <class-stat-calculator
          :classroom-state="clas"
          :display-only="displayOnly"
          class="class-stats"
          @clickTeacherArchiveModalButton="openEditModal(clas)"
          @clickAddStudentsModalButton="openAddModal(clas)"
        />
        <buttons-school-admin
          v-if="displayOnly"
          class="buttons-school-admin"
          :inactive="false"
          :progress-url="`/school-administrator/teacher/${clas.ownerID}/classes/${clas._id}`"
          :projects-url="`/school-administrator/teacher/${clas.ownerID}/classes/${clas._id}/projects`"
        />
      </div>
    </div>

    <div id="archived-area">
      <div class="archived-title">
        <h1>{{ $t('teacher.archived_classes') }}</h1>
        <div class="arrow-toggle" @click="clickArchiveArrow">
          <div v-if="!archiveHidden" class="arrow-icon-up" />
          <div v-else class="arrow-icon-down" />
        </div>
      </div>

      <div
        v-for="clas in sortedArchivedClassrooms"
        v-show="!archiveHidden"
        :key="clas._id"
        class="archived-class"
      >
        <class-stat-calculator
          :classroom-state="clas"
          :display-only="displayOnly"
          class="class-stats"
          @clickTeacherArchiveModalButton="openEditModal(clas)"
        />
        <buttons-school-admin
          v-if="displayOnly"
          class="buttons-school-admin"
          :inactive="true"
        />
      </div>
    </div>

    <modal-edit-class
      v-if="showEditClassModal"
      :classroom="editClassroomObject"
      @close="showEditClassModal = false"
    />
    <modal-add-students
      v-if="showAddStudentsModal"
      :classroom="editClassroomObject"
      @close="showAddStudentsModal = false"
    />
  </div>
</template>

<style lang="scss" scoped>
  @import "app/styles/bootstrap/variables";
  @import "ozaria/site/styles/common/variables.scss";
  @import "app/styles/ozaria/_ozaria-style-params.scss";

  .archived-title {
    height: 50px;
    width: 100%;
    background: #f2f2f2;
    border: 0.5px solid #adadad;
    box-shadow: 0px 4px 4px rgba(0, 0, 0, 0.06);

    display: flex;
    align-items: center;
    justify-content: space-between;

    margin-top: 100px;

    h1 {
      @include font-h-4-nav-uppercase-black;
      color: #545b64;
      padding: 10px 31px;
    }
  }

  #class-stats-area {
    min-height: 200px;
  }

  #archived-area {
    background-color: #d8d8d8;
    margin-bottom: -50px;
    padding-bottom: 50px;
  }

  .active-class, .archived-class {
    display: flex;
    flex-direction: row;
    align-items: center;
    justify-content: center;
    margin: 28px 32px 0;
    .class-stats {
      flex-grow: 7;
    }
    .buttons-school-admin {
      flex-grow: 1;
      height: 126px;
    }
  }

  .arrow-toggle {
    width: 62px;
    height: 100%;
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;

    cursor: pointer;
    box-shadow: -1px 0px 1px rgba(0, 0, 0, 0.06), 3px 0px 8px rgba(0, 0, 0, 0.15);

    &:hover {
      background: #eeeced;
      box-shadow: -1px 0px 1px rgba(0, 0, 0, 0.06), 0px 4px 4px rgba(0, 0, 0, 0.25), inset 0px 5px 10px rgba(0, 0, 0, 0.15);
    }
  }

  .arrow-icon-up {
    border: 3px solid #476FB1;
    box-sizing: border-box;
    border-bottom: unset;
    border-right: unset;
    transform: rotate(45deg);
    width: 9px;
    height: 9px;
  }

  .arrow-icon-down {
    border: 3px solid #476FB1;
    box-sizing: border-box;
    border-bottom: unset;
    border-right: unset;
    transform: rotate(-135deg);
    width: 9px;
    height: 9px;
  }
</style>
