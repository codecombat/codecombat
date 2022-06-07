<template>
  <div class="podcast-footer">
    <div class="podcast-footer__explore">
      <div class="podcast-footer__explore-text">
        {{ $t('podcast.learn_more_coco') }}
      </div>
      <div>
        <a href="/" class="btn podcast-btn-yellow">{{ $t('podcast.explore_coco') }}</a>
      </div>
    </div>

    <div class="podcast-footer__chat">
      <div class="podcast-footer__chat-text">
        {{ $t('podcast.interested_in_being_guest') }}
      </div>
      <div>
        <button class="btn podcast-btn-yellow" @click="letsChatClicked">{{ $t('podcast.lets_chat') }}</button>
      </div>
    </div>
    <LetsChatModal
      v-if="showLetsChatModal"
      @close="showLetsChatModal = false"
    />
  </div>
</template>

<script>
import LetsChatModal from './LetsChatModal'
export default {
  name: 'FooterComponent',
  components: {
    LetsChatModal
  },
  data () {
    return {
      showLetsChatModal: false
    }
  },
  methods: {
    letsChatClicked () {
      console.log('lets chat clicked')
      this.showLetsChatModal = true
    }
  }
}
</script>

<style scoped lang="scss">
@import "app/styles/podcast/variables";
@import "app/styles/podcast/common";

.podcast-footer {
  text-align: center;
  padding-top: 2rem;

  &__explore, &__chat {

    &-text {
      font-size: 2.2rem;

      padding-bottom: 1rem;
    }
  }

  &__explore {
    padding-bottom: 3rem;
  }
}
</style>
