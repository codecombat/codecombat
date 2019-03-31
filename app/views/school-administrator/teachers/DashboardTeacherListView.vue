<style scoped>
    .teacher-list {
        margin: 0;
        margin-top: 15px;

        padding: 0;
    }
</style>

<template>
    <div>
        <h2>{{ $t('school_administrator.my_teachers') }}</h2>

        <h3 v-if="loading.teachers">{{ $t('common.loading') }}</h3>
        <div v-else class="content">
            <ul class="teacher-list">
                <teacher-row v-for="teacher in administratedTeachers" :key="teacher.id" :teacher="teacher" />
            </ul>
        </div>
    </div>
</template>

<script>
  import { mapActions, mapState } from 'vuex'
  import DashboardTeacherRow from '../dashboard/DashboardTeacherRow'

  export default {
    created() {
      this.fetch()
    },

    computed: mapState('schoolAdministrator', [
      'loading',
      'administratedTeachers'
    ]),

    methods: mapActions({
      fetch: 'schoolAdministrator/fetchTeachers'
    }),

    components: {
      'teacher-row': DashboardTeacherRow
    }
  }
</script>
