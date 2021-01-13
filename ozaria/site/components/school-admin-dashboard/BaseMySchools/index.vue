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
          const organization = (trialRequest.organization || '').trim().toLowerCase();
          groupedTeachers[organization] = groupedTeachers[organization] || []
          groupedTeachers[organization].push(teacher)
        }

        return Object.freeze(groupedTeachers)
      },
      // returns example: [ [groupName, [teacher1, teacher2]] ] in sorted order of licenses used from high to low
      sortedGroupedAdministratedTeachers() {
        const groupLicenseUsedMap = {};
        const groupNameTeacherArr = [];
        for (const [groupName, teachers] of Object.entries(this.groupedAdministratedTeachers)) {
          let totalUsage = 0;
          for (const teacher of Object.values(teachers)) {
            const usage = teacher?.stats?.licenses?.usage?.used || 0;
            totalUsage += usage;
          }
          groupLicenseUsedMap[groupName] = totalUsage;
          groupNameTeacherArr.push([groupName, teachers]);
        }
        const sortByLicenseUsedCompare = (grpNameTeacher1, grpNameTeacher2) => {
          return groupLicenseUsedMap[grpNameTeacher1[0]] > groupLicenseUsedMap[grpNameTeacher2[0]] ? -1 : 1;
        }
        groupNameTeacherArr.sort(sortByLicenseUsedCompare);

        // sort teachers inside a group based on license usage
        for (const groupNameTeachers of groupNameTeacherArr) {
          const teachers = groupNameTeachers[1];
          teachers.sort((teacher1, teacher2) => {
            const t1Usage = teacher1?.stats?.licenses?.usage?.used || 0;
            const t2Usage = teacher2?.stats?.licenses?.usage?.used || 0;
            return t1Usage > t2Usage ? -1 : 1;
          });
        }
        return groupNameTeacherArr;
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
        v-for="groupedAdminTeachers in sortedGroupedAdministratedTeachers"
        :key="groupedAdminTeachers[0]"
        class="teacher-list"
      >
        <li class="group-title">
          <!-- Get name from teachers array since key is lowercased for matching -->
          <span v-if="groupedAdminTeachers[1][0]._trialRequest && groupedAdminTeachers[1][0]._trialRequest.organization">
            {{ groupedAdminTeachers[1][0]._trialRequest.organization }}
          </span>
          <span v-else>
            {{ $t('school_administrator.other') }}
          </span>
        </li>

        <teacher-row-component
          v-for="teacher in groupedAdminTeachers[1]"
          :key="teacher._id"
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
