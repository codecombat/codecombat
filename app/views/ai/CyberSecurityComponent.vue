<template>
  <div class="hs-modal-content-container">
    <h2
      id="hs-modal-title"
      class="text-h2"
    >
      {{ $t('ai.cyber_security_modal_header') }}
    </h2>
    <div class="img">
      <picture>
        <source
          srcset="/images/pages/hackstack/cyber/hero-simulation.webp"
          type="image/webp"
        >
        <img src="/images/pages/hackstack/cyber/hero-simulation.webp">
      </picture>
    </div>
    <p class="text-p">
      {{ $t('ai.cyber_security_modal_body') }}
    </p>

    <CTAButton
      href="/hackstack-cyber"
      @clickedCTA="onLearnMore"
    >
      {{ $t('ai.learn_more') }}
    </CTAButton>
  </div>
</template>

<script>
import CTAButton from 'app/components/common/buttons/CTAButton.vue'
import trackable from 'app/components/mixins/trackable.js'
export default {
  name: 'HackstackModalComponent',
  components: {
    CTAButton,
  },
  mixins: [trackable],
  data () {
    return {
    }
  },
  methods: {
    onLearnMore () {
      this.$emit('close')
      this.trackEvent('Cyber Security Promo Modal: Learn more clicked', { category: 'Hackstack' })
    },
  },
}
</script>

<style scoped lang="scss">
@import 'app/styles/core/variables.scss';
@import 'app/styles/common/_button.scss';
@import 'app/styles/component_variables.scss';

.hs-modal-content-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  margin: 10px 30px;
  text-align: center;
  position: relative;

  .text-h2#hs-modal-title {
    font-family: $main-font-family;
    font-weight: bold;
    margin: 10px auto;
  }

  >* {
    max-width: 800px;
  }

  .img {
    margin-bottom: 10px;
    width: 600px;
    position: relative;

    img {
      width: 600px;
    }
  }

  .text-p {
    font-size: 0.9em;
  }
}
</style>