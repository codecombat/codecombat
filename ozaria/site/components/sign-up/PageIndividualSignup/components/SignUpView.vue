<template>
  <div class="subview sign-up-view">
    <div class="head1">
      {{ $t('account.create_a_free_account') }}
    </div>
    <div class="desc">
      {{ roleDesc }}
    </div>
    <div class="fake-form">
      <div
        class="form-group"
        :class="{ 'has-error': $v.email.$error }"
      >
        <span class="inline-flex-form-label-div">
          <span class="control-label">{{ $t('share_progress_modal.form_label') }}</span>
          <span
            v-if="!$v.email.required"
            class="form-error"
          >{{ $t(validationMessages.errorRequired.i18n) }}</span>
          <span
            v-if="!$v.email.email"
            class="form-error"
          >{{ $t(validationMessages.errorInvalidEmail.i18n) }}</span>
          <span
            v-else-if="!$v.email.uniqueEmail"
            class="form-error"
          >{{ $t(validationMessages.errorEmailExists.i18n) }}</span>
        </span>
        <input
          v-model="$v.email.$model"
          name="email"
          class="form-control"
          type="email"
        >
      </div>
      <div
        class="form-group"
        :class="{ 'has-error': $v.birthday.$error }"
      >
        <span class="inline-flex-form-label-div">
          <span class="control-label">{{ $t('account.date_of_birth') }}</span>
          <span
            v-if="!$v.birthday.required"
            class="form-error"
          >{{ $t(validationMessages.errorRequired.i18n) }}</span>
        </span>
        <input
          v-model="$v.birthday.$model"
          name="birthday"
          class="form-control"
          type="date"
        >
      </div>
      <div
        class="form-group"
        :class="{ 'has-error': $v.name.$error }"
      >
        <span class="inline-flex-form-label-div">
          <span class="control-label">{{ $t('general.username') }}</span>
          <span
            v-if="!$v.name.required"
            class="form-error"
          >{{ $t(validationMessages.errorRequired.i18n) }}</span>
          <span
            v-else-if="!$v.name.uniqueName"
            class="form-error"
          >{{ $t(validationMessages.errorNameExists.i18n) }}</span>
        </span>
        <input
          v-model="$v.name.$model"
          name="username"
          class="form-control"
          type="text"
        >
      </div>

      <div
        class="form-group"
        :class="{ 'has-error': $v.password.$error }"
      >
        <span class="inline-flex-form-label-div">
          <span class="control-label">{{ $t('general.password') }}</span>
          <span
            v-if="!$v.password.required"
            class="form-error"
          >{{ $t(validationMessages.errorRequired.i18n) }}</span>
          <span
            v-else-if="$v.password.$error"
            class="form-error"
          >{{ $t('signup.invalid') }}</span>
        </span>
        <input
          v-model="$v.password.$model"
          name="password"
          class="form-control"
          type="password"
        >
      </div>
    </div>

    <div
      v-if="useSocialSignOn"
      class="or"
    >
      <span class="background" />
      <span class="content">{{ $t('code.or') }}</span>
      <span class="background" />
    </div>
    <div
      v-if="useSocialSignOn"
      class="social-sso"
    >
      <a
        id="google-login-button-priority"
        href="#"
        @click="clickGoogleSignup"
      >
        <img
          src="/images/pages/modal/auth/gplus_sso_button2.png"
          draggable="false"
        >
      </a>
    </div>
    <div class="button">
      <CTAButton
        class="cta"
        size="medium"
        @clickedCTA="startCreate"
      >
        {{ $t('login.sign_up') }}
      </CTAButton>
    </div>
  </div>
</template>

<script>
import { validationMixin } from 'vuelidate'
import { individualValidations, validationMessages } from '../../PageEducatorSignup/common/signUpValidations'
import CTAButton from 'app/components/common/buttons/CTAButton.vue'
import api from 'core/api'
const User = require('models/User')
export default {
  name: 'SignUpView',
  components: {
    CTAButton,
  },
  mixins: [validationMixin],
  props: {
    role: {
      type: String,
      default: 'individual',
    },
  },
  data () {
    return {
      email: '',
      birthday: '',
      name: '',
      password: '',
      validationMessages,
    }
  },
  validations: individualValidations,
  computed: {
    roleDesc () {
      return $.i18n.t(`account.${this.role}_inspiration`)
    },
    useSocialSignOn () {
      return me.useSocialSignOn()
    },
    canCreateAccount () {
      return !this.$v.$invalid
    },
  },
  created () {
    if (!me.isAnonymous()) {
      this.$emit('next')
    }
  },
  methods: {
    async checkEmail (email) {
      if (email) {
        const { exists } = await User.checkEmailExists(email)
        return exists
      }
      return false
    },
    async startCreate () {
      if (!this.canCreateAccount) {
        return
      }
      window.tracker.trackEvent('CreateAccountModal Individual Mobile SignUpView Submit Clicked', { category: 'Individuals' })
      me.set('birthday', this.birthday)

      try {
        await this.createAccount()
        await me.signupWithPassword(this.name, this.email, this.password)
        this.$emit('next')
      } catch (err) {
        console.error('Error creating account', err)
        noty({ type: 'error', text: 'Error creating account' })
      }
    },
    async createAccount () {
      me.addNewUserCommonProperties()
      if (this.role === 'parent') {
        const features = me.get('features') || {}
        features.asRole = this.role
        me.set('features', features)
      }
      me.unset('role')
      try {
        await me.save()
      } catch (err) {
        console.error(err)
        throw err
      }
    },
    async clickGoogleSignup (e) {
      e?.preventDefault()
      try {
        await new Promise((resolve, reject) =>
          application.gplusHandler.loadAPI({
            success: resolve,
            error: reject,
          }))
        application.gplusHandler.connect({
          context: this,
          elementId: 'google-login-button-priority',
          success: (resp = {}) => {
            this.postGoogleLoginClick({ resp })
          },
        })
      } catch (err) {
        console.error('Error in individual signup', err)
      }
    },
    async postGoogleLoginClick ({ resp = {} }) {
      const gplusAttrs = await new Promise((resolve, reject) =>
        application.gplusHandler.loadPerson({
          context: this,
          success: resolve,
          error: reject,
          resp,
        }))
      const { email, firstName, lastName } = gplusAttrs
      try {
        const emailExists = await this.checkEmail(email)
        if (emailExists) {
          noty({ type: 'error', text: $.i18n.t('signup.account_exists') + email })
          return
        }
        const ssoAttrs = _.omit(gplusAttrs, attr => attr === '')
        const attrs = _.assign({}, { ...ssoAttrs, userID: me.id })
        await api.users.signupWithGPlus(attrs)
        me.set('firstName', firstName)
        me.set('lastName', lastName)
        me.set('email', email)
        await this.createAccount()
        window?.tracker?.trackEvent('Google Login in mobile individual signup page', { category: 'Signup', label: 'GPlus' })
        this.$emit('next')
      } catch (err) {
        console.error('Error during Google signup', err)
        noty({ type: 'error', text: 'Error during Google signup' })
      }
    },
  },
}
</script>

<style scoped lang="scss">
@import "app/styles/component_variables.scss";

.sign-up-view {
  width: 100%;
  max-width: 60rem;
  margin: 0 auto;
  display: flex;
  flex-direction: column;
  align-items: center;

  .fake-form {
    width: 90%;
    max-width: 56rem;
    margin-top: 2rem;

    .form-line {
      margin-bottom: 2rem;
    }
    .form-label {
      color: black;
      font-size: 4rem;
    }
  }

  .or {
    margin-top: 1rem;
    margin-bottom: 1rem;
    color: $purple;
    position: relative;
    display: flex;
    align-items: center;
    justify-content: space-around;
    width: 90%;
    font-size: 2rem;
    font-weight: bold;

    .content {
      position: relative;
      z-index: 2;
      width: fit-content;
    }

    .background {
      height: 1px;
      flex-basis: 35%;
      background-color: $purple;
    }
  }
  .social-sso {
    img {
      max-width: 25rem;
    }
  }

  .inline-flex-form-label-div {
    display: flex;
    width: 100%;
    justify-content: space-between;
    margin-bottom: 0.5rem;
    align-items: center;
    flex-wrap: wrap;
  }
  .control-label {
    font-weight: 600;
    font-size: 1.6rem;
  }
  .form-error {
    float: right;
    color: $purple;
    font-size: 1.4rem;
  }
  ::v-deep .form-control {
    font-size: 1.6rem;
    padding: 1.2rem 1.6rem;
    border-radius: 1rem;
  }
}

@media (min-width: $screen-sm-min) {
  .sign-up-view {
    max-width: 70rem;

    .fake-form {
      max-width: 64rem;
    }
  }
}

@media (min-width: $screen-lg-min) {
  .sign-up-view {
    max-width: 85rem;

    .fake-form {
      max-width: 78rem;
    }
  }
}

@media (max-width: $screen-sm-max) {
  .cta {
    margin-top: 1rem;
  }

  .fake-form,
  .or,
  .social-sso {
    width: 100%;
  }

  .social-sso {
    display: flex;
    justify-content: center;
  }
}

.button {
  margin-top: 1rem;
  .cta {
    text-transform: uppercase;
  }
}
</style>
