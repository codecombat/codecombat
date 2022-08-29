<template>
  <div class="podcast-head">
    <div class="container">
      <div class="row">
        <div
          :class="{ 'col-md-6': podcast.additionalGuestImage, 'col-md-4': !podcast.additionalGuestImage, 'podcast-head__guest': true }"
        >
          <img
            :src="`/file/${podcast.guestImage}`"
            alt="Guest Image"
            :class="{ 'podcast-head__guest-img': true, 'podcast-head__guest-img-2': podcast.additionalGuestImage }"
          >
          <img
            v-if="podcast.additionalGuestImage"
            :src="`/file/${podcast.additionalGuestImage}`"
            alt="Guest Image"
            :class="{ 'podcast-head__guest-img': true, 'podcast-head__guest-img-2': podcast.additionalGuestImage }"
          >
        </div>
        <div
          :class="{ 'col-md-6': podcast.additionalGuestImage, 'col-md-7': !podcast.additionalGuestImage }"
        >
          <div class="podcast-head__heading">
            <h1 class="podcast-head__heading-title">
              {{ formatName }} {{ $t('signup.with') }}
            </h1>
            <h1 class="podcast-head__heading-guest">
              {{ formatGuestName }}
            </h1>
            <h1
              v-if="podcast.additionalGuestName"
              class="podcast-head__heading-guest"
            >
              {{ $t('code.and') }} {{ formatAdditionalGuestName }}
            </h1>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { i18n } from 'app/core/utils'
export default {
  name: 'SinglePodcastHeadComponent',
  props: {
    podcast: {
      type: Object,
      required: true
    }
  },
  computed: {
    formatName () {
      return i18n(this.podcast, 'name')
    },
    formatGuestName () {
      return i18n(this.podcast, 'guestName')
    },
    formatAdditionalGuestName () {
      return i18n(this.podcast, 'additionalGuestName')
    }
  }
}
</script>

<style scoped lang="scss">
@import "app/styles/bootstrap/variables";

.podcast-head {

  &__guest {
    text-align: center;

    &-img {
      max-width: 100%;
      height: 25rem;

      &-2 {
        max-width: 45%;
      }
    }
  }

  &__heading {
    word-spacing: .8rem;
    letter-spacing: .2rem;
    &-title {
      width: 90%;
    }
    &-guest {
      font-weight: bold;
    }

    @media (max-width: $screen-md-min) {
      margin-top: 2rem;
      letter-spacing: .1rem;

      &-title, &-guest {
        font-size: 3.5rem;
      }
    }
  }

}
</style>
