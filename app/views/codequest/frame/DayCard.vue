<template>
  <div
    class="day"
    :class="{'for-all': forAll}"
  >
    <div
      class="content"
      :class="{'for-all': forAll}"
    >
      <div class="frame">
        <div class="title">
          {{ dayTitle }}
        </div>
        <div class="text-wrapper">
          {{ date }}
        </div>
      </div>
      <div
        v-if="forAll"
        class="participants for-all"
      >
        {{ $t('codequest_page.all_participants') }}
      </div>
      <div
        v-else
        class="participants"
      >
        {{ $t('codequest_page.international_participants') }}
      </div>
      <div class="div">
        <div :class="['title', titleClass]">
          {{ eventTitle }}
        </div>
        <div class="text-wrapper">
          {{ eventSubtitle }}
        </div>
      </div>
      <img
        class="img"
        alt="Frame"
        :src="imageSrc"
      >
    </div>
  </div>
</template>

<script>
export default {
  name: 'DayCard',
  props: {
    dayTitle: String,
    date: String,
    eventTitle: String,
    eventSubtitle: String,
    imageSrc: String,
    titleClass: String,
    forAll: Boolean
  }
}
</script>

<style scoped lang="scss">
@import "app/styles/bootstrap/variables";
.day {
    align-items: center;
    border-radius: 24px;
    box-shadow: 0px 0px 22px #00000026;
    display: flex;
    flex-direction: column;
    position: relative;

    &.for-all {
        @media (min-width: $screen-lg) {
            &:nth-child(3) .content {
                border-radius: 24px 0 0 24px;
                border-right: none;
                margin-left: 30px;
            }
            &:nth-child(4) .content {
                border-radius: 0;
                border-right: none;
                border-left: none;
            }

            &:nth-child(5) .content {
                border-radius: 0 24px 24px 0;
                border-left: none;
                margin-right: 30px;
            }
        }
    }
}

.content {
    align-items: center;
    background:  linear-gradient(100deg, #F9F9FF 0%, #FFF 100%);
    border-radius: 24px;
    display: flex;
    flex: 0 0 auto;
    flex-direction: column;
    position: relative;
    width: 100%;
    padding-bottom: 40px;
    overflow: hidden;
    &.for-all {
        border: 2px solid #4799A9;
        @media (min-width: $screen-lg) {
            width: calc(100% + 30px);
        }
    }
}

.frame {
    align-items: center;
    align-self: stretch;
    background-color: #BAF5F7;
    display: flex;
    flex: 0 0 auto;
    flex-direction: column;
    gap: 8px;
    padding: 16px 30px;
    position: relative;
    width: 100%;
}

.title {
    color: #111928;
    font-family: "Plus Jakarta Sans-Bold", Helvetica;
    font-size: 18px;
    font-weight: 700;
    letter-spacing: 0;
    line-height: 24px;
    margin-top: -1px;
    position: relative;
    white-space: nowrap;
    width: fit-content;
}

.text-wrapper {
    color: #111928;
    font-family: "Plus Jakarta Sans-Regular", Helvetica;
    font-size: 18px;
    font-weight: 400;
    letter-spacing: 0;
    line-height: 24px;
    position: relative;
    white-space: nowrap;
    width: fit-content;
}

.participants {
    color: #111928;
    text-align: center;
    font-family: "Plus Jakarta Sans-Regular", Helvetica;
    font-size: 12px;
    font-style: normal;
    font-weight: 700;
    line-height: 20px;
    background: #99E1E3;
    line-height: 20px;
    width: 100%;

    &.for-all {
        background: #4799A9;
        color: white;
    }
}

.div {
    align-items: center;
    align-self: stretch;
    display: flex;
    flex: 0 0 auto;
    flex-direction: column;
    gap: 8px;
    padding: 16px 30px;
    position: relative;
    width: 100%;
}

.title-2 {
    color: #4799A9;
    font-family: "Plus Jakarta Sans-Bold", Helvetica;
    font-size: 18px;
    font-weight: 700;
    letter-spacing: 0;
    line-height: 24px;
    margin-top: -1px;
    position: relative;
    white-space: nowrap;
    width: fit-content;
}

.img {
    flex: 0 0 auto;
    position: relative;
}

.title-3 {
    color: #4799A9;
    font-family: "Plus Jakarta Sans-Bold", Helvetica;
    font-size: 18px;
    font-weight: 700;
    letter-spacing: 0;
    line-height: 24px;
    margin-left: -6px;
    margin-right: -6px;
    margin-top: -1px;
    position: relative;
    white-space: nowrap;
    width: fit-content;
}

.content-wrapper {
    align-items: center;
    border: 2px solid;
    border-color: #4799A9;
    border-radius: 24px;
    box-shadow: 0px 0px 22px #00000026;
    display: flex;
    flex-direction: column;
    margin-bottom: -2px;
    margin-top: -2px;
    overflow: hidden;
    position: relative;
    width: 174px;
}

.div-wrapper {
    align-items: center;
    border: 2px solid;
    border-color: #4799A9;
    border-radius: 24px;
    box-shadow: 0px 0px 22px #00000026;
    display: flex;
    flex-direction: column;
    overflow: hidden;
    position: relative;
    width: 170px;
}

.title-4 {
    color: #4799A9;
    font-family: "Plus Jakarta Sans-Bold", Helvetica;
    font-size: 18px;
    font-weight: 700;
    letter-spacing: 0;
    line-height: 24px;
    margin-left: -2.5px;
    margin-right: -2.5px;
    margin-top: -1px;
    position: relative;
    white-space: nowrap;
    width: fit-content;
}

.title-5 {
    color: #111928;
    font-family: "Plus Jakarta Sans-Regular", Helvetica;
    font-size: 18px;
    font-weight: 400;
    letter-spacing: 0;
    line-height: 24px;
    margin-left: -18px;
    margin-right: -18px;
    position: relative;
    white-space: nowrap;
    width: fit-content;
}
</style>
