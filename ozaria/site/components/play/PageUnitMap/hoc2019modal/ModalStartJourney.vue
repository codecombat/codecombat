<script>
import CloseModalBar from './layout/CloseModalBar'
import * as focusTrap from 'focus-trap'

export default Vue.extend({
  components: {
    CloseModalBar
  },
  data: () => ({
    focusTrapDeactivated: false,
    focusTrap: null
  }),
  mounted () {
    // TODO: do this generally for all modals
    this.focusTrap = focusTrap.createFocusTrap(this.$el, {
      initialFocus: '.btn-primary',
      onDeactivate: () => {
        this.focusTrapDeactivated = true
      }
    })
    this.focusTrap.activate()
    // fallback
    if (this.focusTrapDeactivated) this.deactivateFocusTrap()
  },
  beforeDestroy () {
    // seems not work when this component is destroyed by parent conditional-render
    this.deactivateFocusTrap()
  },
  methods: {
    deactivateFocusTrap () {
      this.focusTrapDeactivated = true
      this.focusTrap?.deactivate()
    }
  }
})
</script>

<template>
  <div id="start-journey">
    <div class="hero-img">
      <CloseModalBar @click="$emit('closeModal')"/>
      <div class="heading-bar">
        <img src="/images/pages/modal/hoc2019/blackOzariaWordmark.png">
        <h2>{{$t("hoc_2019.heading")}}</h2>
      </div>
    </div>
    <div class="center-row">
      <h1>{{$t("hoc_2019.start")}}</h1>
      <button @click="$emit('clickEducator')" class="btn btn-large btn-primary btn-moon">{{$t("hoc_2018_interstitial.educator")}}</button>
      <button @click="$emit('clickStudent')" class="btn btn-large btn-primary btn-moon">{{$t("hoc_2018_interstitial.student")}}</button>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

#start-journey {
  width: 1110px;
  height: 573px;
  background-color: $pitch;
  box-shadow: -20px -10px 50px 0 rgba(64,243,228,0.3), 20px 10px 50px 0 rgba(64,243,228,0.3);
  border-radius: 25px;

  .hero-img {
    background-image: url(/images/pages/modal/hoc2019/banner-image.png);
    background-size: contain;
    background-repeat: no-repeat;
    height: 360px;
    width: 100%;
  }

  h1 {
    @include font-h-1-title-font-white;
    font-size: 44px;
    font-weight: bold;
    line-height: 40px;
    letter-spacing: 3.5px;
    margin: 37px 0 30px 0;
    font-variant: normal;
  }
}

.btn-primary.btn-moon {
  background-color: $moon;
  border-radius: 1px;
  color: $gray;
  text-shadow: unset;
  font-weight: bold;
  @include font-h-5-button-text-black;
  min-width: 260px;
  padding: 15px 0;
  background-image: unset;
  margin: 0 15px;

  &:hover {
    @include font-h-5-button-text-white;
    background-color: $goldenlight;
    transition: background-color .35s;
  }
}

.center-row {
  text-align: center;
}

.heading-bar {
  display: flex;
  justify-content: center;
  align-items: center;

  img {
    width: 300px;
    margin-right: 7.5px;
  }

  h2 {
    font-family: Work Sans;
    color: $pitch;
    font-size: 44px;
    font-weight: 600;
    letter-spacing: 0.88px;
    line-height: 38px;

    margin: 0;
    margin-left: 7.5px;
    display: inline-block;
    font-variant: normal;
  }
}
</style>
