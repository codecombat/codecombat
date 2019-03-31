<style scope>

</style>

<template>
    <h3 v-if="loading.teacher || loading.classrooms">{{ $t('common.loading') }}</h3>
    <div v-else>
        <h4>{{ teacher.get('firstName') }} {{ teacher.get('lastName') }}'s {{ $t('classes') }}</h4> <!-- TODO apply i18n to possessive -->
    </div>
</template>

<script>
  import { mapActions, mapState } from 'vuex'

  export default {
    created() {
      this.fetchTeacher(this.$route.params.id)
      this.fetchTeacherClassrooms(this.$route.params.id)
    },

    computed: mapState('schoolAdministrator', [
      'loading',
      'administratedTeachers',
      'teacher'
    ]),

    methods: mapActions({
      fetchTeacher: 'schoolAdministrator/fetchTeacher',
      fetchTeacherClassrooms: 'schoolAdministrator/fetchTeacherClassrooms'
    }),
  }
</script>
