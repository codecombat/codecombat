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
@import "app/styles/style-flat-variables.sass";
@import "app/styles/component_variables.scss";

@media (max-width: $screen-sm-max) {
  ::v-deep .subview {
    .head1 {
      font-size: 2.4rem;
      margin-bottom: 0.5rem;
      font-weight: bold;
    }
    .desc {
      font-size: 1.6rem;
    }
  }
}

@media (min-width: $screen-sm-min) {
  ::v-deep .subview {
    .head1 {
      font-size: 3.2rem;
      margin-bottom: 1rem;
      font-weight: bold;
    }
    .desc {
      font-size: 2rem;
    }
  }
}
.page-mobile-container {
  font-size: 62.5%; // 1rem = 10px within the signup flow for easier spacing math
  background-color: white;
  background-image: url(/images/components/bg-image.webp);
  background-position: bottom left;
  background-size: 280rem;
  background-repeat: no-repeat;
  min-height: 100vh;
  padding: 2rem 1rem;
  display: flex;
  font-family: $body-font;

  @media (max-width: $screen-sm-max) {
    background-size: 160rem;
    padding: 1rem 0.5rem;
  }

  .individual-sign-up {
    width: 100%;
    margin: auto;
    max-width: 80rem;
    height: 100%;
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 1rem;
    padding: 0 1rem 4rem;

    .logo {
      text-align: center;
      margin-bottom: 2rem;
      .coco-logo {
        width: 100%;
        margin-top: 2rem;
      }
    }
  }

  @media (min-width: $screen-md-min) {
    .individual-sign-up {
      max-width: 100rem;
    }
  }

  @media (min-width: $screen-lg-min) {
    .individual-sign-up {
      max-width: 120rem;
    }
  }
}
::v-deep .subview{
  width: 100%;
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 0 1.5rem;

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
