<template>
  <div class="guest-info">
    <div class="container">
      <div class="row">
        <div class="col-md-offset-1 col-md-5">
          <div class="guest-info__about">
            <h2 class="guest-info__about-text">
              {{ $t('podcast.about_guest') }}
            </h2>
            <div class="guest-info__about-desc" v-html="formatGuestDetails"></div>
          </div>
        </div>
        <div class="col-md-5 col-md-offset-1">
          <img :src="`/file/${podcast.guestImage}`" alt="Guest Image" class="guest-info__img">
        </div>
      </div>
    </div>

  </div>
</template>

<script>
import { i18n } from 'app/core/utils'
import { podcastLinkRenderer } from '../podcastHelper'
const marked = require('marked')
export default {
  name: 'GuestInfoComponent',
  props: {
    podcast: {
      type: Object,
      required: true
    }
  },
  computed: {
    formatGuestDetails () {
      return marked(i18n(this.podcast, 'guestDetails'), { renderer: podcastLinkRenderer() })
    }
  }
}
</script>

<style scoped lang="scss">
.guest-info {
  padding-top: 6rem;

  &__about {
    padding-bottom: 2rem;
    &-text {
      font-weight: 700;
      padding-bottom: 1rem;
    }

    &-desc {
      font-size: 2rem;
      letter-spacing: .1rem;
      word-spacing: .3rem;

      margin-left: 1rem;
    }
  }

  &__img {
    max-width: 100%;
    height: 30rem;
  }
}
</style>
