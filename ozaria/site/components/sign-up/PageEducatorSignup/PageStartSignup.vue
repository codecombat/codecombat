<script>
  import { mapMutations, mapGetters } from 'vuex'
  import { validationMessages } from './common/signUpValidations'

  const User = require('models/User')

  export default {

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

      async clickGoogleSignup () {
        try {
          this.errorMessage = ''
          await new Promise((resolve, reject) =>
            application.gplusHandler.loadAPI({
              success: resolve,
              error: reject
            }))
          await new Promise((resolve, reject) =>
            application.gplusHandler.connect({
              context: this,
              success: resolve
            }))
          const gplusAttrs = await new Promise((resolve, reject) =>
            application.gplusHandler.loadPerson({
              context: this,
              success: resolve,
              error: reject
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
            firstName: firstName,
            lastName: lastName,
            email: email
          })
          this.updateTrialRequestProperties({
            firstName: firstName,
            lastName: lastName,
            email: email
          })
        } catch (err) {
          console.error('Error in teacher signup', err)
          this.errorMessage = err.message || 'Error during signup'
          return
        }
        this.$emit('startSignup', 'gplus')
      },

      clickEmailSignup () {
        this.errorMessage = ''
        this.resetState()
        this.$emit('startSignup', 'email')
      }
    }
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
        a(@click="clickGoogleSignup")
          img(src="/images/ozaria/common/google_signin_classroom.png")
        span.error(v-if="errorMessage") {{ $t(errorMessage) }}
      .email-sign-up
        span {{ $t("general.or") }}!{' '}
        a(@click="clickEmailSignup") {{ $t("signup.signup_with_email") }}
    .log-in
      span {{ $t("signup.already_have_account") }}!{'? '}
        a(@click="$emit('signIn')") {{ $t("signup.sign_in") }}
</template>

<style lang="sass" scoped>
@import "ozaria/site/styles/common/variables"
#start-signup-component
  height: 100vh
  display: flex
  flex-flow: column
  justify-content: center
  .start-signup-content
    height: 50%
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
      margin: 15px 0
    .email-sign-up
      color: #0b63bc
  a
    text-decoration: underline
  .error
    display: inline-block
    color: red
  .log-in, .log-in a
    @include font-p-4-paragraph-smallest-gray
</style>
