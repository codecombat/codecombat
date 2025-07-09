<template>
  <div class="new-league-page">
    <header-component />
    <GlobalRankings />
    <GetStarted />
    <CompeteToWin />
    <SeasonArenas />
    <Inspiration />
  </div>
</template>

<script>
import Header from './components/Header.vue'
import GlobalRankings from './components/GlobalRankings.vue'
import GetStarted from './components/GetStarted.vue'
import CompeteToWin from './components/CompeteToWin.vue'
import SeasonArenas from './components/SeasonArenas.vue'
import Inspiration from './components/Inspiration.vue'

export default {
  components: {
    'header-component': Header,
    GlobalRankings,
    GetStarted,
    CompeteToWin,
    SeasonArenas,
    Inspiration,
  },
}
</script>

<style scoped lang="scss">
$primary-color: #4DECF0;
$primary-background: #31636F;
::v-deep * {
  font-family: Plus Jakarta Sans;
}
::v-deep div{
  color: white;

  &.heading {
    color: $primary-color;
  }
}
::v-deep p {
  color: white;
  &.description {
    color:  #B4B4B4;
  }
}
::v-deep .CTA {
  $black: #0A2239;

  &__button {
    color: $black !important;
    background-color: $primary-color;
    text-shadow: unset !important;
    font-weight: bold;

    &:hover {
      background-color: lighten($primary-color, 10%);

      [style*="--type: no-background"] & {
        background-color: rgba($primary-color, 0.3)
      }
    }

  }
}
</style>