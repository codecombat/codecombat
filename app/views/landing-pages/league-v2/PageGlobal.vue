<template>
  <div class="new-league-page">
    <HeaderComponent />
    <GlobalRankings />
    <GetStarted />
    <CompeteToWin />
    <SeasonArenas />
    <Inspiration />
    <SetUpTournament />
  </div>
</template>

<script>
import HeaderComponent from './components/Header.vue'
import GlobalRankings from './components/GlobalRankings.vue'
import GetStarted from './components/GetStarted.vue'
import CompeteToWin from './components/CompeteToWin.vue'
import SeasonArenas from './components/SeasonArenas.vue'
import Inspiration from './components/Inspiration.vue'
import SetUpTournament from './components/SetUpTournament.vue'

export default {
  name: 'LeaguePageGlobalV2',
  components: {
    HeaderComponent,
    GlobalRankings,
    GetStarted,
    CompeteToWin,
    SeasonArenas,
    Inspiration,
    SetUpTournament,
  },
}
</script>

<style scoped lang="scss">
@import "app/styles/bootstrap/variables";
@import "app/styles/component_variables.scss";

$primary-color: #4DECF0;
$primary-background: #31636F;
::v-deep * {
  font-family: Plus Jakarta Sans;
}
::v-deep .section {
  color: white;
  padding-top: 40px;
  padding-bottom: 20px;
}
::v-deep .heading{
  color: white;
}
::v-deep .content {
  @extend %font-20;
  margin-bottom: 20px;
  color:  #B4B4B4;
  text-align: center;
}
::v-deep p {
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