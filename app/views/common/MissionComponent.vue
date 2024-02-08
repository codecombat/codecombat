<template>
  <div class="frame">
    <div class="text">
      <p class="title">
        {{ $t('home_v3.mission_title') }}
      </p>
      <p class="supporting-text">
        {{ $t('home_v3.mission_supporting_text') }}
      </p>
    </div>
    <div class="div">
      <StatCard
        img-src="/images/pages/home-v3/mission/vector-1.svg"
        :text="$t('home_v3.stat_card_1_text')"
        :description="$t('home_v3.stat_card_1_description')"
      />
      <StatCard
        img-src="/images/pages/home-v3/mission/image.svg"
        :text="$t('home_v3.stat_card_2_text')"
        :description="$t('home_v3.stat_card_2_description')"
      />
      <StatCard
        img-src="/images/pages/home-v3/mission/vector-2.svg"
        :text="$t('home_v3.stat_card_3_text')"
        :description="$t('home_v3.stat_card_3_description')"
      />
      <StatCard
        img-src="/images/pages/home-v3/mission/layer-1.svg"
        :text="$t('home_v3.stat_card_4_text')"
        :description="$t('home_v3.stat_card_4_description')"
      />
      <StatCard
        img-src="/images/pages/home-v3/mission/vector-3.svg"
        :text="$t('home_v3.stat_card_5_text')"
        :description="$t('home_v3.stat_card_5_description')"
      />
      <StatCard
        img-src="/images/pages/home-v3/mission/vector-4.svg"
        :text="$t('home_v3.stat_card_6_text')"
        :description="$t('home_v3.stat_card_6_description')"
      />
    </div>
  </div>
</template>

<script>
import StatCard from './StatCard.vue'

export default {
  name: 'MissionComponent',
  components: {
    StatCard
  }
}
</script>

<style scoped lang="scss">
@import "app/styles/component_variables.scss";

.frame {
  align-items: center;
  display: flex;
  flex-direction: row;
  gap: 32px;
  justify-content: center;
  margin: 0 auto;
  padding: 64px 0;
  position: relative;

  @media (max-width: 768px) {
    flex-direction: column;
    padding: 32px 0;
  }

  .text {
    flex: 1;
    align-items: center;
    display: flex;
    flex-direction: column;
    gap: 16px;
    position: relative;
  }

  .title {
    @extend %font-32-46;
    font-weight: 400;
    letter-spacing: 0;
    line-height: 48px;
    text-align: center;
    text-align: right;
  }

  .supporting-text {
    @extend %font-24-34;
    color: $light-grey;
    font-weight: 300;
    text-align: right;
  }

  .div {
    flex: 1;
    align-items: center;
    display: flex;
    flex-wrap: wrap;
    gap: 32px;
    justify-content: center;
    position: relative;
  }
}
</style>
