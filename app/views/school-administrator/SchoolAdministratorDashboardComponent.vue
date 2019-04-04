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
    import RawJadeComponent from 'views/common/RawJadeComponent'

    import teacherDashboardNavTemplate from 'templates/courses/teacher-dashboard-nav.jade'

    export default {
      data: () => ({
        teacherDashboardNavTemplate
      }),

      components: {
        'raw-jade-component': RawJadeComponent
      }
    }
</script>
