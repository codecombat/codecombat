<script>
  import { mapGetters, mapActions } from 'vuex'

  export default {
    props: {
      title: {
        type: String,
        default: ''
      },

      chromeOn: {
        type: Boolean,
        default: false
      },

      optionsClickHandler: {
        type: Function
      },

      restartClickHandler: {
        type: Function
      }
    },

    computed: {
      ...mapGetters('ozariaOptions', [
        'isSoundOn'
      ])
    },

    methods: {
      ...mapActions('ozariaOptions', ['toggleSoundAction']),

      clickOptions () {
        if (this.optionsClickHandler) {
          this.optionsClickHandler()
        }
      },

      clickRestart () {
        if (this.restartClickHandler) {
          this.restartClickHandler()
        }
      }
    }
  }
</script>

<template>
  <div class="chrome-container">
    <div
      :class="[ 'chrome-border', chromeOn ? 'chrome-on-slice' : 'chrome-off-slice']"
    >
      <div id="chrome-menu">
        <div
          class="button-flex-item options-btn"
          :class="{ hideBtn: !optionsClickHandler }"
          @click="clickOptions"
        />
        <div
          class="button-flex-item restart-btn"
          :class="{ hideBtn: !restartClickHandler }"
          @click="clickRestart"
        />
        <div class="spacer" />
        <div class="button-flex-item map-btn" />
        <div
          class="button-flex-item sound-btn"
          :class="{ menuVolumeOff: !isSoundOn }"
          @click="toggleSoundAction" />
      </div>

      <div :class="[ chromeOn ? 'side-center-on' : 'side-center-off']" />

      <div v-if="title">
        <div id="text-tab">
          <div class="text-contents">
            <span>{{ title }}</span>
          </div>
        </div>
      </div>
    </div>

    <slot />
  </div>
</template>

<style lang="sass" scoped>
  @import "ozaria/site/styles/common/variables.sass"
  $topOffset: 25px

  .chrome-container
    position: fixed

    top: 0
    left: 0
    right: 0
    bottom: 0

    padding: $chromeTopPadding $chromeRightPadding $chromeBottomPadding $chromeLeftPadding

    // Use pointer events to allow mouse to click buttons.
    pointer-events: none

    & > *
      pointer-events: auto

  .chrome-border
    position: absolute

    top: 0
    left: 0
    right: 0
    bottom: 0

    pointer-events: none
    z-index: 10

    &.chrome-on-slice
      border-image: url('/images/ozaria/layout/chrome/Layout-Chrome-on.png')

    &.chrome-off-slice
      border-image: url('/images/ozaria/layout/chrome/Layout-Chrome-off.png')

    &.chrome-off-slice, &.chrome-on-slice
      border-image-slice: 182 194 130 118 fill
      border-image-width: 140px 148px 124px 90px
      border-image-repeat: round

    .side-center-on
      background: url(/images/ozaria/layout/chrome/central_on.png)

    .side-center-off
      background: url(/images/ozaria/layout/chrome/central_off.png)

    .side-center-off, .side-center-on
      width: 75px
      height: 100%
      overflow: hidden
      position: absolute
      right: 0
      top: $topOffset
      background-position: center
      background-size: contain
      background-repeat: no-repeat

    #chrome-menu
      display: flex
      flex-direction: column
      justify-content: space-around
      width: 58px
      height: 80vh
      position: absolute
      top: calc(10vh + #{$topOffset})
      right: 0
      pointer-events: auto
      .button-flex-item
        width: 58px
        height: 58px
        margin: 10px 0

      .spacer
        flex-grow: 1

      .hideBtn
        visibility: hidden

      .options-btn
        background: url(/images/ozaria/layout/chrome/button_settings.png)

      .restart-btn
        background: url(/images/ozaria/layout/chrome/button_replay.png)

      .map-btn
        background: url(/images/ozaria/layout/chrome/button_map.png)

      .sound-btn
        background: url(/images/ozaria/layout/chrome/button_sound.png)

        &.menuVolumeOff
          // Temp until we have icon
          filter: grayscale(100%)

      .options-btn, .restart-btn, .map-btn, .sound-btn
        background-size: 45px
        background-position: center
        background-repeat: no-repeat

    #text-tab
      background: url(/images/ozaria/layout/chrome/Tab-Title.png)
      background-position-x: center
      background-repeat: no-repeat

      .text-contents
        text-align: center
        color: #48FAFC
        padding: 12px 0
        height: 30px

  #btn-home
    position: fixed
    right: 0
    top: 50%
    transform: translate(0, -50%) scale(0.5)

  #btn-top
    position: fixed
    right: 0
    top: 50%
    transform: translate(0, -50%) translate(-4px, -60px) scale(0.5)

  #btn-bottom
    position: fixed
    right: 0
    top: 50%
    transform: translate(0, -50%) translate(-4px, 60px) scale(0.5)

</style>
