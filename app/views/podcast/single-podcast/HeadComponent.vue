<template>
  <div class="podcast-head">
    <div class="container">
      <div class="row podcast-head__frame">
        <div class="col-md-offset-2 col-md-8">
          <iframe :src="transistorUrl"
                  width='100%' height='180' frameborder='0' scrolling='no'
                  seamless='true' style='width:100%; height:180px;'>
          </iframe>
        </div>
      </div>
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
  },
  computed: {
    transistorUrl () {
      return `https://share.transistor.fm/e/${this.podcast.transistorEpisodeId}/dark`
    }
  }
}
</script>

<style scoped lang="scss">
.podcast-head {

  &__frame {
    padding-bottom: 2rem;
  }

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
      width: 70%;
    }
    &-guest {
      font-weight: bold;
    }
  }

}
</style>
