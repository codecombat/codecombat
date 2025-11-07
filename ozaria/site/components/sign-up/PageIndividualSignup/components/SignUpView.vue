<template>
  <div class="subview">
    <div class="head1">
      {{ $t('account.create_a_free_account') }}
    </div>
    <div class="desc">
      {{ roleDesc }}
    </div>
    <div class="form">
      <div
        v-for="input in forms"
        :key="input.key"
        class="form-line"
      >
        <label class="form-label"> {{ input.label }} </label>
        <input
          v-model="input.value"
          class="form-control"
          :type="input.type"
        >
      </div>
    </div>
    <div
      v-if="useSocialSignOn"
      class="or"
    >
      <span class="content">{{ $t('code.or') }}</span>
      <div class="background" />
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
        @clickedCTA="createAccount"
      >
        {{ $t('login.sign_up') }}
      </CTAButton>
    </div>
  </div>
</template>

<script>
import CTAButton from 'app/components/common/buttons/CTAButton.vue'
export default {
  components: {
    CTAButton,
  },
  props: {
    role: {
      type: String,
      default: 'individual',
    },
  },
  data () {
    return {
      forms: [
        { key: 'email', value: '', label: $.i18n.t('share_progress_modal.form_label'), type: 'email' },
        { key: 'birthday', value: '', label: $.i18n.t('account.date_of_birth'), type: 'date' },
        { key: 'username', value: '', label: $.i18n.t('general.username'), type: 'string' },
        { key: 'password', value: '', label: $.i18n.t('general.password'), type: 'password' },
      ],
    }
  },
  computed: {
    roleDesc () {
      return $.i18n.t(`account.${this.role}_inspiration`)
    },
    useSocialSignOn () {
      return true
      /* return me.useSocialSignOn() */
    },
    canCreateAccount () {
      return this.forms.every(f => f.value)
    },
  },
  created () {
    this.clickGoogleSignup()
  },
  methods: {
    async checkEmailAndName () {
      // todo
    },
    async createAccount () {
      if (!this.canCreateAccount) {
        // noty warning?
        return
      }
      window.tracker.trackEvent('CreateAccountModal Individual Mobile SignUpView Submit Clicked', { category: 'Individuals' })
      this.forms.forEach(f => me.set(f.key, f.value))
      // me.set('birthday', this.signupState.get('birthday').toISOString().slice(0, 7))

      try {
        await this.checkEmailAndName()
      } catch (conflictError) {
        // todo
      }
      const emails = _.assign({}, me.get('emails'))
      if (emails.generalNews == null) { emails.generalNews = {} }
      if (me.inEU()) {
        emails.generalNews.enabled = false
        me.set('unsubscribedFromMarketingEmails', true)
      } else {
        emails.generalNews.enabled = !_.isEmpty(this.state.get('checkEmailValue'))
      }
      me.set('emails', emails)
      me.set('features', {
        ...(me.get('features') || {}),
        isNewDashboardActive: true,
      })
      if (this.role === 'parent') {
        me.set('role', this.role)
      } else {
        me.set('role', null)
      }
      await me.save()
      this.$emit('next')
    },
    async clickGoogleSignup (e) {
      e?.preventDefault()
      try {
        this.errorMessage = ''
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
        console.error('Error in teacher signup', err)
        this.errorMessage = err.message || 'Error during signup'
      }
    },

  },
}
</script>

<style scoped lang="scss">
@import "app/styles/component_variables.scss";

.subview {
  .form {
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

  .cta {
    margin-top: 5rem;
    ::v-deep .CTA__button {
      width: 70vw;
      font-size: 5rem;
    }
  }

  .or {
    margin-top: 5rem;
    margin-bottom: 5rem;
    color: $purple;
    position: relative;

    .content {
      position: relative;
      padding: 8px;
      z-index: 2;
      background-color: white;
    }

    .background {
      z-index: 1;
      width: 96vw;
      height: 1px;
      background-color: $purple;
      position: absolute;
      left: -44vw;
      top: 50%;
    }
  }
  .social-sso {
    width: 50vw;
    img {
      width: 100%;
    }
  }
  .button {
    margin-top: 8rem;
  }
}

</style>