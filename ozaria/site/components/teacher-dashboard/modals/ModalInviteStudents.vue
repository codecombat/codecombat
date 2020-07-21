<script>
  import { inviteMembers } from 'core/api/classrooms'
  import SecondaryButton from '../common/buttons/SecondaryButton'
  import TertiaryButton from '../common/buttons/TertiaryButton'

  export default Vue.extend({
    components: {
      SecondaryButton,
      TertiaryButton
    },
    props: {
      classroomCode: {
        type: String,
        default: '',
        required: true
      },
      classroomId: {
        type: String,
        default: '',
        required: true
      }
    },
    data: () => {
      return {
        emails: '',
        recaptchaResponseToken: '',
        recaptchaSiteKey: require('core/services/google').recaptcha_site_key
      }
    },
    mounted () {
      let recaptchaScript = document.createElement('script')
      recaptchaScript.setAttribute('src', 'https://www.google.com/recaptcha/api.js')
      document.head.appendChild(recaptchaScript)

      window.recaptchaCallback = this.recaptchaCallback.bind(this)
    },
    methods: {
      recaptchaCallback (token) {
        this.recaptchaResponseToken = token
      },
      async sendInvitation () {
        let emailList = this.emails.split(/[,\n]/)
        emailList = emailList.map((e) => e.trim()).filter((e) => e.length > 0)
        if (emailList.length === 0) {
          this.$emit('done')
          return
        }
        if (!this.recaptchaResponseToken) {
          console.error('Tried to send student invites via email without recaptcha success token, resetting widget')
          if (window.grecaptcha) {
            window.grecaptcha.reset()
          }
        } else {
          try {
            await inviteMembers({ classroomID: this.classroomId, emails: emailList, recaptchaResponseToken: this.recaptchaResponseToken })
          } catch (e) {
            noty({ type: 'error', text: 'Error in sending invites', layout: 'topCenter', timeout: 2000 })
          }
          this.$emit('done')
        }
      }
    }
  })
</script>

<template>
  <div class="style-ozaria teacher-form">
    <div class="form-container">
      <span class="sub-title"> {{ $t("teachers.invite_modal_sub_title") }} </span>
      <div class="form-group row email-input">
        <div class="col-xs-12">
          <textarea
            v-model="emails"
            class="form-control"
            rows="10"
          />
        </div>
      </div>
      <div class="form-group row">
        <div
          class="col-xs-12 g-recaptcha"
          :data-sitekey="recaptchaSiteKey"
          data-callback="recaptchaCallback"
        />
      </div>
      <div class="form-group row buttons">
        <div class="col-xs-12">
          <tertiary-button
            @click="$emit('back')"
          >
            {{ $t("common.back") }}
          </tertiary-button>
          <secondary-button
            @click="sendInvitation"
          >
            {{ $t("common.done") }}
          </secondary-button>
        </div>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "app/styles/ozaria/_ozaria-style-params.scss";
.teacher-form {
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  margin: 15px 15px 0px 15px;
}
.form-container {
  width: 100%;
  min-width: 600px;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
}
.sub-title {
  @include font-p-2-paragraph-medium-gray;
  line-height: 22px;
  align-self: flex-start;
  margin-left: 15px;
}
.email-input {
  width: 100%;
  margin: 15px;
}
.buttons {
  align-self: flex-end;
  display: flex;
  margin-top: 30px;

  button {
    width: 150px;
    height: 35px;
    margin: 0 10px;
  }
}
</style>
