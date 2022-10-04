<template>
  <div class="podcast-head">
    <div class="container">
      <div class="row">
        <div class="col-md-7">
          <div class="podcast-head__adventure">
            <img src="/images/pages/podcast/edtech-adventure.jpg" alt="Edtech adventure" class="podcast-head__adventure-img">
          </div>
        </div>
        <div class="col-md-5 podcast-head__text">
          <h2 class="podcast-head__heading">
            {{ $t('podcast.learning_adventure') }}
          </h2>
          <div class="podcast-head__subheading">
            {{ $t('podcast.explores_stem') }}
          </div>
          <div class="podcast-head__subscribe">
            <button class="btn btn-subscribe podcast-btn-yellow" @click="onSubscribeClick">{{ $t('podcast.listen_now') }}</button>
          </div>
        </div>
      </div>
    </div>
    <subscribe-modal
      @close="showSubscribeModal = false"
      v-if="showSubscribeModal"
    />
  </div>
</template>

<script>
import SubscribeModal from './SubscribeModal'
export default {
  name: 'HeadComponent',
  components: {
    SubscribeModal
  },
  data () {
    return {
      showSubscribeModal: false
    }
  },
  methods: {
    onSubscribeClick () {
      this.showSubscribeModal = true
    }
  }
}
</script>

<style scoped lang="scss">
@import "app/styles/podcast/variables";
@import "app/styles/podcast/common";
@import "app/styles/bootstrap/variables";

.podcast-head {
  padding: 7rem;

  @media (max-width: $screen-md-min) {
    padding: 1rem;
  }

  &__adventure {
    &-img {
      max-width: 100%;
    }
  }

  &__heading {
    font-size: 4rem;
    font-weight: 700;

    padding-bottom: 4rem;
  }

  &__subheading {
    font-size: 2rem;
    line-height: 3.5rem;

    padding-bottom: 4rem;
  }

  &__text {
    padding: 3rem;
  }
}
</style>
