<template>
  <div class="account">
    <div class="account__heading">
      Child Account Creation
    </div>
    <div class="account__subheading">
      Your child will use these credentials to log in.
    </div>
    <div class="account__existing">
      Does your child already have a CodeCombat or Ozaria account? <a href="#" @click.prevent="linkAccountClicked">Link Accounts</a>
    </div>
    <form class="account__form" @submit.prevent="onFormSubmit">
      <div class="form-group">
        <label for="name">Child's Full Name</label>
        <input type="text" id="name" class="form-control" v-model="name" />
      </div>
      <div class="form-group">
        <label for="uname">Username</label>
        <input type="text" id="uname" class="form-control" v-model="username" />
      </div>
      <div class="form-group">
        <label for="email">Email</label>
        <input type="email" id="email" class="form-control" v-model="email" />
      </div>
      <div class="form-group">
        <label for="password">Password</label>
        <input type="password" id="password" class="form-control" v-model="password" />
      </div>
<!--      <div class="form-group">-->
<!--        <label for="bday">Birthday</label>-->
<!--        <input type="text" id="bday" class="form-control" v-model="birthday" />-->
<!--      </div>-->
      <div class="form-group account__submit">
        <button class="btn account__back--btn" @click.prevent="onBackButton">Back</button>
        <button class="btn account__submit__btn" type="submit">Continue</button>
      </div>
    </form>
  </div>
</template>

<script>
export default {
  name: 'CreateChildAccountComponent',
  data () {
    return {
      name: null,
      username: null,
      email: null,
      password: null,
      birthday: null
    }
  },
  methods: {
    linkAccountClicked () {
      console.log('link account clicked')
    },
    onFormSubmit () {
      console.log('child account submit', this.$data)
      this.$emit('onChildAccountSubmit', this.$data)
    },
    onBackButton () {
      this.$emit('backButtonClicked')
    }
  }
}
</script>

<style scoped lang="scss">
@import "common";

.account {
  &__existing {
    font-family: 'Work Sans', sans-serif;
    font-weight: 400;
    font-size: 1.4rem;
    line-height: 1.7rem;
    letter-spacing: 0.3px;
    color: #545B64;

    margin-bottom: 2rem;
  }

  &__back--btn {
    border: 2px solid #1FBAB4;
    border-radius: 4px;
    background: #ffffff;
    font-family: 'Open Sans', sans-serif;
    font-style: normal;
    font-weight: 700;
    font-size: 1.8rem;
    line-height: 2.5rem;
    text-align: center;
    color: #1FBAB4;
    padding: 1rem 3rem;
  }

  &__submit {
    justify-content: space-between;
  }
}
</style>
