<script>

import { currentRegularArena } from 'app/core/store/modules/seasonalLeague'

export default {
  name: 'AILeagueResources',
  data () {
    return {
      regularArenaSlug: currentRegularArena ? currentRegularArena.slug : null,
    }
  }
}
</script>

<template>
  <div class="resources">
    <a
      class="resources__item screen"
      href="https://docs.google.com/presentation/d/1ouDOu2k-pOxkWswUKuik7CbrUCkYXF7N_jNjGO0II6o/edit#slide=id.gb06b5c7fa4_0_10"
      target="_blank"
    >
      {{ $t('league.teacher_getting_started_guide') }}
    </a>
    <a
      class="resources__item view-exemplar"
      :href="`https://codecombat.com/play/ladder/${regularArenaSlug ? regularArenaSlug : ''}`"
      target="_blank"
    >
      {{ $t('league.try_ai_league_as_a_teacher') }}
    </a>
    <a
      class="resources__item view-exemplar"
      href="https://codecombat.zendesk.com/hc/en-us/categories/1500000915842-AI-League"
      target="_blank"
    >
      {{ $t('nav.faqs') }}
    </a>
  </div>
</template>

<style scoped lang="scss">

.resources {
  display: flex;
  flex-direction: column;
  gap: 20px;

  &__item {
    display: flex;
    align-items: center;
    justify-content: flex-start;
    border-radius: 8px;
    border: 1px solid #476FB1;
    background: white;
    padding: 0 20px;
    height: 50px;

    color: #000;

    font-feature-settings: 'clig' off, 'liga' off;
    font-family: "Work Sans";
    font-size: 16px;
    font-style: normal;
    font-weight: 600;
    line-height: 17px;
    position: relative;

    &:after {
      position: absolute;
      content: '';
      display: block;
      width: 30px;
      height: 30px;
      background-image: url(/images/ozaria/teachers/dashboard/svg_icons/Icon_ViewExemplar.svg);
      background-color: #F7D047;
      background-repeat: no-repeat;
      background-position: 4px 2px;
      top: -15px;
      right: -15px;
      border-radius: 5px;
    }

    &.screen:after {
      background-image: url(/images/ozaria/teachers/dashboard/svg_icons/Icon_Screen.svg);
      background-color: #157A6C;
    }
  }
}
</style>