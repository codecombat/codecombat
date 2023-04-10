<template>
  <div class="parent-signup">
    <div class="signup__image signup__image--1">
      <img src="/images/pages/parents/personal_learning_3.png" alt="Personal learning image" class="signup__img img-responsive">
    </div>
    <create-parent-account-component
      v-if="currentView === 'create-parent-account'"
      @onParentAccountSubmit="onParentAccountSubmit"
      :initial-data="parentAccountData"
    />
    <create-child-account-component
      v-if="currentView === 'create-child-account'"
      @backButtonClicked="currentView = 'create-parent-account'"
      @onChildAccountSubmit="onChildAccountSubmit"
    />
    <div class="signup__image signup__image--2">
      <img src="/images/pages/home-v2/loc-image.png" alt="Girl playing CodeCombat" class="signup__img img-responsive">
    </div>
  </div>
</template>

<script>
import CreateParentAccountComponent from './signup/CreateParentAccountComponent'
import CreateChildAccountComponent from './signup/CreateChildAccountComponent'
import createChildAccountMixin from './mixins/createChildAccountMixin'

export default {
  name: 'SignupView',
  data () {
    return {
      currentView: 'create-parent-account',
      parentAccountData: null,
      childAccountData: null
    }
  },
  components: {
    CreateParentAccountComponent,
    CreateChildAccountComponent
  },
  mixins: [
    createChildAccountMixin
  ],
  methods: {
    async onParentAccountSubmit (data) {
      console.log('parent account data', data)
      this.parentAccountData = data
      this.currentView = 'create-child-account'
    },
    async onChildAccountSubmit (data) {
      this.childAccountData = data
      await this.onChildAccountSubmitHelper(data)
    }
  }
}
</script>

<style scoped lang="scss">
.parent-signup {
  background: linear-gradient(66.45deg, #FFFEF0 15.94%, #FFFDEA 29.45%, #FFF8CF 46.45%, #FDF7D7 76.99%, #FFFCE9 83.48%);
  border-radius: 20px;
  //transform: matrix(-1, 0, 0, 1, 0, 0);

  height: 100vh;
  position: relative;

  display: flex;
  align-items: center;
  justify-content: center;
}

.signup {
  &__image {
    position: absolute;

    &--1 {
      top: 5%;
      left: 2%;
    }

    &--2 {
      bottom: 5%;
      right: 2%;
    }
  }
  &__img {
    height: 30vh;
  }
}
</style>
