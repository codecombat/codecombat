<script>
import Modal from 'ozaria/site/components/common/Modal'
import trackable from 'app/components/mixins/trackable.js'

import CTAButton from 'app/components/common/buttons/CTAButton.vue'

export default Vue.extend({
  components: {
    Modal,
    CTAButton,
  },
  mixins: [trackable],
  props: {
    remainCredits: {
      type: Number,
      default: 0,
    },
    remainSolutions: {
      type: Number,
      default: 0,
    },
    remainLevels: {
      type: Number,
      default: 0,
    },
    manageUrl: {
      type: String,
      default: '',
    },
  },
  computed: {
    me () {
      return window.me
    },
  },
})
</script>

<template>
  <Modal
    ref="modal"
    modal-type="newModal"
    @close="$emit('close')"
  >
    <div class="modal-content-container">
      <h2
        id="before-you-go-modal-title"
        class="text-h2"
      >
        {{ $t('payments.before_you_go') }}
      </h2>
      <div class="desc">
        {{ $t('payments.before_you_go_desc') }}
      </div>
      <div class="box">
        <div
          v-if="remainSolutions"
          class="remain-solutions"
        >
          <span>{{ remainSolutions }}</span>
          {{ $t('payments.unexplored_solutions') }}
        </div>
        <div
          v-if="remainCredits"
          class="remain-credits"
        >
          <span>{{ remainCredits }}</span>
          {{ $t('payments.ai_credits_remaining') }}
        </div>
        <div
          v-if="remainLevels"
          class="remain-levels"
        >
          <span>{{ remainLevels }}</span>
          {{ $t('payments.premium_levels_available') }}
        </div>
      </div>

      <div class="desc">
        {{ $t('payments.access_until', { date: me.premiumEndDate() }) }}
      </div>
      <CTAButton
        @clickedCTA="$emit('close')"
      >
        {{ $t('payments.keep_subscription') }}

        <template #description>
          <a :href="manageUrl">
            {{ $t('payments.continue_cancel') }}
          </a>
        </template>
      </CTAButton>
    </div>
  </Modal>
</template>

<style lang="scss" scoped>
@import 'app/styles/core/variables.scss';
@import 'app/styles/common/_button.scss';
@import 'app/styles/component_variables.scss';

.modal-content-container {
  ::v-deep {
    a {
      color: var(--color-primary);
    }
  }
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  margin: 10px 30px;
  text-align: center;
  position: relative;
  font-weight: 400;

  .text-h2 {
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
  }
  .desc {
    margin-top: 20px;
    margin-bottom: 20px;
  }
  .box {
    width: 600px;
    margin-bottom: 40px;
    margin-top: 40px;
    border-readius: 5px;
    border: 1px solid #dbdbdb;
    background-color: #f7f6fd;

    .remain-solutions, .remain-levels, .remain-credits {
      height: 80px;
      margin: auto;
      display: flex;
      width: 80%;
      align-items: center;
      justify-content: center;
      span {
        font-size: 160%;
        color: var(--color-primary);
        margin-right: 2rem;
      }
    }
    .remain-credits, .remain-solutions {
      border-bottom: 1px solid #dbdbdb;
    }
  }
}
</style>
