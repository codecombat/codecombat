<script>
  import { mapGetters, mapActions, mapMutations } from 'vuex'
  import { COMPONENT_NAMES, PAGE_TITLES } from '../common/constants.js'
  import TeacherRowComponent from './TeacherRowComponent'

  export default {
    name: COMPONENT_NAMES.MY_SCHOOLS,

    components: {
      TeacherRowComponent
    },

    computed: {
      ...mapGetters({
        loading: 'schoolAdminDashboard/getLoadingState',
        administratedTeachers: 'schoolAdminDashboard/getAdministratedTeachers',
        getStatsByUser: 'userStats/getStatsByUser'
      }),

      groupedAdministratedTeachers () {
        const groupedTeachers = {}

        for (const teacher of this.administratedTeachers) {
          const trialRequest = teacher._trialRequest || {}

          groupedTeachers[trialRequest.organization] = groupedTeachers[trialRequest.organization] || []
          groupedTeachers[trialRequest.organization].push(teacher)
        }

        return Object.freeze(groupedTeachers)
      }
    },

    mounted () {
      this.setPageTitle(PAGE_TITLES[this.$options.name])
      this.fetchData({ componentName: this.$options.name, options: { loadedEventName: 'My Schools: Loaded' } })
    },

    destroyed () {
      this.resetLoadingState()
    },

    methods: {
      ...mapActions({
        fetchData: 'schoolAdminDashboard/fetchData'
      }),

      ...mapMutations({
        resetLoadingState: 'schoolAdminDashboard/resetLoadingState',
        setPageTitle: 'schoolAdminDashboard/setPageTitle'
      })
    }
  }
</script>

<template>
  <div class="my-schools">
    <div
      v-if="administratedTeachers.length === 0 && !loading"
      class="no-teachers"
    >
      <span v-html="$t('school_administrator.no_teachers')" />
    </div>
    <div v-else>
      <ul
        v-for="(teachers, groupName) of groupedAdministratedTeachers"
        :key="groupName"
        class="teacher-list"
      >
        <li class="group-title">
          <span v-if="groupName">
            {{ groupName }}
          </span>
          <span v-else>
            {{ $t('school_administrator.other') }}
          </span>
        </li>

        <teacher-row-component
          v-for="teacher in teachers"
          :key="teacher.id"
          :teacher="teacher"
          :user-stats="getStatsByUser(teacher._id)"
        />
      </ul>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

.my-schools {
  margin: 30px;
  min-height: 200px;
}

.teacher-list {
  margin-bottom: 30px;
  padding: 0;
  list-style: none;
}

.teacher-list .group-title {
  margin-bottom: 20px;
  @include font-h-5-button-text-black;
  color: $twilight;
  text-align: left;
  text-transform: capitalize;
}

.no-teachers {
  span {
    font-family: Work Sans;
    font-style: normal;
    font-weight: normal;
    font-size: 20px;
    line-height: 23px;
    color: $pitch;
    a {
      text-decoration: underline;
    }
  }
}
</style>
