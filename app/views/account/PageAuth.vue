<template>
  <div
    id="page-auth"
    :class="`screen-${currentScreen}`"
  >
    <!-- Desktop Back (upper-left, outside card) -->
    <div
      v-if="canGoBack"
      class="back-desktop"
    >
      <button
        class="back-desktop-btn"
        type="button"
        @click="handleBack"
      >
        ← Back
      </button>
    </div>

    <div class="auth-shell">
      <!-- Mobile X close (inside top-right of card, hidden on desktop) -->
      <button
        class="close-x"
        type="button"
        aria-label="Close"
        @click="handleClose"
      >
        ✕
      </button>

      <AuthWelcomeScreen
        v-if="currentScreen === 'welcome'"
        @create-account="goToChooser"
        @class-code="onSelectPlaceholder('classroom')"
        @login="goToLogin"
      />
      <AuthChooserScreen
        v-else-if="currentScreen === 'chooser'"
        @select-path="handleChooserPath"
        @login="goToLogin"
      />
      <AuthEducatorSignInScreen
        v-else-if="currentScreen === 'educator-signin'"
        @google-signin="educatorLoginWithGoogle"
        @clever-signin="educatorLoginWithClever"
        @schoology-signin="educatorLoginWithSchoology"
        @classlink-signin="educatorLoginWithClassLink"
        @email-signup="goToEducatorCreate"
      />
      <AuthEducatorCreateAccountScreen
        v-else-if="currentScreen === 'educator-create'"
        :submitting="submitting"
        :error-message="errorMessage"
        @submit="submitEducatorCreate"
      />
      <AuthEducatorClassReadyScreen
        v-else-if="currentScreen === 'educator-class-ready'"
        :first-name="educatorForm.firstName"
        :last-name="educatorForm.lastName"
        :class-code="educatorClassCode"
      />
      <AuthBirthdayScreen
        v-else-if="currentScreen === 'birthday'"
        :birthday="birthday"
        @continue="handleBirthdayContinue"
        @under-13="goToCoppa"
      />
      <AuthSoloCreateAccountScreen
        v-else-if="currentScreen === 'create-account'"
        :form="soloCreateForm"
        :submitting="submitting"
        :error-message="errorMessage"
        @update-form="updateSoloCreateForm"
        @submit="submitSoloCreateAccount"
        @google-signup="signupWithGoogle"
        @facebook-signup="signupWithFacebook"
      />
      <AuthCoppaScreen
        v-else-if="currentScreen === 'coppa'"
        :parent-email="parentEmail"
        :submitting="submitting"
        :error-message="errorMessage"
        :success-message="successMessage"
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
        @facebook-login="loginWithFacebook"
        @clever-login="loginWithClever"
        @schoology-login="loginWithSchoology"
        @classlink-login="loginWithClassLink"
        @create-account="goToChooser"
      />
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
import AuthEducatorSignInScreen from './components/AuthEducatorSignInScreen.vue'
import AuthEducatorCreateAccountScreen from './components/AuthEducatorCreateAccountScreen.vue'
import AuthEducatorClassReadyScreen from './components/AuthEducatorClassReadyScreen.vue'
const User = require('models/User')
const forms = require('core/forms')
const errors = require('core/errors')
const contact = require('core/contact')
const utils = require('core/utils')
const { me } = require('core/auth')
const { logInWithClever } = require('core/social-handlers/CleverHandler')
const ClassLinkHandler = require('core/social-handlers/ClassLinkHandler')
const SchoologyHandler = require('core/social-handlers/SchoologyHandler')

export default Vue.extend({
  name: 'PageAuth',
  components: {
    AuthWelcomeScreen,
    AuthChooserScreen,
    AuthBirthdayScreen,
    AuthSoloCreateAccountScreen,
    AuthCoppaScreen,
    AuthLoginScreen,
    AuthEducatorSignInScreen,
    AuthEducatorCreateAccountScreen,
    AuthEducatorClassReadyScreen,
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
      educatorForm: {
        firstName: '',
        lastName: '',
        email: '',
        password: '',
      },
      educatorClassCode: 'FROG-1284',
    }
  },
  computed: {
    currentScreen () {
      if (this.mode === 'login') {
        return 'login'
      }
      return this.screen || 'welcome'
    },
    canGoBack () {
      return true
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
    handleBack () {
      const screen = this.currentScreen
      if (screen === 'chooser') return this.goToWelcome()
      if (screen === 'birthday') return this.goToChooser()
      if (screen === 'create-account') return this.goToBirthday()
      if (screen === 'coppa') return this.goToBirthday()
      if (screen === 'educator-signin') return this.goToChooser()
      if (screen === 'educator-create') return this.goToEducatorSignIn()
      if (screen === 'educator-class-ready') return this.goToChooser()
      // welcome and login are flow entry points — back exits the flow
      return this.handleClose()
    },
    handleClose () {
      window.location.href = '/'
    },
    goToEducatorSignIn () {
      this.resetMessages()
      this.updateRoute('/signup', { screen: 'educator-signin' })
    },
    goToEducatorCreate () {
      this.resetMessages()
      this.updateRoute('/signup', { screen: 'educator-create' })
    },
    goToEducatorClassReady () {
      this.resetMessages()
      this.updateRoute('/signup', { screen: 'educator-class-ready' })
    },
    handleChooserPath (path) {
      if (path === 'individual') {
        return this.goToBirthday()
      }
      if (path === 'educator') {
        return this.goToEducatorSignIn()
      }
      return this.onSelectPlaceholder(path)
    },
    onSelectPlaceholder (path) {
      const titles = {
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
            this.errorMessage = 'Sign up failed. Please try again.'
            errors.showNotyNetworkError(res, jqxhr)
          }
        },
      }).always(() => {
        this.submitting = false
      })
    },
    signupWithGoogle () {
      this.resetMessages()
      noty({ text: 'Google signup coming next pass; use email signup for now.', layout: 'topCenter', type: 'info', timeout: 3500, killer: false, dismissQueue: true })
    },
    signupWithFacebook () {
      this.resetMessages()
      noty({ text: 'Facebook signup coming next pass; use email signup for now.', layout: 'topCenter', type: 'info', timeout: 3500, killer: false, dismissQueue: true })
    },
    loginWithFacebook () {
      this.resetMessages()
      const User = require('models/User')
      return application.facebookHandler.connect({
        context: this,
        success: (response) => {
          return application.facebookHandler.loadPerson({
            context: this,
            success: (facebookAttrs) => {
              const existingUser = new User()
              return existingUser.fetchFacebookUser(facebookAttrs.facebookID, response?.authResponse?.accessToken, {
                success: () => {
                  return me.loginFacebookUser(facebookAttrs.facebookID, response?.authResponse?.accessToken, {
                    success: () => { window.location.href = '/' },
                    error: () => { this.errorMessage = 'Facebook login failed. Check your account.' },
                  })
                },
                error: () => { this.errorMessage = 'No CodeCombat account found for that Facebook login.' },
              })
            },
          })
        },
      })
    },
    loginWithSchoology () {
      this.resetMessages()
      const handler = new SchoologyHandler()
      handler.connect({
        context: this,
        success: () => {
          this.errorMessage = 'No CodeCombat account found for that Schoology login.'
        },
      }).catch((err) => {
        this.errorMessage = err?.message || 'Schoology login failed.'
      })
    },
    loginWithClassLink () {
      this.resetMessages()
      const handler = new ClassLinkHandler()
      handler.connect({
        context: this,
        success: () => {
          this.errorMessage = 'No CodeCombat account found for that ClassLink login.'
        },
      }).catch((err) => {
        this.errorMessage = err?.message || 'ClassLink login failed.'
      })
    },
    submitEducatorCreate ({ firstName, lastName, email, password }) {
      this.resetMessages()
      if (password.length < 4) {
        this.errorMessage = 'Password must be at least 4 characters.'
        return
      }
      this.educatorForm = { firstName, lastName, email, password }
      this.submitting = true
      const name = `${firstName} ${lastName}`.trim()
      return me.signupWithPassword(name, email, password, {
        success: () => {
          // Mark role as teacher after account creation
          me.set('firstName', firstName)
          me.set('lastName', lastName)
          me.set('role', 'teacher')
          me.save({ firstName, lastName, role: 'teacher' })
          this.goToEducatorClassReady()
        },
        error: (res, jqxhr = {}) => {
          const errorID = jqxhr.responseJSON?.errorID
          if (errorID === 'email-exists') {
            this.errorMessage = 'An account already uses that email.'
          } else if (errorID === 'name-exists') {
            this.errorMessage = 'That name is already taken — try adding a middle initial.'
          } else {
            this.errorMessage = 'Sign up failed. Please try again.'
            errors.showNotyNetworkError(res, jqxhr)
          }
        },
      }).always(() => {
        this.submitting = false
      })
    },
    educatorLoginWithGoogle () {
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
                    success: () => { window.location.href = '/teachers/classes' },
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
    educatorLoginWithClever () {
      logInWithClever()
    },
    educatorLoginWithSchoology () {
      this.resetMessages()
      const handler = new SchoologyHandler()
      handler.connect({
        context: this,
        success: () => {
          this.errorMessage = 'No CodeCombat account found for that Schoology login.'
        },
      }).catch((err) => {
        this.errorMessage = err?.message || 'Schoology login failed.'
      })
    },
    educatorLoginWithClassLink () {
      this.resetMessages()
      const handler = new ClassLinkHandler()
      handler.connect({
        context: this,
        success: () => {
          this.errorMessage = 'No CodeCombat account found for that ClassLink login.'
        },
      }).catch((err) => {
        this.errorMessage = err?.message || 'ClassLink login failed.'
      })
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
          this.successMessage = 'Email sent! Your parent needs to finish creating your account.'
        })
        .catch(() => {
          this.errorMessage = 'Could not send that email. Please try again.'
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

/* Hide site chrome when auth route is active */
body.auth-route-standalone #main-nav,
body.auth-route-standalone #site-nav,
body.auth-route-standalone #site-footer,
body.auth-route-standalone #footer,
body.auth-route-standalone #final-footer {
  display: none !important;
}

body.auth-route-standalone #page-container,
body.auth-route-standalone #page-container > .content,
body.auth-route-standalone #site-content-area {
  padding: 0 !important;
  margin: 0 !important;
  height: 100vh !important;
  overflow: hidden !important;
}
</style>

<style lang="scss" scoped>
@import "app/styles/component_variables.scss";

#page-auth {
  position: fixed;
  inset: 0;
  z-index: 100;
  background: linear-gradient(160deg, #f4f5ff 0%, #ece8ff 100%);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 0 16px;
}

/* Desktop Back — outside card, upper-left relative to the card column */
.back-desktop {
  display: none;
}

.close-x {
  position: absolute;
  top: 14px;
  right: 16px;
  z-index: 10;
  width: 32px;
  height: 32px;
  border-radius: 50%;
  border: 0;
  background: rgba(100, 90, 200, 0.08);
  color: #7a65fc;
  font-size: 14px;
  line-height: 1;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
}

.auth-shell {
  position: relative;
  width: 100%;
  max-width: 440px;
}

/* Chooser gets wider on desktop only */
#page-auth.screen-chooser .auth-shell {
  max-width: 440px; /* mobile default, overridden on desktop */
}

@media screen and (min-width: $screen-md-min) {
  #page-auth {
    padding: 0 24px;
  }

  .auth-shell {
    max-width: 440px;
  }

  #page-auth.screen-chooser .auth-shell {
    max-width: 720px;
  }

  /* Desktop: hide mobile X, show Back outside card */
  .close-x {
    display: none;
  }

  .back-desktop {
    display: block;
    width: 440px;
    text-align: left;
    margin-bottom: 10px;
  }

  #page-auth.screen-chooser .back-desktop {
    width: 720px;
  }

  .back-desktop-btn {
    appearance: none;
    border: 0;
    background: none;
    color: #6d5df6;
    font-size: 14px;
    font-weight: 700;
    cursor: pointer;
    padding: 0;
  }
}
</style>
