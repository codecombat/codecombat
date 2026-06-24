<template>
  <div class="auth-entry-experiment">
    <PageAuth
      v-if="variant === 'beta'"
      :mode="mode"
      :screen="screen"
    />
    <BackboneModalHarness
      v-else-if="variant === 'control'"
      :modal-view="legacyModalView"
      :modal-options="legacyModalOptions"
      @close="onLegacyModalClose"
    />
  </div>
</template>

<script>
import PageAuth from './PageAuth.vue'
import BackboneModalHarness from '../common/BackboneModalHarness.vue'

const AuthModal = require('views/core/AuthModal')
const CreateAccountModal = require('views/core/CreateAccountModal')
const utils = require('core/utils')
const { me } = require('core/auth')

const AUTH_PAGE_EXPERIMENT = 'standalone-auth-page'

export default Vue.extend({
  name: 'PageAuthExperiment',
  components: {
    PageAuth,
    BackboneModalHarness,
  },
  props: {
    mode: {
      type: String,
      default: 'signup',
    },
    screen: {
      type: String,
      default: null,
    },
  },
  data () {
    return {
      variant: null,
    }
  },
  computed: {
    legacyModalView () {
      return this.mode === 'login' ? AuthModal : CreateAccountModal
    },
    legacyModalOptions () {
      if (this.mode === 'login') {
        return {
          initialValues: {
            email: utils.getQueryVariable('email', ''),
          },
        }
      }

      const signupScreen = this.$route?.query?.screen
      const signupType = this.$route?.query?.type
      let startOnPath = null

      if (signupType === 'individual') {
        startOnPath = 'individual'
      } else if (['birthday', 'create-account', 'coppa'].includes(signupScreen)) {
        startOnPath = 'individual'
      } else if (['class-code', 'class-username', 'class-success'].includes(signupScreen)) {
        startOnPath = 'student'
      } else if (['educator-signin', 'educator-create', 'educator-class-ready'].includes(signupScreen)) {
        startOnPath = 'teacher'
      }

      return startOnPath ? { startOnPath } : {}
    },
  },
  created () {
    this.variant = me.getOrStartStandaloneAuthPageExperimentValue()
    window.tracker?.trackEvent('Auth Entry Experiment Viewed', {
      category: 'Authentication',
      experiment: AUTH_PAGE_EXPERIMENT,
      mode: this.mode,
      route: this.$route?.path,
      variant: this.variant,
    })
  },
  methods: {
    onLegacyModalClose () {
      _.defer(() => {
        const stillOpen = Boolean(document.querySelector('.modal.show, .modal.in, .ozaria-modal'))
        if (!stillOpen && ['/login', '/signup'].includes(this.$route?.path)) {
          this.$router.push({ path: '/' }).catch(() => {})
        }
      })
    },
  },
})
</script>
