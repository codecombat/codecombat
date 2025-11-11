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
        @next="next"
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
const VALID_ROLE = ['individual', 'parent']
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
      validator: function (value) {
        return VALID_ROLE.includes(value)
      },
    },
  },
  data () {
    return {
      view: 'sign-up',
    }
  },
  methods: {
    next () {
      this.view = 'success'
    },
  },
})

</script>

<style scoped lang="scss">
@import "app/styles/component_variables.scss";

@media (min-width: 768px) {
  ::v-deep .subview {
    .head1 {
      font-size: 32px;
      margin-bottom: 20px;
    }
    .desc {
      font-size: 22px;
    }
  }
}

@media (max-width: 768px) {
  ::v-deep .subview {
    .head1 {
      font-size: 7rem;
      margin-bottom: 3rem;
    }
    .desc {
      font-size: 4.5rem;
    }
  }
}
.page-mobile-container {
  background-color: white;
  background-image: url(/images/components/bg-image.webp);
  background-position: bottom left;
  background-size: 2800px;
  background-repeat: no-repeat;
  min-height: 100vh;

  .individual-sign-up {
    width: 100%;
    margin: auto;
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
  width: 100%;
  display: flex;
  flex-direction: column;
  align-items: center;

  .head1 {
    color: black;
  }
  .desc {
    width: 90%;
    text-align: center;
    color: $purple;
  }
}
</style>