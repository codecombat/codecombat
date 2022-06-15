<template>
  <div class="podcast-head">
    <div class="container">
      <div class="row">
        <div class="col-md-4 col-xs-4 podcast-head__guest">
          <img :src="`/file/${podcast.guestImage}`" alt="Guest Image" class="podcast-head__guest-img">
        </div>
        <div class="col-md-7 col-xs-8">
          <div class="podcast-head__heading">
            <h1 class="podcast-head__heading-title">
              {{ podcast.name }} {{ $t('signup.with') }}
            </h1>
            <h1 class="podcast-head__heading-guest">
              {{ podcast.guestName }}
            </h1>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'SinglePodcastHeadComponent',
  props: {
    podcast: {
      type: Object,
      required: true
    }
  }
}
</script>

<style scoped lang="scss">
.podcast-head {

  &__guest {
    text-align: center;

    &-img {
      max-width: 100%;
      height: 25rem;
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
  }

}
</style>
