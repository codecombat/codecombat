<style scoped>
</style>

<template>
    <div>
        <raw-jade-component :jade="teacherDashboardNavTemplate"></raw-jade-component>
        <div class="container">
            <router-view></router-view>
        </div>
    </div>
</template>

<script>
    import { mapGetters } from 'vuex'

    import RawJadeComponent from 'views/common/RawJadeComponent'
    import teacherDashboardNavTemplate from 'templates/courses/teacher-dashboard-nav.jade'

    export default {
      data: () => ({ teacherDashboardNavTemplate }),

      components: {
        'raw-jade-component': RawJadeComponent
      },

      created: function () {
        if (this.isAnonymous || this.isStudent) {
          return this.$router.replace('/')
        }

        if (!this.isSchoolAdmin) {
          return this.$router.replace('/teacher/classes')
        }
      },

      computed: mapGetters('me', [
        'isSchoolAdmin',
        'isTeacher',
        'isStudent'
      ])
    }
</script>
