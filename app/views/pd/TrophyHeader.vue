<template>
  <div class="trophy-header">
    <h2 class="text-h2">
      {{ $t('pd_page.trophy_header') }}
    </h2>
    <div class="header">
      <div class="goblet goblet-bronze">
        <a
          href="#implementation"
          class="trophy-button btn btn-lg btn-teal"
        >{{
          $t('pd_page.implementation_training_title')
        }}</a>
      </div>
      <div class="goblet goblet-silver">
        <a
          href="#professional"
          class="trophy-button btn btn-lg btn-teal"
        >
          <div
            v-for="(line, lineIndex) in $t('pd_page.professional_development_title').split('[NEWLINE]')"
            :key="`line-${lineIndex}`"
          >
            {{ line }}
          </div>

        </a>
      </div>
      <div class="goblet goblet-gold">
        <a
          href="#apcsp"
          class="trophy-button btn btn-lg btn-teal"
        >
          <img
            src="/images/pages/apcsp/apcsp_logo.webp"
            class="ap-badge"
          >
          <div
            v-for="(line, lineIndex) in $t('pd_page.ap_csp_professional_development_title').split('[NEWLINE]')"
            :key="`line-${lineIndex}`"
          >
            {{ line }}
          </div>
        </a>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'TrophyHeader',
}
</script>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import 'ozaria/site/styles/common/variables.scss';
@import 'app/styles/ozaria/_ozaria-style-params.scss';
@import 'app/styles/common/_button.scss';

.text-h2 {
  color: $color-tertiary-brand;
  text-align: center;
  font-family: "Work Sans";
  font-size: 24px;
  font-style: normal;
  font-weight: 600;
  line-height: normal;
  letter-spacing: 0.56px;
  margin: 20px auto 40px;
}

.header {
  background: url(/images/pages/pd/moon-line.svg);
  background-repeat: no-repeat;
  background-size: contain;
  background-position: center 40px;

  display: flex;
  flex-direction: row;
  justify-content: space-between;
  gap: 20px;
  padding: 0 50px;

  @media screen and (max-width: $screen-sm) {
    gap: 10px;
    padding: 0 0;
  }

  .goblet {
    flex: 1;
    filter: drop-shadow(0px 5px 5px #fff);

    &.goblet-bronze {
      background-image: url(/images/pages/pd/bronze-trophy.png);
      background-size: 70px;
    }

    &.goblet-silver {
      background-image: url(/images/pages/pd/silver-trophy.png);
      background-size: 80px;
    }

    &.goblet-gold {
      background-image: url(/images/pages/pd/gold-trophy.png);
      background-size: 90px;
    }

    padding-top: 100px;
    background-position: top center;
    background-repeat: no-repeat;
    text-align: center;

    .trophy-button {
      max-width: 360px;
      display: inline-flex;
      padding: 20px 30px;

      @media screen and (max-width: $screen-sm) {
        padding: 10px 5px;
      }

      justify-content: center;
      align-items: center;
      flex-direction: column;
      gap: 5px;
      border-radius: 30px;
      position: relative;
      white-space: normal;

      color: $pitch;
      font-family: "Work Sans";
      font-size: 16px;
      font-style: normal;
      font-weight: 600;
      line-height: 108%;

      @media screen and (max-width: $screen-sm) {
        font-size: 12px;
        gap: 5px;
        border-radius: 15px;
      }

      .ap-badge {
        position: absolute;
        top: -35px;
        width: 70px;
        height: 70px;
        right: -35px;

        @media screen and (max-width: $screen-sm) {
          top: -10px;
          width: 30px;
          height: 30px;
          right: -10px;
        }
      }
    }
  }
}
</style>
