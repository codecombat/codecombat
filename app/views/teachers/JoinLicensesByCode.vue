<script>
import { mapActions, mapMutations } from 'vuex'
import { COMPONENT_NAMES, PAGE_TITLES } from 'ozaria/site/components/teacher-dashboard/common/constants.js'
export default {
  name: COMPONENT_NAMES.ACTIVATE_LICENSE,
  data () {
    return {
      state: 'loading',
      result: {},
    }
  },
  mounted () {
    this.setPageTitle(PAGE_TITLES[this.$options.name])
    if (this.$route.query.codes) {
      this.post()
    } else {
      application.router.navigate('/teachers/licenses', { trigger: true })
    }
  },
  methods: {
    ...mapActions({
      joinByCodes: 'prepaids/joinPrepaidByCodes',
    }),
    ...mapMutations({
      setPageTitle: 'teacherDashboard/setPageTitle',
    }),
    post () {
      this.joinByCodes(this.$route.query).then((res) => {
        let state = 'success'
        for (const code in res) {
          if (!res[code] || res[code] !== 'success') {
            state = 'partly-failed'
            break
          }
        }
        this.result = res
        this.state = state

        if (state === 'success') {
          setTimeout(() => {
            application.router.navigate('/teachers/licenses', { trigger: true })
          }, 5000)
        }
      })
    }
  }
}
</script>

<template lang="pug">
  div
    .progress.progress-striped.active(v-if="state === 'loading'")
      .progress-bar(style="width: 100%")
    .alert.alert-success(v-if="state === 'success'") {{ $t('teachers.licenses_activated_success') }}
    .alert.alert-failed(v-if="state === 'partly-failed'")
      .status(v-for="(res, code) in result")
        span.code {{ code }}:
        span.status {{ res }}
</template>

<style scoped>
</style>
