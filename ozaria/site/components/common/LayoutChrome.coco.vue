<script>
  import { mapGetters, mapActions } from 'vuex'

  export default Vue.extend({
    props: {
      title: {
        type: String,
        default: ''
      },

      chromeOn: {
        type: Boolean,
        default: false
      },

      displayOptionsMenuItem: {
        type: Boolean,
        default: false
      },

      displayRestartMenuItem: {
        type: Boolean,
        default: false
      }
    },

    computed: {
      ...mapGetters({
        soundOn: 'layoutChrome/soundOn',
        getMapUrl: 'layoutChrome/getMapUrl',
      }),

      mapLink () {
        if (me.isSessionless() || !this.getMapUrl) {
          return '/teachers/courses'
        }
        return this.getMapUrl
      }
    },

    methods: {
      ...mapActions('layoutChrome', ['toggleSoundAction']),

      clickOptions () {
        this.$emit('clickOptions')
      },

      clickRestart () {
        this.$emit('clickRestart')
      }
    }
  })
</script>

<template>
  <div class="chrome-container">
    <div
      :class="[ 'chrome-border', chromeOn ? 'chrome-on-slice' : 'chrome-off-slice']"
    >
      <div :class="[ chromeOn ? 'side-center-on' : 'side-center-off']" />

      <div id="chrome-menu">
        <div
          class="button-flex-item options-btn"
          :class="{ hideBtn: !displayOptionsMenuItem }"

          v-tooltip="{
            content: $t('ozaria_chrome.level_options'),
            placement: 'right',
            classes: 'layoutChromeTooltip',
          }"

          @click="clickOptions"
        />
        <div
          class="button-flex-item restart-btn"
          :class="{ hideBtn: !displayRestartMenuItem }"

          v-tooltip="{
            content: $t('ozaria_chrome.restart_level'),
            placement: 'right',
            classes: 'layoutChromeTooltip',
          }"

          @click="clickRestart"
        />
        <div class="spacer" />
        <a :href="mapLink">
          <div class="button-flex-item map-btn"
            v-tooltip="{
              content: $t('ozaria_chrome.back_to_map'),
              placement: 'right',
              classes: 'layoutChromeTooltip',
            }"
          />
        </a>
        <div
          class="button-flex-item sound-btn"
          :class="{ menuVolumeOff: soundOn }"

          v-tooltip="{
            content: soundOn
              ? $t('ozaria_chrome.sound_off')
              : $t('ozaria_chrome.sound_on'),
            placement: 'right',
            classes: 'layoutChromeTooltip'
          }"

          @click="toggleSoundAction" />
      </div>

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

  .chrome-container
    position: fixed

    top: 0
    left: 0
    right: 0
    bottom: 0

    padding: $chromeTopPadding $chromeRightPadding $chromeBottomPadding $chromeLeftPadding

  .chrome-border
    $topOffset: 25px
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
        background: url(/images/ozaria/layout/chrome/Global_Neutral_LevelOptions.png)

        &:hover
          background: url(/images/ozaria/layout/chrome/Global_Hover_LevelOptions.png)

      .restart-btn
        background: url(/images/ozaria/layout/chrome/Global_Neutral_Restart.png)

        &:hover
          background: url(/images/ozaria/layout/chrome/Global_Hover_Restart.png)
      .map-btn
        background: url(/images/ozaria/layout/chrome/Global_Neutral_Map.png)

        &:hover
          background: url(/images/ozaria/layout/chrome/Global_Hover_Map.png)
      .sound-btn
        background: url(/images/ozaria/layout/chrome/Global_Neutral_SoundOn.png)

        &:hover
          background: url(/images/ozaria/layout/chrome/Global_Hover_SoundOn.png)

        &.menuVolumeOff
          background: url(/images/ozaria/layout/chrome/Global_Neutral_SoundOff.png)

        &.menuVolumeOff:hover
          background: url(/images/ozaria/layout/chrome/Global_Hover_SoundOff.png)

      .options-btn, .restart-btn, .map-btn, .sound-btn, .sound-btn.menuVolumeOff
        &, &:hover
          background-size: 45px
          background-position: center
          background-repeat: no-repeat

    #text-tab
      text-align: center

      .text-contents
        display: inline-block
        color: #40F3E4
        padding: 10px 70px 30px
        font-family: 'Open Sans', serif
        font-size: 24px
        letter-spacing: 1.78px
        line-height: 24px
        text-shadow: 0 2px 4px rgba(51,236,201,0.55)

        background: url(/images/ozaria/layout/chrome/Tab-Title.png)
        background-position-x: center
        background-size: 100% 100%
        min-width: 370px

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

<style lang='sass'>

  .tooltip.layoutChromeTooltip
    $chromeTooltipBackground: #74E8CA
    display: block !important
    z-index: 10000

    font-family: 'Open Sans', serif
    font-size: 16px

    &[aria-hidden='true'] 
      visibility: hidden
      opacity: 0
      transition: opacity .15s, visibility .15s

    &[aria-hidden='false'] 
      visibility: visible
      opacity: 1
      transition: opacity .15s

    .tooltip-inner
      background: $chromeTooltipBackground
      color: black
      border-radius: 8px
      padding: 5px 10px 4px

    .tooltip-arrow
      width: 0
      height: 0
      border-style: solid
      position: absolute
      margin: 5px
      border-color: $chromeTooltipBackground
      z-index: 1

    &[x-placement^="left"]
      margin-right: 5px

      .tooltip-arrow
        border-width: 5px 0 5px 5px
        border-top-color: transparent !important
        border-right-color: transparent !important
        border-bottom-color: transparent !important
        right: -5px
        top: calc(50% - 5px)
        margin-left: 0
        margin-right: 0

    &[x-placement^="right"] 
      margin-left: 5px

      .tooltip-arrow 
        border-width: 5px 5px 5px 0
        border-left-color: transparent !important
        border-top-color: transparent !important
        border-bottom-color: transparent !important
        left: -5px
        top: calc(50% - 5px)
        margin-left: 0
        margin-right: 0

</style>
