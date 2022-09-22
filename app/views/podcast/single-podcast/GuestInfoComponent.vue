<template>
  <div class="guest-info">
    <div class="container">
      <div class="row guest-info__about">
        <h2 class="guest-info__about-text">
          {{ podcast.additionalGuestName ? $t('podcast.about_guests') : $t('podcast.about_guest') }}
        </h2>
      </div>
      <div class="row guest-info__container">
        <div class="col-md-offset-1 col-md-5">
          <div class="guest-info__about">
            <h2
              class="guest-info__about-text"
              v-html="formatGuestName"
            />
            <div
              class="guest-info__about-desc"
              v-html="formatGuestDetails"
            />
          </div>
        </div>
        <div class="col-md-5 col-md-offset-1">
          <img
            :src="`/file/${podcast.guestImage}`"
            alt="Guest Image"
            class="guest-info__img"
          >
        </div>
      </div>
      <div
        v-if="podcast.additionalGuestName"
        class="row guest-info__container"
      >
        <div class="col-md-5 col-md-offset-1">
          <img
            :src="`/file/${podcast.additionalGuestImage}`"
            alt="Guest Image"
            class="guest-info__img guest-info__img-add"
          >
        </div>
        <div class="col-md-5">
          <div class="guest-info__about">
            <h2
              class="guest-info__about-text"
              v-html="formatAdditionalGuestName"
            />
            <div
              class="guest-info__about-desc"
              v-html="formatAdditionalGuestDetails"
            />
          </div>
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
    },
    formatAdditionalGuestDetails () {
      return marked(i18n(this.podcast, 'additionalGuestDetails'), { renderer: podcastLinkRenderer() })
    },
    formatGuestName () {
      return marked(i18n(this.podcast, 'guestName'), { renderer: podcastLinkRenderer() })
    },
    formatAdditionalGuestName () {
      return marked(i18n(this.podcast, 'additionalGuestName'), { renderer: podcastLinkRenderer() })
    }
  }
}
</script>

<style scoped lang="scss">
.guest-info {
  padding-top: 6rem;

  &__container {
    margin-bottom: 5rem;
  }

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
