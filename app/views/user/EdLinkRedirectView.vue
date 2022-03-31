<template>
  <div class="text-center ed-link-redirect">
    <div v-if="loggedIn" class="success">
      Logged in, redirecting...
    </div>
    <div v-else-if="!code" class="error">
      Login failed on LMS
    </div>
    <div v-else-if="cocoLoginFailed" class="error">
      Login failed on CodeCombat, please contact support@codecombat.com
    </div>
    <div v-else>
      Logging you into CodeCombat....
    </div>
  </div>
</template>

<script>
export default {
  name: 'EdLinkRedirectView',
  props: {
    code: {
      type: String
    }
  },
  data () {
    return {
      loggedIn: false,
      cocoLoginFailed: false
    }
  },
  async created () {
    try {
      const resp = await me.loginEdLinkUser(this.code)
      console.log('edLink resp', resp)
      this.loggedIn = true
    } catch (err) {
      console.error('edLink login failed', err)
      this.cocoLoginFailed = true
      return
    }
    window.location = '/teachers/classes'
  }
}
</script>

<style scoped lang="scss">
.ed-link-redirect {
  padding: 50px;
}
.error {
  color: red;
}
.success {
  color: green;
}
</style>
