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
          class="form-control"
          type="email"
        >
      </div>
      <div
        class="form-line"
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
          class="form-control"
          type="date"
        >
      </div>
      <div
        class="form-line"
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
          class="form-control"
          type="text"
        >
      </div>

      <div
        class="form-line"
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
  .fake-form {
    width: 90%;
    margin-top: 5rem;

    .form-line {
      margin-bottom: 2rem;
    }
    .form-label {
      color: black;
      font-size: 4rem;
    }
  }

  .or {
    margin-top: 3rem;
    margin-bottom: 4rem;
    color: $purple;
    position: relative;
    display: flex;
    align-items: center;
    justify-content: space-around;
    width: 90%;

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
    width: 50%;
    img {
      width: 100%;
    }
  }

  .control-label {
    font-weight: 600;
  }
  .form-error {
    float: right;
    color: $purple;
  }
}
@media (min-width: 768px) {
  .button {
    margin-top: 40px;
  }
  .cta {
    ::v-deep .CTA__button {
      width: min(70vw, 560px);
    }
  }
}
@media (max-width: 768px) {
  .cta {
    margin-top: 4rem;
    ::v-deep .CTA__button {
      width: min(70vw, 560px);
      font-size: 5rem;
    }
  }

  .button {
    margin-top: 5rem;
  }
}
</style>