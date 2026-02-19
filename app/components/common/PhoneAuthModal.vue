<template>
  <div>
    <base-game-modal @close="$emit('close')">
      <template #header>
        <img
          src="/images/pages/play/modal/subscribe-background-blank.png"
          class="background"
        >
        <div class="board-title">
          开始冒险
        </div>
      </template>
      <template #body>
        <div class="tabs">
          <div
            id="tab-sms"
            class="tab-item"
            :class="{active: tab === 'sms'}"
            @click="switchTab('sms')"
          >
            短信登录
          </div>
          <div
            id="tab-pwd"
            class="tab-item"
            :class="{active: tab === 'pwd'}"
            @click="switchTab('pwd')"
          >
            密码登录
          </div>
        </div>

        <div
          v-if="tab === 'sms'"
          id="form-sms"
          class="form-area"
        >
          <div class="input-group">
            <span class="prefix">+86</span>
            <input
              v-model="phone"
              type="tel"
              class="game-input input-phone"
              placeholder="请输入手机号"
              maxlength="11"
              @blur="notifyIfPhoneError"
            >
          </div>

          <div class="input-group">
            <input
              v-model="phoneCode"
              type="text"
              class="game-input"
              :class="{ showError: phoneCodeError}"
              :placeholder="phoneCodePH"
              maxlength="6"
            >
            <button
              class="verify-btn"
              :disabled="!(phoneExistsCheckCompleted && phoneNumberValid) || codeSent"
              @click="sendCode"
            >
              {{ sendSMSText }}
            </button>
          </div>

          <div class="agreement">
            <input
              id="agree-sms"
              v-model="smsAgreed"
              type="checkbox"
            >
            <label for="agree-sms">
              已阅读并同意 <a
                href="codecombat_user_agreement.html"
                target="_blank"
              >用户协议</a> 与 <a
                href="codecombat_privacy_policy.html"
                target="_blank"
              >隐私政策</a>，未注册手机号验证通过后将自动创建账号
            </label>
          </div>
        </div>

        <div
          v-if="tab === 'pwd'"
          id="form-pwd"
          class="form-area"
        >
          <div class="input-group">
            <input
              v-model="username"
              type="text"
              class="game-input"
              :class="{ showError: usernameError}"
              :placeholder="usernamePH"
            >
          </div>

          <div class="input-group">
            <input
              v-model="password"
              type="password"
              class="game-input"
              :class="{ showError: passwordError}"
              :placeholder="passwordPH"
            >
          </div>

          <div class="agreement">
            <input
              id="agree-pwd"
              v-model="pwdAgreed"
              type="checkbox"
            >
            <label for="agree-pwd">
              已阅读并同意 <a
                href="codecombat_user_agreement.html"
                target="_blank"
              >用户协议</a> 与 <a
                href="codecombat_privacy_policy.html"
                target="_blank"
              >隐私政策</a>
            </label>
          </div>
        </div>

        <button
          class="btn-game-submit"
          :disabled="!formValid"
          @click="submit"
        >
          登录
        </button>
      </template>
      <template #footer>
        <div class="footer-links">
          <a
            v-if="tab === 'pwd'"
            href="javascript:void()"
            @click="forgetPassword"
          >忘记密码?</a>
          <a
            href="codecombat_faq.html"
            target="_blank"
          >遇到问题?</a>
        </div>
      </template>
    </base-game-modal>
    <backbone-modal-harness
      :modal-view="RecoverModal"
      :open="isRecoverModalOpen"
      @close="isRecoverModalOpen = false"
    />
  </div>
</template>
<script>
import BaseGameModal from 'app/components/common/BaseGameModal'
import BackboneModalHarness from 'app/views/common/BackboneModalHarness.vue'

import api from 'core/api'

import { uniquePhone } from 'ozaria/site/components/sign-up/PageEducatorSignup/common/signUpValidations'
import { randomName } from 'app/lib/random-name-utils'

const RecoverModal = require('views/core/RecoverModal')

export default {
  components: {
    BaseGameModal,
    BackboneModalHarness,
  },
  inject: ['openLegacyModal'],
  data () {
    return {
      RecoverModal,
      isRecoverModalOpen: false,
      tab: 'sms',
      phone: '',
      phoneCode: '',
      phoneExists: false,
      phoneExistsCheckCompleted: false,
      username: '',
      password: '',
      codeSent: false,
      countDown: 60,
      phoneCodePH: '请输入 6 位验证码',
      usernamePH: '请输入用户名 / 邮箱 / 手机号',
      passwordPH: '请输入密码',
      phoneCodeError: false,
      usernameError: false,
      passwordError: false,
      smsAgreed: true,
      pwdAgreed: true,
    }
  },
  computed: {
    sendSMSText () {
      if (this.codeSent) {
        return $.i18n.t('signup.resend_phone_code', { countDown: this.countDown })
      } else {
        return $.i18n.t('signup.send_phone_code')
      }
    },
    phoneNumberValid () {
      // simple chinese phone regex
      return /^1\d{10}/.test(this.phone)
    },
    formValid () {
      return (this.tab === 'sms' && this.phone && this.phoneNumberValid && this.phoneCode) ||
        (this.tab === 'pwd' && this.username && this.password)
    },
  },
  watch: {
    phone (newVal) {
      if (this.phoneNumberValid) {
        this.phoneExistsCheckCompleted = false
        uniquePhone(newVal).then(unique => {
          this.phoneExists = !unique
          this.phoneExistsCheckCompleted = true
        })
      }
    },
  },
  methods: {
    switchTab (tab) {
      this.tab = tab
    },
    notifyIfPhoneError () {
      if (this.phone && !this.phoneNumberValid) {
        noty({
          type: 'warning',
          text: '手机号格式错误',
          layout: 'center',
        })
      }
    },
    login () {
      let username = this.username
      let password = this.password
      if (this.tab === 'sms') {
        username = this.phone
        password = this.phoneCode
      }
      const originalPHusername = this.usernamePH
      const originalPHpassword = this.passwordPH
      const originalPHphonecode = this.phoneCodePH
      return new Promise(me.loginPasswordUser(username, password).then)
        .catch(jqxhr => {
          if (jqxhr.status === 401) {
            const {
              errorID,
            } = jqxhr.responseJSON
            if (errorID === 'not-found') {
              this.usernamePH = $.i18n.t('loading_error.user_not_found')
              this.usernameError = true
              this.username = ''
            }
            if (errorID === 'wrong-password') {
              if (this.tab === 'sms') {
                this.phoneCodeError = true
                this.phoneCodePH = $.i18n.t('loading_error.phone_code_error')
                this.phoneCode = ''
              } else {
                this.passwordError = true
                this.passwordPH = $.i18n.t('account_settings.wrong_password')
                this.password = ''
              }
            }
          } else if (jqxhr.status === 429) {
            this.usernameError = true
            this.usernamePH = $.i18n.t('loading_error.too_many_login_failures')
            this.username = ''
          }
        })
        .then(() => {
          application.tracker.identifyAfterNextPageLoad()
          return application.tracker.identify()
        })
        .finally(() => {
          if (!(this.usernameError || this.passwordError || this.phoneCodeError)) {
            if (window.nextURL) {
              window.location.href = window.nextURL
              return
            } else {
              this.$emit('close')
            }
          }
          setTimeout(() => {
            this.passwordError = this.usernameError = this.phoneCodeError = false
            this.passwordPH = originalPHpassword
            this.usernamePH = originalPHusername
            this.phoneCodePH = originalPHphonecode
          }, 3000)
        })
    },
    async phoneRegister () {
      window.tracker.trackEvent('PhoneAuthModal Submit Clicked', { category: 'Individuals' })
      try {
        me.addNewUserCommonProperties()
        me.unset('role')
        await me.save()
        const name = randomName()
        await me.signupWithPhone(name, this.phone, this.phoneCode, undefined)
        this.$emit('close')
      } catch (err) {
        console.error('Error creating account', err)
        noty({ type: 'error', text: 'Error creating account' })
      }
    },
    async submit () {
      if ((this.tab === 'sms' && !this.smsAgreed) || !this.pwdAgreed) {
        return noty({
          type: 'warning',
          text: '请阅读并同意用户协议与隐私政策',
          layout: 'center',
        })
      }
      if (this.tab === 'sms') {
        if (!this.phoneExists) {
          return await this.phoneRegister()
        }
      }
      await this.login()
    },
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
      let method = api.sms.sendSMSRegister
      if (this.phoneExists) {
        method = api.sms.sendSMSLogin
      }
      this.codeSent = true
      this.countDown = 60
      this.startCountDown()
      try {
        await method({
          json: {
            phone: this.phone,
          },
        })
      } catch (e) {
        this.countDown = 0
        this.codeSent = false
      }
    },
    forgetPassword () {
      if (this.openLegacyModal) {
        this.isRecoverModalOpen = true
      } else {
        this.$emit('open-recover-modal')
      }
    },
  },
}
</script>
<style scoped lang="scss">
.board-title {
    font-size: 32px; color: #ffc107;
    text-shadow: 2px 2px 0px #000, 0 0 10px rgba(255, 193, 7, 0.5);
    font-weight: 900; letter-spacing: 2px;
    margin-top: 30px;
}

.tabs {
    display: flex; width: 100%;
    margin-bottom: 25px; margin-top: 0px;
    border-bottom: 2px solid rgba(0,0,0,0.1);
}
.tab-item {
    flex: 1; text-align: center; padding: 10px; cursor: pointer;
    font-size: 18px; font-weight: bold; color: #5d4037; opacity: 0.6;
    transition: all 0.2s; border-bottom: 4px solid transparent;
}

/* 修改：Tab激活状态文字改回深褐色 #3e2723 */
.tab-item.active { opacity: 1; color: #3e2723; border-bottom: 4px solid #f2be22; }

/* 修改：表单区域增加左右内边距 */
.form-area {
    width: 100%;
    padding: 0 40px; /* 增加左右间隙 */
}
.input-group { position: relative; margin-bottom: 15px; display: flex; align-items: center; }

/* 修改：输入框边框加深加粗 */
.game-input {
    width: 100%; height: 50px; background-color: rgba(255, 255, 255, 0.9);
    border: 3px solid #2d3436; /* 深黑色边框 */
    border-radius: 8px; padding: 0 15px;
    font-size: 16px; color: #333; outline: none;
    box-shadow: inset 0 2px 5px rgba(0,0,0,0.1); transition: border-color 0.2s;
}
.game-input:focus { border-color: #ff9800; background-color: #fff; }

.prefix {
    position: absolute; left: 15px; font-weight: bold; color: #333;
    border-right: 1px solid #ccc; padding-right: 10px; height: 24px; line-height: 24px; top: 13px;
}
.input-phone { padding-left: 70px; }

.verify-btn {
    position: absolute; right: 5px; top: 5px; height: 40px; border: none;
    background: transparent; color: #2196F3; font-weight: bold; cursor: pointer;
    padding: 0 10px; font-size: 14px;
}
.verify-btn:disabled { color: #999; cursor: not-allowed; }

.agreement {
    display: flex; align-items: center; font-size: 12px; color: #5d4037;
    margin-bottom: 25px; line-height: 1.4;
}
.agreement input { margin-right: 8px; width: 16px; height: 16px; accent-color: #4CAF50; flex-shrink: 0; }
.agreement a { color: #2196F3; text-decoration: none; font-weight: bold; margin: 0 2px; }

/* 修改：登录按钮改为绿色 */
.btn-game-submit {
    width: 100%; height: 60px;
    background: linear-gradient(180deg, #2ecc71 0%, #27ae60 100%);
    border: 2px solid #1e824c; border-bottom: 6px solid #1e824c;
    border-radius: 8px; color: #ffffff;
    font-size: 24px; font-weight: 900;
    cursor: pointer; transition: all 0.1s;
    display: flex; justify-content: center; align-items: center;
    text-shadow: 0 2px 0 rgba(0,0,0,0.2);
}
.btn-game-submit:active { transform: translateY(4px); border-bottom: 2px solid #1e824c; }
.btn-game-submit:hover { filter: brightness(1.1); }
/* Disabled state styles */
.btn-game-submit:disabled,
.btn-game-submit.disabled {
    background: #bdc3c7; /* A neutral grey */
    border-color: #95a5a6;
    border-bottom: 2px solid #95a5a6; /* Flatten the button */
    color: #ecf0f1;
    cursor: not-allowed; /* Shows the "no" symbol */
    filter: none; /* Removes the hover brightness effect */
    transform: translateY(4px); /* Keeps it in the "pressed" position */
    text-shadow: none;
    pointer-events: none; /* Ensures no clicks or hover effects trigger */
}

/* 底部链接横向排列样式 - 深咖啡色 */
.footer-links {
    margin-top: 20px; font-size: 14px;
    color: #bdc3c7;
    font-weight: bold;
    text-align: center;
    display: flex; justify-content: center; gap: 40px;
}
/* 更新：确保 a 标签继承颜色并去掉下划线，保持虚线边框 */
.footer-links span, .footer-links a {
    cursor: pointer;
    border-bottom: 1px dashed #5d4037;
    color: inherit;
    text-decoration: none;
}
.background-img {
    position: absolute;
    top: -61px;
    left: 0;
}
input.showError::placeholder {
    color: #c73622;
}
</style>