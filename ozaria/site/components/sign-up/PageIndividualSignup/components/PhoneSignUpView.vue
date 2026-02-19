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
        :class="{ 'has-error': $v.phone.$error }"
      >
        <span class="inline-flex-form-label-div">
          <span class="control-label">{{ $t('teachers_quote.phone_number') }}</span>
          <span
            v-if="!$v.phone.required"
            class="form-error"
          >{{ $t(validationMessages.errorRequired.i18n) }}</span>
          <span
            v-else-if="!$v.phone.uniquePhone"
            class="form-error"
          >{{ $t(validationMessages.errorPhoneExists.i18n) }}</span>
        </span>
        <input
          v-model="$v.phone.$model"
          name="phone"
          class="form-control"
          type="tel"
        >
      </div>
      <div
        class="form-group"
        :class="{ 'has-error': $v.phoneCode.$error }"
      >
        <span class="inline-flex-form-label-div">
          <div>
            <span class="control-label">{{ $t('signup.phone_code') }}</span>
            <CTAButton
              class="sendCode"
              size="small"
              @clickedCTA="sendCode"
            >
              {{ sendSMSText }}
            </CTAButton>
          </div>
          <span
            v-if="!$v.phoneCode.required"
            class="form-error"
          >{{ $t(validationMessages.errorRequired.i18n) }}</span>
        </span>
        <input
          v-model="$v.phoneCode.$model"
          name="phoneCode"
          class="form-control"
          type="text"
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
import { phoneValidations, validationMessages } from '../../PageEducatorSignup/common/signUpValidations'
import CTAButton from 'app/components/common/buttons/CTAButton.vue'
import api from 'core/api'
const User = require('models/User')
export default {
  name: 'PhoneSignUpView',
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
      phone: '',
      phoneCode: '',
      birthday: '',
      name: '',
      password: '',
      validationMessages,
      codeSent: false,
      countDown: 60,
    }
  },
  validations: phoneValidations,
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
    sendSMSText () {
      if (this.codeSent) {
        return $.i18n.t('signup.resend_phone_code', { countDown: this.countDown })
      } else {
        return $.i18n.t('signup.send_phone_code')
      }
    },
  },
  created () {
    if (!me.isAnonymous()) {
      this.$emit('next')
    }
  },
  methods: {
    startCountDown () {
      if (this.countDown > 0) {
        this.countDown -= 1
        setTimeout(this.startCountDown, 1000)
      } else {
        this.codeSent = false
        this.countDown = 60
      }
    },
    async sendCode () {
      if (this.codeSent) {
        return
      }
      if (!this.phone) {
        return
      }
      this.codeSent = true
      this.countDown = 60
      this.startCountDown()
      try {
        await api.sms.sendSMSRegister({
          json: {
            phone: this.phone,
          },
        })
      } catch (e) {
        this.countDown = 0
        this.codeSent = false
      }
    },
    async checkPhone (phone) {
      if (phone) {
        const { exists } = await User.checkPhoneExists(phone)
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
        await me.signupWithPhone(this.name, this.phone, this.phoneCode, this.password)
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
  },
}
</script>

<style scoped lang="scss">
@import "app/styles/component_variables.scss";

.sign-up-view {
  width: 100%;
  margin: 0 auto;
  display: flex;
  flex-direction: column;
  align-items: center;
  font-size: 1.6rem;

  .fake-form {
    width: 70vw;
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
    font-size: 2.2rem;
  }
  .form-error {
    float: right;
    color: $purple;
    font-size: 1.6rem;
  }
  ::v-deep .form-control {
    font-size: 2.2rem;
    padding: 1.2rem 1.6rem;
    border-radius: 1rem;
  }
  .sendCode {
    display: inline-block;
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
