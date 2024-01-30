<template>
  <modal
    title="AI Hint"
    :backbone-dismiss-modal="true"
  >
    <div class="ask-ai">
      <div class="ask-ai__img">
        <img
          :src="aiHintAnimal"
          alt="AI Hint Animal"
        >
      </div>
      <div class="ask-ai__content">
        <div class="ask-ai__text">
          {{ $t('play_level.problem_alert_need_hint') }}
        </div>
        <div class="ask-ai__cta">
          <button
            class="btn ai-help-button"
            :class="aiHintBtnStyle"
            data-dismiss="modal"
            @click="onAskAiClicked"
          >
            {{ $t('play_level.problem_alert_ask_the_ai') }}
          </button>
        </div>
        <div
          v-if="creditMessage"
          class="ask-ai__credit"
        >
          {{ creditMessage }}
        </div>
      </div>
    </div>
  </modal>
</template>

<script>
import Modal from 'app/components/common/Modal'
const userUtils = require('app/lib/user-utils')
const _ = require('lodash')
const utils = require('core/utils')
export default Vue.extend({
  name: 'AskAIHelp',
  components: {
    Modal
  },
  data () {
    return {
      creditMessage: ''
    }
  },
  computed: {
    aiHintAnimal () {
      if (utils.isCodeCombat) {
        return '/images/level/baby-griffin.png'
      } else {
        return '/images/ozaria/avatar-selector/avatar_ghost.png'
      }
    },
    aiHintBtnStyle () {
      if (utils.isCodeCombat) {
        return 'btn-illustrated btn-primary'
      } else {
        return 'ai-btn-active'
      }
    }
  },
  async created () {
    this.creditMessage = await userUtils.levelChatCreditsString()
  },
  methods: {
    onAskAiClicked () {
      this.$emit('ask-ai-clicked')
      const message = $.i18n.t('ai.prompt_level_chat_hint_' + _.random(1, 5))
      Backbone.Mediator.publish('level:add-user-chat', { message })
    }
  }
})
</script>

<style scoped lang="scss">
@import "ozaria/site/styles/play/images";

.ask-ai {
  padding: 5px;

  &__img {
    display: flex;
    justify-content: center;
    margin-bottom: 10px;
    img {
      width: 75px;
    }
  }

  &__cta {
    display: flex;
    justify-content: center;
  }

  &__hint-icon {
    margin-left: 5px;
  }

  &__text {
    margin-bottom: 5px;
  }

  &__credit {
    font-size: 14px;
    color: #7b7575;
    text-align: center;
    margin-top: 5px;
  }

  .ai-btn-active {
    background-image: url($Button);
    background-position: center;
    background-size: contain;
    background-repeat: no-repeat;
    font-size: 16px;
    font-weight: bold;
    letter-spacing: 0.77px;
    line-height: 18px;
  }
}
</style>
