<style scoped>
    h1 {
        color: blue;
    }

    .teacher-list {
        margin: 0;
        margin-top: 15px;

        padding: 0;
    }
</style>

<template>
    <div class="container">
        <h2>{{ $t('school_administrator.my_teachers') }}</h2>

        <h3 v-if="loading">{{ $t('common.loading') }}</h3>
        <div class="content" v-if="!loading">
            <ul class="teacher-list">
                <teacher-row v-for="teacher in administratedTeachers" :teacher="teacher" />
            </ul>
        </div>
    </div>
</template>

<script>
    import { mapActions, mapState } from 'vuex'
    import DashboardTeacherRow from './DashboardTeacherRow'

    export default {
      created() {
        this.fetch()
      },

      computed: mapState('schoolAdministrator', [
        'loading',
        'administratedTeachers'
      ]),

      methods: mapActions({
        fetch: 'schoolAdministrator/fetch'
      }),

      components: {
        'teacher-row': DashboardTeacherRow
      }
    }
</script>
