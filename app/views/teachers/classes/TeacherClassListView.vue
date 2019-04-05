<style scoped>
    ul.teacher-list {
        margin: 0;
        padding: 0;
    }
</style>

<template>
    <div>
        <breadcrumbs v-bind:links="links"></breadcrumbs>
        <ul class="teacher-list">
            <classroom-list-row
                    v-for="classroom in activeClassrooms"
                    :key="classroom._id"
                    :classroom="classroom">
            </classroom-list-row>
        </ul>
    </div>
</template>

<script>
  import ClassroomListRow from './ClassroomListRow'
  import Breadcrumbs from '../../common/BreadcrumbComponent'

  export default {
    components: {
      'classroom-list-row': ClassroomListRow,
      Breadcrumbs
    },

    props: {
      activeClassrooms: Array
    },

    data: () => ({
      links: [{
        href: '/school-admin',
        i18n: 'school_administrator.my_teachers'
      }]
    })
  }
</script>

