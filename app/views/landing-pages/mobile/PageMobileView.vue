<template>
  <div id="page-mobile">
    <div class="page-mobile-container">
      <a v-if="isCodeCombat" href="/"><img class="coco-logo" src="/images/pages/base/logo.png"></a>
      <a v-if="isOzaria" href="/"><img class="ozaria-logo" src="/images/pages/mobile/ozaria-logo.svg"></a>
      <p v-if="activeStep!==STEP_DONE" class="subtitle">{{ $t('mobile_landing.subtitle') }}</p>

      <img v-if="isCodeCombat && activeStep===STEP_DONE" src="/images/pages/mobile/you-re-set.svg" class="title-image"/>
      <h3 v-if="isOzaria && activeStep===STEP_DONE" class="you-re-set">{{ $t('mobile_landing.you_re_set') }}</h3>
      <p v-if="activeStep===STEP_DONE" class="blurb-done">{{ $t('mobile_landing.done_blurb') }}</p>
      <div class="form-container" :class="{'step-done':activeStep===STEP_DONE}">
        <!-- Wrapper for slides -->
        <div v-if="activeStep!==STEP_DONE" class="page-mobile-inner">
          <div class="line" :class="{'step-name':activeStep===STEP_NAME}">
            <img v-if="isCodeCombat" src="/images/pages/mobile/hero1.svg"
                 :class="{'moved-out':activeStep!==STEP_EMAIL}"/>
          </div>
          <div class="input-container text-input-container input-container-email"
               :class="{'moved-out': activeStep!==STEP_EMAIL}">
            <input ref="email" type="email" placeholder="Enter email here" v-model="email" @keyup="onEmailChange"
                   @keyup.enter="emailEntered" @focus="setActiveStep(STEP_EMAIL)" @blur="onEmailBlur"/>
            <template v-if="email">
              <i v-if="checkingEmail" class="small glyphicon glyphicon-refresh mobile-icon-refresh"></i>
              <i v-if="!checkingEmail && isEmailValid && !isEmailAvailable"
                 class="small text-burgundy glyphicon glyphicon-remove-circle"></i>
              <i v-if="!checkingEmail && isEmailValid && isEmailAvailable"
                 class="small text-forest glyphicon glyphicon-ok-circle"></i>
            </template>
          </div>

          <div class="input-container text-input-container input-container-firstname"
               :class="{'moved-out': activeStep!==STEP_NAME}">
            <input ref="firstName" type="text" placeholder="First name" v-model="firstName"
                   @keyup.enter="firstNameEntered" @focus="emailEntered">
          </div>
          <div class="input-container text-input-container input-container-lastname"
               :class="{'moved-out': activeStep!==STEP_NAME}">
            <input ref="lastName" type="text" placeholder="Last name" v-model="lastName"
                   @keyup.enter="lastNameEntered">
          </div>

          <div v-if="activeStep!==STEP_DONE" class="input-container input-container-button"
               :class="{'moved-out': activeStep===STEP_DONE}">
            <img v-if="isCodeCombat" class="hero-2" src="/images/pages/mobile/hero2.png"
                 :class="{'moved-out': activeStep!==0}"/>
            <button @click="setActiveStep(activeStep + 1)" :disabled="nextButtonDisabled">
              <span :class="{hidden: activeStep!==STEP_EMAIL}">START</span>
              <span :class="{hidden: activeStep!==STEP_NAME}">NEXT</span>
            </button>
          </div>
        </div>

        <ol class="carousel-indicators">
          <li :class="{active: activeStep===STEP_EMAIL}" @click="setActiveStep(STEP_EMAIL)">
            <span class="">{{ $t('mobile_landing.step_email') }}</span>
          </li>
          <li :class="{active: activeStep===STEP_NAME}" @click="setActiveStep(STEP_NAME)">
            <span class="">{{ $t('mobile_landing.step_name') }}</span>
          </li>
          <li :class="{active: activeStep===STEP_DONE}">
            <span class="">{{ $t('mobile_landing.step_done') }}</span>
          </li>
        </ol>

        <div class="screenshot-container">
          <h4 v-if="activeStep===STEP_DONE" class="">{{ $t('mobile_landing.video_title') }}</h4>
          <base-cloudflare-video v-if="(isCodeCombat && activeStep===STEP_DONE)"
                                 video-cloudflare-id="100412c840bf03141644c1855784c785" ref="video"/>
          <base-cloudflare-video v-if="(isOzaria && activeStep===STEP_DONE)"
                                 video-cloudflare-id="94e611192ce86d5b4cf6ba2343a53927" ref="video"/>
        </div>
      </div>
    </div>
    <footer>
      <a v-if="isOzaria" href="https://codecombat.com" target="_blank">
        <img class="coco-logo-bottom" src="/images/pages/base/logo.png" :class="{'step-done':activeStep===STEP_DONE}">
      </a>
      <final-footer></final-footer>
    </footer>
  </div>
</template>

<script>
import utils from 'core/utils'
import { mapActions, mapGetters } from 'vuex'
import User from '../../../models/User'
import { register } from 'core/api/mobile'
import { debounce } from 'lodash'
import BaseCloudflareVideo from 'app/components/common/BaseCloudflareVideo'
import FinalFooter from 'app/components/common/FinalFooter'

export default Vue.extend({
  name: 'PageMobileView',
  components: {
    BaseCloudflareVideo,
    FinalFooter
  },
  metaInfo () {
    return {
      title: utils.getProductName(),
      meta: [
        { name: 'viewport', content: 'width=device-width, initial-scale=1' }
      ]
    }
  },

  data () {
    return {
      done: false,
      email: '',
      firstName: '',
      lastName: '',
      isEmailValid: false,
      isEmailAvailable: false,
      checkingEmail: false,
      checkEmailState: null,
      activeStep: 0,
      STEP_EMAIL: 0,
      STEP_NAME: 1,
      STEP_DONE: 2,
      registrationInProgress: false,
      isCodeCombat: utils.isCodeCombat,
      isOzaria: utils.isOzaria
    }
  },

  updated () {
  },

  created () {

  },

  mounted () {
    $('flying-focus').remove() // no need for it, and it mixes focuses.
    this.setAutoFocus()
  },

  computed: {
    ...mapGetters({}),
    nextButtonDisabled () {
      return (
          (this.activeStep === this.STEP_EMAIL && this.email.length > 3 && (!this.isEmailValid || !this.isEmailAvailable)) ||
          (this.activeStep === this.STEP_NAME && (this.firstName.length < 1 || this.lastName.length < 1 || this.registrationInProgress))
      )
    },
    emailCheck () {
      return debounce(this.checkEmail, 500)
    }
  },

  methods: {
    ...mapActions({}),

    onEmailChange () {
      this.isEmailAvailable = false
      this.emailCheck()
    },

    setAutoFocus () {
      const focusMap = {
        [this.STEP_EMAIL]: this.$refs.email,
        [this.STEP_NAME]: this.$refs.firstName
      }

      const element = focusMap[this.activeStep]
      if (element) {
        element.focus()
      }
    },

    setActiveStep (newStep) {
      const oldStep = this.activeStep
      if (!this.onStepChange(newStep, oldStep)) {
        this.setAutoFocus()
        return
      }
      this.activeStep = newStep
      this.onStepChanged(newStep, oldStep)
    },

    onStepChange (newStep, oldStep) {
      if (oldStep === this.STEP_DONE) {
        return false
      }

      if (newStep === this.STEP_NAME) {
        if (!this.isEmailValid || !this.isEmailAvailable || this.checkingEmail) {
          this.checkEmail()
          if (this.isEmailValid && this.checkingEmail) {
            this.emailCheckingPromise.then(() => {
              if (this.isEmailAvailable) {
                this.setActiveStep(newStep)
              }
            })
          }
          return false
        }
      }

      if (newStep === this.STEP_DONE) {
        if (!this.firstName || !this.lastName) {
          return false
        }

        if (!this.registrationSucceeded) {
          this.sendRegistration()
          return false
        }
      }
      return true
    },

    onStepChanged (newStep, oldStep) {
      this.setAutoFocus()
    },

    async checkEmail () {
      this.isEmailValid = utils.isValidEmail(this.email)
      this.isEmailAvailable = false
      if (this.isEmailValid) {
        this.checkingEmail = true
        this.emailCheckingPromise = this.emailChecker()
        await this.emailCheckingPromise
      }
    },

    sendRegistration () {
      this.registrationInProgress = true
      register({
        email: this.email,
        firstName: this.firstName,
        lastName: this.lastName,
        product: utils.getProduct()
      }).then(() => {
        this.registrationSucceeded = true
        this.setActiveStep(this.STEP_DONE)
      }).catch((err) => {
        noty({
          text: 'Failed to contact server: ' + err.message,
          type: 'error'
        })
      }).finally(() => {
        this.registrationInProgress = false
      })
    },

    async emailChecker () {
      this.checkEmailState = 'checking'
      const resp = await User.checkEmailExists(this.email)
      this.checkingEmail = false
      this.isEmailAvailable = !(resp?.exists)
      this.checkEmailState = this.isEmailAvailable ? 'available' : 'exists'
    },

    onEmailBlur () {
      if (!this.isEmailValid) {
        this.setAutoFocus()
        return false
      }
    },

    async emailEntered () {
      this.setActiveStep(this.STEP_NAME)
    },
    async namesEntered () {
      this.setActiveStep(this.STEP_DONE)
    },
    async firstNameEntered () {
      this.$refs.lastName.focus()
    },
    async lastNameEntered () {
      this.namesEntered()
    }
  }
})
</script>

<style lang="scss">
$background-color: #e6fafa;

body {
  background-color: $background-color;
  min-height: 100vh;
}

html {
  // We need this trick for people who open this page on a large screen
  // From now `rem` will be equal to the `vw` with the maximum of 10 pixels
  // If a screen is larger than 1000px of width, the page will be centered.
  font-size: min(1vw, 10px)
}
</style>

<style scoped lang="scss">
@import "app/styles/utils";

$background-color: #e6fafa;
$border-width: 1rem;
$border-color: #ffbf00;
$border-style: dashed;
$navy: #2a4e5b;

@if $is-ozaria {
  $background-color: #ffcf00;
  $border-color: #00e0ff;
  $border-style: dotted;
}

$circle-radius: 2.5rem;

.circle {
  content: ' ';
  background-color: #00e0ff;
  border-color: $navy;
  width: $circle-radius*2;
  height: $circle-radius*2;
  border-radius: $circle-radius;
  border-width: $border-width;
  border-style: solid;
  position: absolute;
}

#page-mobile {
  background: transparent;
  text-align: center;
  min-height: 100vh;
  max-width: 100vw;
  overflow: hidden;
  margin: 0;
  position: relative;
  display: flex;
  flex-direction: column;

  // If a screen is larger than 1000px of width, the page will be centered.
  padding-right: calc((100vw - 100rem) / 2);
  padding-left: calc((100vw - 100rem) / 2);

  @if $is-codecombat {
    background-image: url(/images/pages/mobile/background.svg), url(/images/pages/mobile/cloud1.svg), url(/images/pages/mobile/cloud3.svg), url(/images/pages/mobile/cloud2.svg);
    background-repeat: no-repeat;
    background-position: bottom center, top 29vh right -15rem, top 50vh left -14rem, top 69vh right -10.7rem;
    background-size: contain, 33rem, 42rem, 30rem;
  } @else {
    background-image: url(/images/pages/mobile/ozaria-background.jpg);
    background-size: cover;
    background-position-x: center;
    background-repeat: no-repeat;
  }

  @keyframes spin {
    from {
      transform: rotate(0deg);
    }
    to {
      transform: rotate(360deg);
    }
  }

  .page-mobile-container {
    width: 100rem;
    position: relative;
    flex: 1 0 auto;
    z-index: 0;

    @if $is-ozaria {
      &:before {
        content: '';
        display: block;
        background: black;
        width: 1px;
        height: 1px;
        position: absolute;
        top: 40rem;
        left: 50rem;
        box-shadow: 0px 0px 50rem 30rem rgb(0 0 0 / 50%);
        z-index: -1;
      }
    }
  }

  .form-container {
    padding-bottom: 27rem;

    &.step-done {
      @if $is-ozaria {
        padding-bottom: 10rem;
      }
    }
  }

  h1 {
    color: $border-color;
    text-shadow: 1px 0 0 rgb(0 0 0 / 20%), -1px 0 0 rgb(0 0 0 / 20%), 0 -1px 0 rgb(0 0 0 / 20%), 0 1px 0 rgb(0 0 0 / 20%), 3px 3px 4px rgb(0 0 0 / 50%);
    text-align: center;
    font-family: "lores12ot-bold", "VT323";
  }

  .coco-logo {
    width: 90rem;
    margin-top: 5rem;
  }

  .coco-logo-bottom {
    width: max(30rem, 100px);
    margin-top: 20rem;

    &.step-done {
      margin-top: 1rem;
    }
  }

  footer {
    flex-shrink: 0;

    #final-footer {
      width: 100%;
      background: transparent;
      padding: 0 1rem;
      margin: 1rem 0;

      @if $is-ozaria {
        background: rgba(42, 78, 91, 0.9);
      }

      ::v-deep {
        img {
          display: none
        }

        .float-right {
          padding: 0;
          float: initial;
        }

        a, span {
          white-space: nowrap;
          display: inline-block;
          margin-left: 1rem;
        }
      }
    }
  }

  .ozaria-logo {
    width: 58rem;
    margin-top: 1rem;
    margin-bottom: 1rem;
  }

  .cloudflare-video-div {
    margin: 2rem 8rem 0;
    box-shadow: 0px 0px 2rem #000000aa;
  }

  .title-image {
    width: 80rem;
    margin-top: 3rem;
  }

  .blurb-done {
    font-size: 5.5rem;
    font-weight: bold;
    margin: 3rem 4rem 0;
    line-height: 6.2rem;
    letter-spacing: 0.2rem;
    color: $navy;
    @if $is-ozaria {
      color: white;
      text-shadow: 0.5px 0.5px rgb(0 0 0 / 70%), -0.5px -0.5px rgb(0 0 0 / 70%);
      background: rgb(42 78 91 / 90%);
      margin: 5rem 0 0;
      padding: 2rem 4rem;
    }
  }

  .line {
    border-top: $border-width $border-style $border-color;
    width: calc(50% - $border-width / 2);
    position: relative;
    z-index: 10;
    padding-top: 16rem;
    margin-top: calc(9rem * 229 / 281);

    &.step-name {
      padding-top: 5rem;
      @if $is-ozaria {
        padding-top: 11rem;
      }
    }

    img {
      position: absolute;
      width: 30rem;
      z-index: 10000;
      transform: translateY(-150%);
      left: 1rem;
      top: 22rem;
      transition: left 0.5s;

      &.moved-out {
        left: -100vw;
      }
    }

    @if $is-ozaria {
      &:before {
        @extend .circle;
        right: $circle-radius * -1;
        top: $circle-radius * -1;
      }
    }
  }

  .hero-2 {
    width: 25rem;
    position: absolute;
    top: -21rem;
    right: 16rem;
    transition: right 0.5s;
    z-index: 2;

    &.moved-out {
      right: -100vw;
    }
  }

  .page-mobile-inner {
    overflow: visible;
    position: relative;
    height: 66rem;
    @if $is-ozaria {
      height: 71rem;
    }

    &:before {
      content: " ";
      display: block;
      border-right: $border-width $border-style $border-color;
      position: absolute;
      right: 50%;
      width: 50%;
      height: calc(100% - 13rem);
      top: 0;
    }
  }

  .input-container {
    overflow: visible;
    margin-bottom: 0;
    margin-top: 0;
    position: absolute;
    padding-left: 17rem;
    padding-right: 17rem;
    width: 100%;
    transition: transform 0.5s, opacity 0.5s;

    &.input-container-lastname {
      top: 31rem;
      @if $is-ozaria {
        top: 37rem;
      }
    }

    &.input-container-button {
      width: 100%;
      bottom: 0;
    }

    input {
      border: $border-width $border-style $border-color;
      border-radius: 0;
      @if $is-ozaria {
        border: $border-width * 1.5 solid $border-color;
        color: #131b25;
      }
      outline: none;
      text-align: center;
      height: 13rem;
      font-size: 4.3rem;
      font-weight: bold;
      background-color: $background-color;
      background-clip: padding-box;
    }

    &.text-input-container {
      overflow: hidden;
      opacity: 1;
      display: block;
      z-index: 1;

      @if $is-ozaria {
        opacity: 1;
        transform: scale(1);
      }

      &.moved-out {
        opacity: 0;
        transform: scale(0);
        z-index: 0;
      }

      i {
        position: absolute;
        top: calc($border-width + 0.8rem);
        right: calc(17rem + $border-width + 0.8rem);
        line-height: 2.5rem;
        font-size: 2.5rem;

        &.mobile-icon-refresh {
          animation-name: spin;
          animation-duration: 5000ms;
          animation-iteration-count: infinite;
          animation-timing-function: linear;
        }

        &.mobile-icon-ok {
          color: green;
        }

        &.mobile-icon-remove {
          color: red;
        }
      }

      @if $is-ozaria {
        overflow: visible;
        &:before {
          @extend .circle;
          right: calc(50% - $circle-radius + $border-width / 2);
          top: $circle-radius * -1;
        }
        &:after {
          right: calc(50% - $circle-radius + $border-width / 2);
          bottom: $circle-radius * -1;
          @extend .circle;
          z-index: 1;
        }
      }
    }
  }

  #form-slide-email .text-input-container {
    margin-top: 0;

    &:before {
      display: none
    }

    &:after {
      height: 23rem;
    }

  }

  button {
    height: 13rem;
    background: #F7D047;
    border: none;
    @if $is-ozaria {
      background: $navy;
      border: $border-width * 1.5 solid $border-color;
    }
    border-radius: 20px;
    color: white;
    font-size: 9rem;
    line-height: 9rem;
    font-weight: bold;
    text-shadow: -1px -1px 0 #000,
    1px -1px 0 #000,
    -1px 1px 0 #000,
    1px 1px 0 #000;

    &:disabled {
      filter: grayscale(80%)
    }
  }

  input, button {
    width: 100%;
  }

  .subtitle {
    text-transform: uppercase;
    font-weight: bold;
    margin-top: 4rem;
    font-size: 7.3rem;
    line-height: 7.3rem;
    color: $navy;
    @if $is-ozaria {
      color: white;
      margin: -1rem 9rem 0;
      font-size: 6.8rem;
      line-height: 6.8rem;
      text-shadow: 1px 1px rgb(0 0 0 / 70%), -1px -1px rgb(0 0 0 / 70%);
      color: white;
    }
  }

  h3.you-re-set {
    color: #f7d047;
    font-family: "Open Sans", sans-serif;
    text-shadow: 1px 1px rgb(0 0 0 / 70%), -1px -1px rgb(0 0 0 / 70%);
    font-size: 13rem;
    font-weight: bold;
    margin-top: 2rem;
  }

  .carousel-indicators {
    position: static;
    margin: 0;
    width: 100%;
    display: flex;
    align-items: center;
    justify-content: space-evenly;
    margin-top: 9.5rem;
    margin-bottom: 6rem;

    @if $is-ozaria {
      margin-top: 5.5rem;
    }

    li {
      flex: 1;
      position: relative;
      overflow: visible;
      text-indent: 0;

      display: flex;
      align-items: center;
      justify-content: center;

      background: transparent;
      border: none;
      max-width: 10rem;
      @if $is-ozaria {
        max-width: 25rem;
      }

      &:before {
        content: ' ';
        background-color: #f7d047;
        border-color: #f7d047;
        width: 6rem;
        height: 6rem;
        border-radius: 3rem;
        border-width: $border-width;
        border-style: solid;
      }

      &.active:before {
        background-color: $navy;
      }

      &:not(:last-child):after {
        content: ' ';
        position: absolute;
        display: inline-block;
        top: calc(50% - 2px);
        width: calc((100rem - 300%) / 4);
        left: 100%;
        @if $is-ozaria {
          width: calc(100% - 6rem);
          left: calc(50% + 6rem);
        }
        border-bottom: $border-width $border-style $border-color;
      }

      span {
        position: absolute;
        top: 6rem;
        white-space: nowrap;
        font-size: 2.5rem;
        font-weight: bold;
        margin-left: -100%;
        margin-right: -100%;
        text-shadow: 1px 1px rgb(0 0 0 / 10%);
        @if $is-ozaria {
          text-shadow: 1px 1px rgb(0 0 0 / 70%), -1px -1px rgb(0 0 0 / 70%);
          color: white;
        }
      }
    }
  }

  .screenshot-container {
    @if $is-ozaria {
      margin: 9rem 0 0;
    }

    h4 {
      font-size: 6.7rem;
      font-weight: bold;
      padding-top: 4rem;
      padding-bottom: 1rem;
      color: $navy;
      @if $is-ozaria {
        color: white;
        text-shadow: 0.5px 0.5px rgb(0 0 0 / 70%), -0.5px -0.5px rgb(0 0 0 / 70%);
        background: rgb(42 78 91 / 90%);
        padding: 2rem;
      }
    }

    img {
      width: 88rem;
    }
  }
}
</style>
