<template>
  <div class="podcast-head">
    <div class="container">
      <div class="row">
        <div class="col-sm-5">
          <div class="podcast-head__adventure">
            <img src="/images/pages/podcast/edtech-adventure.jpg" alt="Edtech adventure" class="podcast-head__adventure-img">
          </div>
        </div>
        <div class="col-sm-7 podcast-head__text">
          <h2 class="podcast-head__heading">
            {{ $t('podcast.learning_adventure') }}
          </h2>
          <div class="podcast-head__subheading">
            {{ $t('podcast.explores_stem') }}
          </div>
          <div class="podcast-head__subscribe">
            <button class="btn btn-subscribe podcast-btn-yellow">{{ $t('podcast.subscribe') }}</button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'HeadComponent'
}
</script>

<style scoped lang="scss">
@import "app/styles/podcast/variables";
@import "app/styles/podcast/common";

.podcast-head {
  padding: 7rem;

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
