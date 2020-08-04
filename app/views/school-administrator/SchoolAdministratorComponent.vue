<style scoped>
.container {
  margin-top: 30px;
}
</style>

<template>
    <div>
        <div class="container">
            <router-view></router-view>
        </div>
    </div>
</template>

<script>
    import { mapGetters } from 'vuex'

    export default {
      metaInfo: function () {
        return {
          title: this.$t('school_administrator.title')
        }
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
