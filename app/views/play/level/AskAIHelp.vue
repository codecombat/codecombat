<template>
  <modal
    v-if="!hideModal"
    title="AI Hint"
    :backbone-dismiss-modal="true"
  >
    <div class="ask-ai">
      <div class="ask-ai__img">
        <img
          src="/images/level/baby-griffin.png"
          alt="AI Hint Animal"
        >
      </div>
      <div class="ask-ai__content">
        <div class="ask-ai__text">
          {{ $t('play_level.problem_alert_need_hint') }}
        </div>
        <div class="ask-ai__cta">
          <button
            class="btn btn-illustrated btn-primary ai-help-button"
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
export default Vue.extend({
  name: 'AskAIHelp',
  components: {
    Modal
  },
  data () {
    return {
      creditMessage: '',
      hideModal: false
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
      this.hideModal = true
    }
  }
})
</script>

<style scoped lang="scss">
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
}
</style>
