<template>
  <div
    v-if="isAnonymousUser"
    class="account"
  >
    <div class="account__heading">
      Parent Account Creation
    </div>
    <div class="account__subheading">
      Start your free trial of CodeCombat
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
      <div class="form-group account__submit">
        <button class="btn account__submit__btn" type="submit">Continue</button>
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
export default {
  name: 'CreateParentAccountComponent',
  data () {
    return {
      name: this.$props?.initialData?.name,
      email: this.$props?.initialData?.email,
      password: null,
      // phone: this.$props?.initialData?.phone,
      gplusBtnDisabled: true,
      isAnonymousUser: me.isAnonymous()
    }
  },
  props: {
    initialData: {
      type: Object
    }
  },
  methods: {
    onFormSubmit () {
      console.log('parent account form submitted', this.$data)
      this.$emit('onParentAccountSubmit', this.$data)
    }
  },
  created () {
    const gplus = new GPlusHandler()
    gplus.loadAPI({
      success: () => {
        gplus.connect({
          elementId: 'account__google-login-btn',
          success: () => {

          }
        })
      }
    })
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
}
</style>
