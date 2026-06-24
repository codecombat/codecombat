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
          @select-path="handleChooserPath"
          @login="goToLogin"
        />
        <AuthBirthdayScreen
          v-else-if="currentScreen === 'birthday'"
          :birthday="birthday"
          @back="goToChooser"
          @continue="handleBirthdayContinue"
          @under-13="goToCoppa"
        />
        <AuthSoloCreateAccountScreen
          v-else-if="currentScreen === 'create-account'"
          :form="soloCreateForm"
          :submitting="submitting"
          :error-message="errorMessage"
          @back="goToBirthday"
          @update-form="updateSoloCreateForm"
          @submit="submitSoloCreateAccount"
          @google-signup="signupWithGoogle"
        />
        <AuthCoppaScreen
          v-else-if="currentScreen === 'coppa'"
          :parent-email="parentEmail"
          :submitting="submitting"
          :error-message="errorMessage"
          :success-message="successMessage"
          @back="goToBirthday"
          @update:parent-email="updateParentEmail"
          @submit="submitParentEmail"
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
import AuthBirthdayScreen from './components/AuthBirthdayScreen.vue'
import AuthSoloCreateAccountScreen from './components/AuthSoloCreateAccountScreen.vue'
import AuthCoppaScreen from './components/AuthCoppaScreen.vue'
import AuthLoginScreen from './components/AuthLoginScreen.vue'
const User = require('models/User')
const forms = require('core/forms')
const errors = require('core/errors')
const contact = require('core/contact')
const utils = require('core/utils')
const { me } = require('core/auth')
const { logInWithClever } = require('core/social-handlers/CleverHandler')

export default Vue.extend({
  name: 'PageAuth',
  components: {
    AuthWelcomeScreen,
    AuthChooserScreen,
    AuthBirthdayScreen,
    AuthSoloCreateAccountScreen,
    AuthCoppaScreen,
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
      successMessage: '',
      birthday: {
        month: '',
        day: '',
        year: '',
      },
      soloCreateForm: {
        username: '',
        email: '',
        password: '',
      },
      parentEmail: '',
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
  mounted () {
    document.body.classList.add('auth-route-standalone')
  },
  beforeDestroy () {
    document.body.classList.remove('auth-route-standalone')
  },
  methods: {
    updateRoute (path, query = {}) {
      if (this.$route.path === path && JSON.stringify(this.$route.query) === JSON.stringify(query)) {
        return
      }
      this.$router.push({ path, query }).catch(() => {})
    },
    resetMessages () {
      this.errorMessage = ''
      this.successMessage = ''
    },
    goToWelcome () {
      this.resetMessages()
      this.updateRoute('/signup')
    },
    goToChooser () {
      this.resetMessages()
      this.updateRoute('/signup', { screen: 'chooser' })
    },
    goToBirthday () {
      this.resetMessages()
      this.updateRoute('/signup', { screen: 'birthday' })
    },
    goToCreateAccount () {
      this.resetMessages()
      this.updateRoute('/signup', { screen: 'create-account' })
    },
    goToCoppa () {
      this.resetMessages()
      this.updateRoute('/signup', { screen: 'coppa' })
    },
    goToLogin () {
      this.resetMessages()
      this.updateRoute('/login')
    },
    handleChooserPath (path) {
      if (path === 'individual') {
        return this.goToBirthday()
      }
      return this.onSelectPlaceholder(path)
    },
    onSelectPlaceholder (path) {
      const titles = {
        educator: 'Educator path arrives in next slice.',
        parent: 'Parent path arrives in next slice.',
        classroom: 'With a Class path arrives in next slice.',
      }
      noty({ text: titles[path] || 'Next step arrives in next slice.', layout: 'topCenter', type: 'info', timeout: 3000, killer: false, dismissQueue: true })
    },
    handleBirthdayContinue (birthday) {
      this.birthday = { ...birthday }
      const birthDate = new Date(Date.UTC(Number(birthday.year), Number(birthday.month) - 1, Number(birthday.day)))
      const age = (new Date().getTime() - birthDate.getTime()) / 365.4 / 24 / 60 / 60 / 1000
      if (_.isNaN(birthDate.getTime())) {
        this.errorMessage = 'Please complete your birthday.'
        return
      }
      if (age > utils.ageOfConsent(me.get('country'), 13)) {
        this.goToCreateAccount()
      } else {
        this.goToCoppa()
      }
    },
    updateSoloCreateForm (form) {
      this.soloCreateForm = { ...form }
    },
    updateParentEmail (value) {
      this.parentEmail = value
      this.errorMessage = ''
    },
    submitLogin ({ username, password }) {
      this.resetMessages()
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
    submitSoloCreateAccount ({ username, email, password }) {
      this.resetMessages()
      if (password.length < 8) {
        this.errorMessage = 'Use at least 8 characters for your password.'
        return
      }
      this.submitting = true
      return me.signupWithPassword(username, email, password, {
        success: () => {
          window.location.href = '/'
        },
        error: (res, jqxhr = {}) => {
          const errorID = jqxhr.responseJSON?.errorID
          if (errorID === 'email-exists') {
            this.errorMessage = 'An account already uses that email.'
          } else if (errorID === 'name-exists') {
            this.errorMessage = 'That username is already taken.'
          } else {
            this.errorMessage = 'Create account is not fully wired yet. Please try again.'
            errors.showNotyNetworkError(res, jqxhr)
          }
        },
      }).always(() => {
        this.submitting = false
      })
    },
    signupWithGoogle () {
      this.resetMessages()
      noty({ text: 'Google signup wiring is next pass; password signup is live now.', layout: 'topCenter', type: 'info', timeout: 3500, killer: false, dismissQueue: true })
    },
    submitParentEmail (email) {
      this.resetMessages()
      if (!(email && forms.validateEmail(email)) || /team@codecombat.com/i.test(email)) {
        this.errorMessage = 'Enter a valid parent email.'
        return
      }
      this.submitting = true
      this.parentEmail = email
      return contact.sendParentSignupInstructions(email)
        .then(() => {
          this.successMessage = 'Check your parent\'s inbox. They need to finish creating your account before you can save progress.'
        })
        .catch(() => {
          this.errorMessage = 'We could not send that email yet. Please try again.'
        })
        .finally(() => {
          this.submitting = false
        })
    },
    loginWithGoogle () {
      this.resetMessages()
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

<style lang="scss">
@import "app/styles/component_variables.scss";

body.auth-route-standalone #main-nav,
body.auth-route-standalone #site-nav,
body.auth-route-standalone #site-footer,
body.auth-route-standalone #footer,
body.auth-route-standalone #final-footer {
  display: none !important;
}

body.auth-route-standalone #page-container,
body.auth-route-standalone #page-container > .content {
  padding-top: 0 !important;
}
</style>

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
    padding: 64px 24px 88px;
    align-items: center;
  }

  .auth-page-card {
    width: min(100%, 520px);
  }
}
</style>
