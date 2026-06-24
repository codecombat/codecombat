<template>
  <div id="page-auth">
    <div class="auth-page-shell">
      <div class="auth-page-card">
        <AuthWelcomeScreen
          v-if="currentScreen === 'welcome'"
          @create-account="goToChooser"
          @class-code="onSelectPlaceholder('classroom')"
          @login="goToLogin"
        />
        <AuthChooserScreen
          v-else-if="currentScreen === 'chooser'"
          @back="goToWelcome"
          @select-path="onSelectPlaceholder"
          @login="goToLogin"
        />
        <AuthLoginScreen
          v-else
          :submitting="submitting"
          :google-loading="googleLoading"
          :error-message="errorMessage"
          @login="submitLogin"
          @google-login="loginWithGoogle"
          @clever-login="loginWithClever"
          @create-account="goToChooser"
        />
      </div>
    </div>
  </div>
</template>

<script>
import AuthWelcomeScreen from './components/AuthWelcomeScreen.vue'
import AuthChooserScreen from './components/AuthChooserScreen.vue'
import AuthLoginScreen from './components/AuthLoginScreen.vue'
const User = require('models/User')
const forms = require('core/forms')
const errors = require('core/errors')
const { me } = require('core/auth')
const { logInWithClever } = require('core/social-handlers/CleverHandler')

export default Vue.extend({
  name: 'PageAuth',
  components: {
    AuthWelcomeScreen,
    AuthChooserScreen,
    AuthLoginScreen,
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
      submitting: false,
      googleLoading: false,
      errorMessage: '',
    }
  },
  computed: {
    currentScreen () {
      if (this.mode === 'login') {
        return 'login'
      }
      return this.screen || 'welcome'
    },
  },
  methods: {
    updateRoute (path, query = {}) {
      if (this.$route.path === path && JSON.stringify(this.$route.query) === JSON.stringify(query)) {
        return
      }
      this.$router.push({ path, query }).catch(() => {})
    },
    goToWelcome () {
      this.errorMessage = ''
      this.updateRoute('/signup')
    },
    goToChooser () {
      this.errorMessage = ''
      this.updateRoute('/signup', { screen: 'chooser' })
    },
    goToLogin () {
      this.errorMessage = ''
      this.updateRoute('/login')
    },
    onSelectPlaceholder (path) {
      const titles = {
        educator: 'Educator path arrives in next slice.',
        parent: 'Parent path arrives in next slice.',
        classroom: 'With a Class path arrives in next slice.',
        individual: 'Solo Learner path arrives in next slice.',
      }
      noty({ text: titles[path] || 'Next step arrives in next slice.', layout: 'topCenter', type: 'info', timeout: 3000, killer: false, dismissQueue: true })
    },
    submitLogin ({ username, password }) {
      this.errorMessage = ''
      this.submitting = true
      return me.loginPasswordUser(username, password, {
        success: () => {
          window.location.href = '/'
        },
        error: (res, jqxhr = {}) => {
          if (jqxhr.status === 404) {
            this.errorMessage = 'We could not find that account.'
          } else if (jqxhr.status === 401) {
            this.errorMessage = 'Incorrect email, username, or password.'
          } else {
            this.errorMessage = 'Log in failed. Please try again.'
            errors.showNotyNetworkError(res, jqxhr)
          }
        },
      }).always(() => {
        this.submitting = false
      })
    },
    loginWithGoogle () {
      this.errorMessage = ''
      this.googleLoading = true
      forms.clearFormAlerts?.($(this.$el))
      return application.gplusHandler.connect({
        context: this,
        success: (resp = {}) => {
          return application.gplusHandler.loadPerson({
            resp,
            context: this,
            success: (gplusAttrs) => {
              const existingUser = new User()
              return existingUser.fetchGPlusUser(gplusAttrs.gplusID, gplusAttrs.email, {
                success: () => {
                  return me.loginGPlusUser(gplusAttrs.gplusID, {
                    success: () => {
                      window.location.href = '/'
                    },
                    error: this.onGoogleLoginError,
                  })
                },
                error: (res, jqxhr) => this.onGoogleLoginError(res, jqxhr),
              })
            },
          })
        },
        error: (err) => {
          this.googleLoading = false
          this.errorMessage = err?.message || 'Google login failed.'
        },
      })
    },
    onGoogleLoginError (res, jqxhr) {
      this.googleLoading = false
      if ((jqxhr?.status === 401) && jqxhr.responseJSON?.errorID === 'individuals-not-supported') {
        this.errorMessage = $.i18n.t('login.individual_users_not_supported')
      } else if (jqxhr?.status === 404) {
        this.errorMessage = 'No CodeCombat account found for that Google login.'
      } else {
        this.errorMessage = 'Google login failed.'
        if (arguments.length) {
          errors.showNotyNetworkError(...arguments)
        }
      }
    },
    loginWithClever () {
      logInWithClever()
    },
  },
})
</script>

<style lang="scss" scoped>
@import "app/styles/component_variables.scss";

#page-auth {
  min-height: 100vh;
  background: linear-gradient(180deg, #f7f8ff 0%, #eef0ff 100%);
}

.auth-page-shell {
  min-height: 100vh;
  padding: 24px 16px 40px;
  display: flex;
  align-items: flex-start;
  justify-content: center;
}

.auth-page-card {
  width: min(100%, 520px);
}

@media screen and (min-width: $screen-md-min) {
  .auth-page-shell {
    padding: 48px 24px 64px;
    align-items: center;
  }

  .auth-page-card {
    width: min(100%, 720px);
  }
}
</style>
