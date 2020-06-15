<script>
  import { mapGetters, mapActions, mapMutations } from 'vuex'
  import { COMPONENT_NAMES } from '../common/constants.js'
  import SecondaryTeacherNavigation from '../common/SecondaryTeacherNavigation'
  import TitleBar from '../common/TitleBar'
  import LoadingBar from '../common/LoadingBar'
  import ClassStatCalculator from './components/ClassStatCalculator'

  export default {
    name: COMPONENT_NAMES.MY_CLASSES_ALL,
    components: {
      'secondary-teacher-navigation': SecondaryTeacherNavigation,
      'title-bar': TitleBar,
      'loading-bar': LoadingBar,
      ClassStatCalculator
    },
    computed: {
      ...mapGetters({
        loading: 'teacherDashboard/getLoadingState',
        activeClassrooms: 'teacherDashboard/getActiveClassrooms',
        archivedClassrooms: 'teacherDashboard/getArchivedClassrooms'
      })
    },

    mounted () {
      this.setTeacherId(me.get('_id'))
      this.fetchData({ componentName: this.$options.name })
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
        setTeacherId: 'teacherDashboard/setTeacherId'
      })
    }
  }
</script>

<template>
  <div>
    <secondary-teacher-navigation
      :classrooms="activeClassrooms"
    />
    <title-bar title="All classes" @newClass="$emit('newClass')" />
    <loading-bar
      :key="loading"
      :loading="loading"
    />

    <class-stat-calculator
      v-for="clas in activeClassrooms"
      :key="clas._id"
      :classroom-state="clas"
    />

    <div id="archived-area">
      <div class="archived-title">
        <h1>{{ $t('teacher.archived_classes') }}</h1>
      </div>

      <class-stat-calculator
        v-for="clas in archivedClassrooms"
        :key="clas._id"
        :classroom-state="clas"
      />
    </div>
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

    margin-top: 100px;

    h1 {
      @include font-h-4-nav-uppercase-black;
      color: #545b64;
      padding: 10px 31px;
    }
  }

  #archived-area {
    background-color: #d8d8d8;
    margin-bottom: -50px;
    padding-bottom: 50px;
  }
</style>
