<template>
  <div class="jumbotron">
    <div class="row">
      <div class="col-lg-5 col-md-6 trust-logos">
        <div class="flex-spacer">
          <div class="codie-logo-container">
            <img srcset="/images/pages/parents/2017_codie_award@1x.png 1x,
                                     /images/pages/parents/2017_codie_award@2x.png 2x,
                                     /images/pages/parents/2017_codie_award@3x.png 3x"
                 src="/images/pages/parents/2017_codie_award@1x.png"
            />
          </div>
        </div>

        <div class="flex-spacer">
          <img srcset="/images/pages/parents/cse_top_pick@1x.png 1x,
                                     /images/pages/parents/cse_top_pick@2x.png 2x,
                                     /images/pages/parents/cse_top_pick@3x.png 3x"
               src="/images/pages/parents/cse_top_pick@1x.png"
               class="cse-top-pick"
          />
        </div>

        <div class="flex-spacer">
          <div class="cs-for-all-container">
            <img srcset="/images/pages/parents/cs_for_all_member@1x.png 1x,
                                     /images/pages/parents/cs_for_all_member@2x.png 2x,
                                     /images/pages/parents/cs_for_all_member@3x.png 3x"
                 src="/images/pages/parents/cs_for_all_member@1x.png"
            />
          </div>
        </div>
      </div>
    </div>
    <div class="row">
      <div class="col-lg-5 col-md-6">
        <h1>{{ $t('parents_landing_2.splash_title') }}</h1>
      </div>
    </div>
    <div class="row">
      <div class="col-lg-4 col-md-5">
        <a v-if="isParentsPage" href="#" class="full-width button" @click="onCtaClick">
          {{ $t('parents_landing_2.learn_with_instructor') }}
        </a>
        <a v-else href="#" class="full-width button" @click="onCtaClick">
          {{ $t('parents_landing_2.start_free_trial_today') }}
        </a>
      </div>
    </div>
    <div class="row" v-if="isParentsPage">
      <div class="col-lg-4 col-md-5">
        <a href="#premium" class="full-width button">
          {{ $t('parents_landing_2.learn_at_own_pace') }}
        </a>
      </div>
    </div>
  </div>

</template>

<script>
export default {
  props: {
    type: {
      type: String,
      required: true
    }
  },

  computed: {
    isParentsPage: function () {
      return this.type === 'parents'
    }
  },

  methods: {
    onCtaClick (e) {
      e.preventDefault()
      this.$emit('cta-clicked')
    }
  }
}
</script>

<style scoped>
  .jumbotron {
    padding: 70px;
    margin-bottom: 0;
    min-height: 580px;

    background-image: url("/images/pages/parents/jumbotron@1x.png");
    background-size: cover;
    background-repeat: no-repeat;
    background-position: center;

    position: relative;
    z-index: 2;
  }

  .jumbotron h1 {
    margin-bottom: 10px;
  }

  .jumbotron .button {
    margin-top: 30px;
    max-width: 320px;
  }

  @media (-webkit-min-device-pixel-ratio: 2), (min-resolution: 192dpi) {
    .jumbotron {
      background-image: url("/images/pages/parents/jumbotron@2x.png");
    }
  }

  .trust-logos {
    margin-bottom: 40px;

    display: flex;
    justify-content: flex-start;
    align-items: center;
  }

  .trust-logos .flex-spacer {
    padding-right: 23px;
    flex-shrink: 1;
  }

  .trust-logos .flex-spacer:last-of-type {
    padding-right: 0;
  }

  @media (min-width: 375px) {
    .jumbotron {
      padding: 50px;
    }
  }

  .codie-logo-container {
    background: #FFFFFF;

    box-shadow: 10px 10px 30px rgba(0, 0, 0, 0.43), -10px -10px 30px rgba(0, 0, 0, 0.25);
    border-radius: 6px;

    padding: 3px 6px;
  }

  .codie-logo-container img {
    width: 118px;
    height: 42px;
    max-width: 100%;
  }

  .cse-top-pick {
    filter: drop-shadow(10px 10px 30px rgba(0, 0, 0, 0.43)) drop-shadow(-10px -10px 30px rgba(0, 0, 0, 0.25));
    max-width: 100%;
  }

  .cs-for-all-container {
    padding: 5px 16px;
    background: #FFFFFF;

    box-shadow: 10px 10px 30px rgba(0, 0, 0, 0.43), -10px -10px 30px rgba(0, 0, 0, 0.25);
    border-radius: 6px;
  }

  .cs-for-all-container img {
    width: 93px;
    height: 40px;
    max-width: 100%;
    max-height: 100%;
  }
</style>
