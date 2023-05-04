<template>
  <div
    v-if="isAnonymousUser"
    class="account"
  >
    <div class="account__heading">
      Parent Account Creation
    </div>
    <div class="account__subheading">
      Check out CodeCombat for free
    </div>
    <form class="account__form" @submit.prevent="onFormSubmit">
      <div class="form-group">
        <label for="name">Parent's Full Name</label>
        <input type="text" id="name" class="form-control" v-model="name" required />
      </div>
      <div class="form-group">
        <label for="email">Email</label>
        <input type="email" id="email" class="form-control" v-model="email" required />
      </div>
      <div class="form-group">
        <label for="password">Password</label>
        <input type="password" id="password" class="form-control" v-model="password" required />
      </div>
<!--      <div class="form-group">-->
<!--        <label for="phone">Phone</label>-->
<!--        <input type="text" id="phone" class="form-control" v-model="phone" required />-->
<!--      </div>-->
      <div class="account__empty-line"></div>
      <div class="form-group account__google">
        <span class="account__or">Or:</span>
        <div id="account__google-login-btn" :disabled="gplusBtnDisabled"></div>
      </div>
      <div
        v-if="errorMsg"
        class="account__error"
      >
        {{ errorMsg }}
      </div>
      <div class="form-group account__submit">
        <button class="btn account__submit__btn" type="submit">Continue to Child Account</button>
      </div>
    </form>
  </div>
  <div
    v-else
    class="account"
  >
    <p class="account__exists">
      Already logged in!!!
    </p>
  </div>
</template>

<script>
import GPlusHandler from 'app/core/social-handlers/GPlusHandler'
const User = require('../../../models/User')
export default {
  name: 'CreateParentAccountComponent',
  data () {
    return {
      name: this.initialData?.name,
      email: this.initialData?.email,
      password: this.initialData?.password,
      // phone: this.$props?.initialData?.phone,
      gplusBtnDisabled: true,
      isAnonymousUser: me.isAnonymous(),
      gplusData: null
    }
  },
  props: {
    initialData: {
      type: Object
    },
    errorMsg: {
      type: String,
      default: ''
    }
  },
  methods: {
    onFormSubmit () {
      console.log('parent account form submitted', this.$data)
      this.$emit('onParentAccountSubmit', this.$data)
    },
    startGplusSignup () {
      const gplus = new GPlusHandler()
      gplus.loadAPI({
        success: () => {
          gplus.connect({
            elementId: 'account__google-login-btn',
            success: (resp = {}) => {
              gplus.loadPerson({
                resp: resp,
                context: this,
                success: (gplusAttrs) => {
                  const existingUser = new User()
                  existingUser.fetchGPlusUser(gplusAttrs.gplusID, gplusAttrs.email, {
                    success: (res) => {
                      const msg = 'Account already exists, please login'
                      noty({ text: msg, type: 'error', layout: 'center', timeout: 5000 })
                    },
                    error: (user, jqxhr) => {
                      if (jqxhr.status === 404) {
                        this.gplusData ||= {}
                        this.gplusData.firstName = gplusAttrs.firstName
                        this.gplusData.lastName = gplusAttrs.lastName
                        this.gplusData.gplusID = gplusAttrs.gplusID
                        this.gplusData.email = gplusAttrs.email
                        this.$emit('onParentAccountSubmit', this.$data)
                      } else {
                        console.log('gplus signup error', jqxhr)
                        noty({ text: 'Internal error', type: 'error', layout: 'center', timeout: 5000 })
                      }
                    }
                  })
                }
              })
            }
          })
        }
      })
    }
  },
  created () {
    if (!me.isAnonymous()) {
      if (me.isParentHome()) {
        window.location.href = '/parents/dashboard'
        return
      }
      window.location.href = '/'
    }
    this.startGplusSignup()
  }
}
</script>

<style scoped lang="scss">
@import "common";
.account {

  &__google {
    display: flex;
    justify-content: flex-start;
    align-items: center;
  }

  &__or {
    margin-right: 1rem;
  }

  &__empty-line {
    height: 2px;
    background-color: #1FBAB4;

    margin-top: 2rem;
    margin-bottom: 2rem;
  }

  &__exists {
    font-size: 3rem;
    text-transform: uppercase;
  }

  &__error {
    color: red;
  }
}
</style>
