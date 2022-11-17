<script>
  import { mapMutations, mapActions } from 'vuex'
  import LayoutSplit from '../layout/LayoutSplit'
  import CloseModalBar from '../layout/CloseModalBar'
  import { logInWithClever } from 'core/social-handlers/CleverHandler'

  const User = require('models/User')
  export default {
    props: {
      saveProgressModal: {
        type: Boolean,
        default: false
      }
    },
    components: {
      LayoutSplit,
      CloseModalBar
    },
    data: () => ({
      firstName: '',
      lastName: '',
      userName: '',
      password: '',
      ssoUsed: '',
      ssoAttrs: ''
    }),
    mounted () {
      this.setHourOfCode()
    },
    methods: {
      ...mapMutations({
        updateSso: 'studentModal/updateSso',
        updateSignupForm: 'studentModal/updateSignupForm',
        setHourOfCode: 'studentModal/setHourOfCode',
        updateEmail: 'studentModal/updateEmail'
      }),
      ...mapActions({
        createAccount: 'studentModal/createAccount',
        joinClass: 'studentModal/joinClass',
        setHocOptions: 'studentModal/setHocOptions'
      }),
      async onSubmitForm (e) {
        this.updateSignupForm({
          firstName: this.firstName,
          lastName: this.lastName,
          name: this.userName,
          password: this.password
        })
        await this.signUpStudent()
      },
      async googleSignUp () {
        const USER_EXISTS = 'User already exists.'
        try {
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
          const { email } = gplusAttrs
          const { exists } = await User.checkEmailExists(email)
          if (exists) {
            throw new Error(USER_EXISTS)
          } else {
            this.updateEmail({ email: email })
            this.updateSso({
              ssoUsed: 'gplus',
              ssoAttrs: gplusAttrs
            })
          }
        } catch (err) {
          console.error('Error in google sign up', err)
          if (err.message === USER_EXISTS) {
            noty({
              text: this.$t('hoc_2019.err_google_exists'),
              type: 'info',
              layout: 'center',
              buttons: [
                {
                  addClass: 'btn btn-primary', text: 'Ok', onClick: function($noty) {
                  $noty.close();
                }
              }
              ]
            })
          } else {
            noty({ text: err.message || 'Error in sign up', type: 'error', layout: 'center', timeout: 2000 })
          }
          return
        }
        await this.signUpStudent()
      },
      async signUpStudent () {
        try {
          await this.createAccount()
          try {
            await this.joinClass()
          } catch (err) {
            // Set hoc progress options if could not join the class
            await this.setHocOptions()
          }

          // A minor hack to pull down the logged in user details.
          me.fetch({
            success: () => { this.$emit('done') },
            error: () => {
              throw new Error('Fetching created student failed')
            }
          })
          
          return true
        } catch (err) {
          console.log('Error in sign up', err)
          if (err && err.errorName === 'Conflict') {
            noty({
              text: this.$t('hoc_2019.err_username_taken'),
              type: 'info',
              layout: 'center',
              buttons: [
                {
                  addClass: 'btn btn-primary', text: 'Ok', onClick: function($noty) {
                  $noty.close();
                }
              }
              ]
            })
          } else {
            noty({ text: err.message || 'Error in sign up', type: 'error', layout: 'center', timeout: 2000 })
          }
        }
      },
      // TODO: test this to see if progress actually is saved when signing in with Clever this way, or if it leaves student on empty student dashboard
      cleverSignUp () {
        logInWithClever()
      }
    }
  }
</script>

<template>
  <LayoutSplit @back="$emit('back')" :showBackButton="!saveProgressModal">
    <CloseModalBar @click="$emit('closeModal')" style="margin-bottom: -9px;"/>
    <div id="student-signup">
      <div v-if="saveProgressModal" class="text-left">
        <h1>{{$t("hoc_2019.save_progress_modal") + ':'}}</h1>
      </div>
      <form @submit.prevent="onSubmitForm">
        <div class="form-group">
          <label for="firstName">{{$t("general.first_name")}}</label>
          <input
            id="firstName"
            class="ozaria-input-field"
            v-model="firstName"
            type="text"
            required
          >
        </div>
        <div class="form-group">
          <label for="lastName">{{$t("general.last_name")}}</label>
          <input
            id="lastName"
            class="ozaria-input-field"
            v-model="lastName"
            type="text"
            required
          >
        </div>
        <div class="form-group">
          <label for="userName">{{$t("general.username")}}</label>
          <input
            id="userName"
            class="ozaria-input-field"
            v-model="userName"
            type="text"
            required
          >
        </div>
        <div class="form-group">
          <label for="password">{{$t("general.password")}}</label>
          <input
            id="password"
            class="ozaria-input-field"
            v-model="password"
            type="password"
            required
            minlength="4"
          >
        </div>

        <button class="ozaria-btn" type="submit">{{saveProgressModal ? 'Save Progress' : 'Start the Game'}}</button>
      </form>
      <div class="yellow-bar"></div>
      <div class="sso">
        <span id="or">{{$t("general.or")}}</span>
        <a id="google-sso-signup" @click="googleSignUp">
          <img src="/images/ozaria/common/Google Sign Up.png"/>
        </a>
        <a id="clever-sso-signup" @click="cleverSignUp">
          <img src="/images/pages/modal/auth/clever_sso_button@2x.png"/>
        </a>
      </div>
      <a
        v-if="!saveProgressModal"

        class="sign-in"

        @click="$emit('signIn')"
      >
        {{$t("hoc_2019.already_have_account")}}
      </a>
    </div>
  </LayoutSplit>
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

#student-signup {
  width: 590px;
  padding: 0 66px 40px 52px;

  text-align: center;

  h1 {
    color: $pitch;
    font-family: Work Sans;
    font-size: 24px;
    line-height: 32px;
    letter-spacing: 0.48px;
    font-style: normal;

    margin-top: 0;
    margin-bottom: 15px;
  }

  .form-group {
    display: flex;
    align-items: center;
    flex-direction: row;
    justify-content: space-between;

    label {
      margin-bottom: 0;

      font-family: Work Sans;
      font-weight: 400;
      color: $color-tertiary-brand;
      font-size: 18px;
      letter-spacing: 0.2px;
      line-height: 24px;
    }

    .ozaria-input-field {
      height: 36px;
      width: 334px;

      box-sizing: border-box;
      border: 1px solid $dusk;
      border-radius: 2px;
      background-color: #FFFFFF;

      font-family: Work Sans;
      padding-left: 12.5px;
      color: $pitch;
      font-size: 18px;
      line-height: 24px;
      letter-spacing: 0.2px;
    }
  }
  // TODO: Refactor these out to be a standard button across the codebase:
  .ozaria-btn {
    text-shadow: unset;
    font-family: Work Sans, "Open Sans", sans-serif;
    font-size: 20px;
    font-weight: 600;
    letter-spacing: 0.4px;
    line-height: 24px;
    min-height: 60px;
    min-width: 261px;

    color: $pitch;
    background-image: unset;
    background-color: $dusk;
    border: unset;

    margin-top: 10px;
    margin-bottom: 22.5px;

    &:hover {
      background-color: $dusk-dark;
    }
  }
  .yellow-bar {
    position: relative;
    height: 0px;
  }

  .yellow-bar:after {
    content: "";
    position: absolute;
    height: 510px;
    width: 8px;
    /* The transform must be half the height */
    transform: rotate(90deg) translate(-255px, 0px);
    background: linear-gradient(59.61deg, #D1B147 0%, #D1B147 20%, #F7D047 90.4%, #F7D047 100%);
  }

  div.sso {
    display: flex;
    flex-direction: row;
    justify-content: center;
    align-items: center;
    margin-top: 22.5px;
  }

  span#or {
    font-family: Work Sans;
    color: $goldenlight;
    font-size: 28px;
    font-weight: 600;
    letter-spacing: 0.56px;
    line-height: 32px;

    margin-right: 5px;
  }

  #google-sso-signup, #clever-sso-signup {
    img {
      margin-left: 5px;
      height: 40px;
    }
  }

  a.sign-in {
    font-family: Work Sans;
    font-size: 14px;
    color: #0170E9;
    letter-spacing: 0.23px;
    line-height: 18px;
    text-decoration: underline;

    display: block;
    margin-top: 11px;
  }
}
</style>
