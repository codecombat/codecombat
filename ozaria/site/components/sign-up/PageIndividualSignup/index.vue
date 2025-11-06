<template>
  <div class="page-mobile-container">
    <div class="individual-sign-up">
      <div class="logo">
        <img
          class="coco-logo"
          src="/images/pages/base/logo.png"
        >
      </div>
      <SignUpView
        v-if="view == 'sign-up'"
        :role="role"
      />
      <SuccessView
        v-else
        :role="role"
      />
    </div>
  </div>
</template>

<script>
import SignUpView from './components/SignUpView.vue'
import SuccessView from './components/SuccessView.vue'
module.exports = Vue.extend({
  name: 'PageIndex',
  components: {
    SignUpView,
    SuccessView,
  },
  props: {
    role: {
      type: String,
      default: 'individual',
    },
  },
  data () {
    return {
      /* view: 'sign-up' */
      view: 'success',
    }
  },
  computed: {
    roleDesc () {
      return $.i18n.t(`account.${this.role}_inspiration`)
    },
  },
})

</script>

<style scoped lang="scss">
@import "app/styles/component_variables.scss";

@media (screen) and (max-width: 768px) {
  .individual-sign-up {
    width: 100%;
  }
}
.page-mobile-container {
  background: black; /* in case we open this page in pc */
  height: 100vh;

  .individual-sign-up {
    margin: auto;
    background-color: white;
    background-image: url(/images/components/bg-image.webp);
    background-position: bottom left;
    background-size: 350%;
    background-repeat: no-repeat;
    max-width: 800px;
    height: 100%;
    display: flex;
    flex-direction: column;
    align-items: center;

    .logo {
      text-align: center;
      margin-bottom: 5rem;
      .coco-logo {
        width: 100%;
        margin-top: 5rem;
      }
    }
  }
}
::v-deep .subview{
  display: flex;
  flex-direction: column;
  align-items: center;

  .head1 {
    color: black;
    font-size: 7rem;
    margin-bottom: 3rem;
  }
  .desc {
    width: 90%;
    text-align: center;
    color: $purple;
    font-size: 4.5rem;
  }
}

</style>