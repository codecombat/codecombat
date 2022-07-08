<template>
  <modal
    title="Subscribe to EdTech Adventures with CodeCombat"
    @close="$emit('close')"
  >
    <div class="container subscribe">
      <div class="row">
        <div class="col-xs-4">
          <a href="https://open.spotify.com/show/2Uadk5CLLnr1VpkW8IUzDG?si=A_6kDdQWQX6QUsDz0S6zIw" target="_blank">
            <img src="/images/pages/podcast/subscribe-logos-spotify.png" alt="Spotify" class="subscribe__logo" />
          </a>
        </div>
        <div class="col-xs-4">
          <a href="https://music.amazon.com/podcasts/f52fc3f3-3e09-40a9-97f3-cee523291346/edtech-adventures" target="_blank">
            <img src="/images/pages/podcast/subscribe-logos-amazon.png" alt="Amazon Music" class="subscribe__logo" />
          </a>
        </div>
        <div class="col-xs-4">
          <a href="https://podcasts.apple.com/us/podcast/edtech-adventures/id1628668668" target="_blank">
            <img src="/images/pages/podcast/subscribe-logos-apple.png" alt="Apple" class="subscribe__logo" />
          </a>
        </div>
      </div>
      <div class="row">
        <div class="col-xs-4">
          <a href="https://www.deezer.com/us/show/3783307" target="_blank">
            <img src="/images/pages/podcast/subscribe-logos-deezer.png" alt="Deezer" class="subscribe__logo" />
          </a>
        </div>
        <div class="col-xs-4 podcast-addict">
          <a href="https://podcastaddict.com/podcast/3985051" target="_blank" class="podcast-addict__link">
            <img src="/images/pages/podcast/subscribe-logos-podcast-addict.png" alt="Podcast Addict" class="subscribe__logo" />
            <span class="podcast-addict__text">Podcast Addict</span>
          </a>
        </div>
        <div class="col-xs-4">
          <a href="https://player.fm/series/edtech-adventures" target="_blank">
            <img src="/images/pages/podcast/subscribe-logos-player-fm.png" alt="Player FM" class="subscribe__logo" />
          </a>
        </div>
      </div>
      <div class="row">
        <div class="col-xs-4">
          <a href="https://www.stitcher.com/podcast/edtech-adventures" target="_blank">
            <img src="/images/pages/podcast/subscribe-logos-stitcher.png" alt="Stitcher" class="subscribe__logo" />
          </a>
        </div>
        <div class="col-xs-4">
          <a href="https://podcasts.google.com/feed/aHR0cHM6Ly9mZWVkcy50cmFuc2lzdG9yLmZtL2VkdGVjaC1hZHZlbnR1cmVz" target="_blank">
            <img src="/images/pages/podcast/subscribe-logos-google.png" alt="Google" class="subscribe__logo" />
          </a>
        </div>
      </div>
    </div>

  </modal>
</template>

<script>
import Modal from '../../components/common/Modal'

export default {
  name: 'SubscribeModal',
  components: {
    Modal
  }
}
</script>

<style scoped lang="scss">
.subscribe {
  &__logo {
    max-width: 100%;
    max-height: 4rem;
  }

  .row {
    padding: 2rem;
  }
}

.podcast-addict {
  text-align: center;
  &__text {
    color: #fc7e0f;
    font-size: 1.4rem;
  }

  &__link {
    text-decoration: none;
  }
}

::v-deep .title {
  padding-top: 10px;
}
</style>
