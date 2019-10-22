<style scoped>
</style>

<template>
    <div>
        <raw-pug-component :pug="teacherDashboardNavTemplate"></raw-pug-component>
        <div class="container">
            <router-view></router-view>
        </div>
    </div>
</template>

<script>
    import { mapGetters } from 'vuex'

    import RawPugComponent from 'app/views/common/RawPugComponent'
    import teacherDashboardNavTemplate from 'templates/courses/teacher-dashboard-nav.jade'

    export default {
      metaInfo: function () {
        return {
          title: this.$t('school_administrator.title')
        }
      },

      data: () => ({ teacherDashboardNavTemplate }),

      components: {
        'raw-pug-component': RawPugComponent
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
