<script>
import { mapMutations, mapGetters } from 'vuex'
import { validationMessages } from './common/signUpValidations'
import { logInWithClever } from 'core/social-handlers/CleverHandler'

const User = require('models/User')

export default {
  metaInfo: {
    meta: [{ vmid: 'viewport', name: 'viewport', content: 'width=device-width, initial-scale=1, viewport-fit=cover' }]
  },

  data: () => ({
    validationMessages,
    errorMessage: ''
  }),

  computed: {
    ...mapGetters({
      getSsoUsed: 'teacherSignup/getSsoUsed'
    }),
    useSocialSignOn () {
      return me.useSocialSignOn()
    }
  },
  created () {
    this.clickGoogleSignup()
  },
  methods: {
    ...mapMutations({
      updateSso: 'teacherSignup/updateSso',
      updateSignupForm: 'teacherSignup/updateSignupForm',
      updateTrialRequestProperties: 'teacherSignup/updateTrialRequestProperties',
      resetState: 'teacherSignup/resetState'
    }),

    async checkEmail (email) {
      if (email) {
        const { exists } = await User.checkEmailExists(email)
        return exists
      }
      return false
    },
    async clickGoogleSignup (e) {
      e?.preventDefault()
      try {
        this.errorMessage = ''
        await new Promise((resolve, reject) =>
          application.gplusHandler.loadAPI({
            success: resolve,
            error: reject
          }))
        application.gplusHandler.connect({
          context: this,
          elementId: 'google-login-button-priority',
          success: (resp = {}) => {
            this.postGoogleLoginClick({ resp })
          }
        })
      } catch (err) {
        console.error('Error in teacher signup', err)
        this.errorMessage = err.message || 'Error during signup'
      }
    },

    async postGoogleLoginClick ({ resp = {} }) {
      const gplusAttrs = await new Promise((resolve, reject) =>
        application.gplusHandler.loadPerson({
          context: this,
          success: resolve,
          error: reject,
          resp
        }))
      const { email, firstName, lastName } = gplusAttrs
      const emailExists = await this.checkEmail(email)
      if (emailExists) {
        this.errorMessage = this.validationMessages.errorEmailExists.i18n
        return
      }
      this.resetState()
      this.updateSso({
        ssoUsed: 'gplus',
        ssoAttrs: gplusAttrs
      })
      this.updateSignupForm({
        firstName,
        lastName,
        email
      })
      this.updateTrialRequestProperties({
        firstName,
        lastName,
        email
      })
      this.$emit('startSignup', 'gplus')
    },

    clickEmailSignup (e) {
      e.preventDefault()
      this.errorMessage = ''
      this.resetState()
      this.$emit('startSignup', 'email')
    },

    clickCleverSignup () {
      logInWithClever()
    },
    async clickClasslinkSignup () {
      console.log('clickClasslinkSignup')
      const handler = application.classlinkHandler
      const { loggedIn, email, firstName, lastName } = await handler.logInWithEdlink()
      if (!loggedIn) {
        this.resetState()
        this.updateSso({
          ssoUsed: 'classlink',
          ssoAttrs: { email, firstName, lastName },
        })
        this.updateSignupForm({
          firstName,
          lastName,
          email,
        })
        this.updateTrialRequestProperties({
          firstName,
          lastName,
          email,
        })
        this.$emit('startSignup', 'classlink')
      } else {
        noty({
          text: 'Account already exists, logging you in...',
          type: 'error',
          layout: 'topCenter',
          timeout: 5000,
        })
        setTimeout(() => {
          window.location.href = '/'
        }, 2000)
      }
    },
  },
}
</script>

<template lang="pug">
  #start-signup-component
    .start-signup-content
      h2 {{ $t("signup.create_your_educator_account") }}
      ul.create-account-list
        li
          span.li-title {{ $t("signup.educator_signup_list_1_title") }}!{' '}
          span.li-desc {{ $t("signup.educator_signup_list_1_desc") }}
        li
          span.li-title {{ $t("signup.educator_signup_list_2_title") }}!{' '}
          span.li-desc {{ $t("signup.educator_signup_list_2_desc") }}
        li
          span.li-title {{ $t("signup.educator_signup_list_3_title") }}!{' '}
          span.li-desc {{ $t("signup.educator_signup_list_3_desc") }}
      .social-sign-in(v-if="useSocialSignOn")
        a(@click="clickGoogleSignup" href="#" id="google-login-button-priority")
          img(src="/images/ozaria/common/google_signin_classroom.png")
        a(@click="clickCleverSignup" href="#" id="clever-login-button-priority")
          img(src="/images/pages/modal/auth/clever_sso_button@2x.png")
        a(@click="clickClasslinkSignup" href="#" id="classlink-login-button-priority" class="classlink-login-button")
          img(src="/images/pages/modal/auth/classlink-logo-text.png")
      .error(v-if="errorMessage") {{ $t(errorMessage) }}
      .email-sign-up
        span {{ $t("general.or") }}!{' '}
        a(@click="clickEmailSignup" href="#") {{ $t("signup.signup_with_email") }}
    .log-in
      span {{ $t("signup.already_have_account") }}!{'? '}
        a(@click="$emit('signIn')" href="#") {{ $t("signup.sign_in") }}
</template>

<style lang="sass" scoped>
@import "ozaria/site/styles/common/variables"
#start-signup-component
  height: 100vh
  display: flex
  flex-flow: column
  justify-content: center
  .start-signup-content
    height: 55%
    display: flex
    flex-direction: column
    justify-content: flex-start
    .create-account-list
      margin: 25px 0
      li
        color: #000000
        .li-title
          font-weight: 600
    .social-sign-in
      margin: 5px 0
      display: flex
      justify-content: flex-start
      gap: 10px
      a
        display: inline-block
        max-width: 200px
        height: 40px
        img
          max-width: 200px
          height: 40px
    .email-sign-up
      color: #0b63bc
  a
    text-decoration: underline
  .error
    @include font-p-4-paragraph-smallest-gray
    color: red
  .log-in, .log-in a
    @include font-p-4-paragraph-smallest-gray
  .classlink-login-button
    background-color: #ffffff
</style>
