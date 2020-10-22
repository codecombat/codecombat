<script>
  import { mapGetters, mapActions } from 'vuex'
  import SignupModal from 'ozaria/site/components/play/PageUnitMap/hoc2019modal'
  import { tryCopy } from '../../common/ozariaUtils'

  export default Vue.extend({
    components: {
      SignupModal
    },
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
    data: () => ({
      openSaveProgressModal: false
    }),
    computed: {
      ...mapGetters({
        soundOn: 'layoutChrome/soundOn',
        getMapUrl: 'layoutChrome/getMapUrl',
        isTeacher: 'me/isTeacher',
        isStudent: 'me/isStudent',
        isAnonymous: 'me/isAnonymous',
        classCode: 'classrooms/getMostRecentClassCode'
      }),

      mapLink () {
        if (!this.getMapUrl) {
          if (this.isTeacher) {
            return '/teachers/units'
          } else if (this.isStudent) {
            return '/students'
          } else {
            return '/'
          }
        }
        return this.getMapUrl
      },

      displaySaveProgressButton () {
        return !this.isTeacher && this.isAnonymous
      },

      showSaveProgressModal () {
        return this.openSaveProgressModal
      }
    },

    mounted () {
      // Check here if `show_hoc_progress_modal` has been set as true to show the progress modal
      // `hoc_progress_modal_time` is set in the unit map component
      // and since chrome is mounted before unit map, the condition will be false while on the unit map page
      // However it will be true if the user navigates to any level from the unit map, since chrome is mounted again on those pages
      if (window.sessionStorage.getItem('hoc_progress_modal_time') && this.isAnonymous) {
        this.showProgressModal = setInterval(() => {
          if (window.sessionStorage.getItem('show_hoc_progress_modal')) {
            this.openSaveProgressModal = true
            this.$emit('pause-cutscene')
            window.sessionStorage.removeItem('show_hoc_progress_modal')
            clearInterval(this.showProgressModal)
          }
        }, 60000) // every 1 min
      }
    },

    beforeDestroy () {
      if (this.showProgressModal) {
        clearInterval(this.showProgressModal)
      }
    },

    methods: {
      ...mapActions('layoutChrome', ['toggleSoundAction']),

      clickOptions () {
        this.$emit('click-options')
      },

      clickRestart () {
        this.$emit('click-restart')
      },

      closeSaveProgressModal () {
        this.openSaveProgressModal = false
      },

      clickSaveProgress () {
        this.openSaveProgressModal = true
        this.$emit('pause-cutscene')
      },

      // Inspired from CocoView toggleFullscreen method.
      toggleFullScreen () {
        const full = document.fullscreenElement ||
           document.mozFullScreenElement ||
           document.mozFullscreenElement ||
           document.msFullscreenElement ||
           document.webkitFullscreenElement

        if (!full) {
          const d = document.documentElement

          const req = d.requestFullscreen ||
                d.mozRequestFullScreen ||
                d.mozRequestFullscreen ||
                d.msRequestFullscreen ||
                d.webkitRequestFullscreen

          if (req) {
            req.call(d)
          }
        } else {
          const exitFullScreen = document.exitFullscreen ||
                document.mozCancelFullScreen ||
                document.mozCancelFullscreen ||
                document.webkitExitFullscreen ||
                document.msExitFullscreen
          if (exitFullScreen) {
            exitFullScreen.call(document)
          }
        }
      },

      copyClassCode () {
        this.$refs['classCodeRef'].select()
        tryCopy()
      }
    }
  })
</script>

<template>
  <div class="chrome-container">
    <div v-if="classCode" class="class-code-container">
      <label for="classCode" class="class-code-descriptor"> {{ $t("teachers.class_code") }} </label>
      <div class="class-code-text-container">
        <input
          id="classCode"
          class="class-code-text"
          ref="classCodeRef"
          :value="classCode"
          type="text"
          readonly
        />
      </div>
      <a @click="copyClassCode"><img src="/images/pages/modal/hoc2019/Copy.png" alt="Copy class code"/></a>
    </div>

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
        <div class="button-flex-item fullscreen-btn"
            v-tooltip="{
              content: $t('ozaria_chrome.max_browser'),
              placement: 'right',
              classes: 'layoutChromeTooltip',
            }"

            @click="toggleFullScreen" />
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

      <div id="text-tab">
        <div
          v-if="title"
          class="text-contents"
          :class="[ chromeOn ? 'chrome-on' : 'chrome-off']"
        >
          <span>{{ title }}</span>
        </div>
        <div
          v-if="displaySaveProgressButton"
          class="save-progress-div"
          @click="clickSaveProgress"
        >
          <span class="save-progress-text"> {{ $t("hoc_2019.save_progress") }} </span>
        </div>
      </div>
    </div>

    <div class="background-img">
      <slot />
    </div>

    <signup-modal
      v-if="showSaveProgressModal"
      class="save-progress-modal"
      :save-progress-modal="showSaveProgressModal"

      @closeModal="closeSaveProgressModal"
    />
  </div>
</template>

<style lang="sass" scoped>
  @import "ozaria/site/styles/common/variables.scss"
  $topOffset: 25px

  .class-code-container
    height: 30px
    width: 274px
    right: 10%
    top: 0.5%
    position: absolute
    display: flex
    z-index: 99999

    .class-code-text-container
      height: 28px
      width: 192px
      border-radius: 4px
      background-color: #231D1D
      box-shadow: inset 2px 2px 3px 0 rgba(0,0,0,0.5), inset -2px -2px 3px 0 #191213
      margin: 0 8px 0 8px
      text-align: center

    .class-code-descriptor
      height: 28px
      width: 42px
      color: #40F3E4
      font-family: "Space Mono"
      font-size: 12px
      font-style: italic
      letter-spacing: 0.24px
      line-height: 14px
      text-align: center

    .class-code-text
      height: 30px
      width: 164px
      color: #40F3E4
      font-family: "Work Sans"
      font-size: 18px
      letter-spacing: 0.36px
      line-height: 30px
      text-align: center
      // Turn off <input> style:
      background: transparent
      border: none
      outline: none

    img
      cursor: pointer
      height: 30px
      width: 24px

  .chrome-container
    position: fixed

    top: 0
    left: 0
    right: 0
    bottom: 0

    padding: $chromeTopPadding $chromeRightPadding $chromeBottomPadding $chromeLeftPadding

    .background-img
      // TODO: Swap out with higher resolution image.
      background-image: url(/images/ozaria/layout/chrome/AC_backer.png)
      background-position: center center
      background-size: cover
      background-repeat: no-repeat
      width: 100%
      height: 100%

    .save-progress-modal
      position: absolute
      top: 50%
      left: 50%
      transform: translate(-50%, -50%)

  .chrome-border
    position: absolute

    top: 0
    left: 0
    right: 0
    bottom: 0

    pointer-events: none
    z-index: 10

    &.chrome-on-slice
      border-image: url(/images/ozaria/layout/chrome/Layout-Chrome-on.png)

    &.chrome-off-slice
      border-image: url(/images/ozaria/layout/chrome/Layout-Chrome-off.png)

    &.chrome-off-slice, &.chrome-on-slice
      border-image-slice: 182 194 130 118 fill
      // vh and vw does not scale with browser zoom, creating more space when zoomed in
      border-image-width: 17vh 12vw 14vh 7vw
      border-image-repeat: round

    .side-center-on
      background: url(/images/ozaria/layout/chrome/central_on.png)

    .side-center-off
      background: url(/images/ozaria/layout/chrome/central_off.png)

    .side-center-off, .side-center-on
      width: 6.2vw
      height: 50vh
      overflow: hidden
      position: absolute
      right: 0
      top: 28vh
      background-position: center
      background-size: contain
      background-repeat: no-repeat

    #chrome-menu
      display: flex
      flex-direction: column
      justify-content: space-around
      width: 4.5vw
      height: 80vh
      position: absolute
      top: calc(10vh + #{$topOffset})
      right: 0
      pointer-events: auto
      .button-flex-item
        width: 7vh
        height: 7vh
        margin: 1vh -0.2vw
        cursor: pointer

      .spacer
        flex-grow: 1
        min-height: 20vh

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

      .fullscreen-btn
        background: url(/images/ozaria/layout/chrome/Global_Neutral_MaxBrowser.png)

        &:hover
          background: url(/images/ozaria/layout/chrome/Global_Hover_MaxBrowser.png)

      .sound-btn
        background: url(/images/ozaria/layout/chrome/Global_Neutral_SoundOn.png)

        &:hover
          background: url(/images/ozaria/layout/chrome/Global_Hover_SoundOn.png)

        &.menuVolumeOff
          background: url(/images/ozaria/layout/chrome/Global_Neutral_SoundOff.png)

        &.menuVolumeOff:hover
          background: url(/images/ozaria/layout/chrome/Global_Hover_SoundOff.png)

      .options-btn, .restart-btn, .map-btn, .sound-btn, .sound-btn.menuVolumeOff, .fullscreen-btn
        &, &:hover
          background-size: 100%
          background-position: center
          background-repeat: no-repeat

    #text-tab
      text-align: center

      .text-contents.chrome-off
        background: url(/images/ozaria/layout/chrome/Tab-Title-Off.png)
        background-position-x: center
        background-size: 100% 100%

      .text-contents.chrome-on
        background: url(/images/ozaria/layout/chrome/Tab-Title.png)
        background-position-x: center
        background-size: 100% 100%

      .text-contents
        display: inline-block
        color: #40F3E4
        padding: 1vh 7vw 2vh
        font-family: 'Open Sans', serif
        font-size: 4vh
        letter-spacing: 1.78px
        line-height: 24px
        text-shadow: 0 2px 4px rgba(51,236,201,0.55)
        min-width: 40vw

      .save-progress-div
        height: 28px
        width: 158px
        border-radius: 10px
        background-color: #231D1D
        box-shadow: inset 2px 2px 3px 0 rgba(0,0,0,0.5), inset -2px -2px 3px 0 #191213
        right: 13%
        top: 1%
        position: absolute
        cursor: pointer
        pointer-events: auto

        .save-progress-text
          height: 30px
          width: 128px
          color: $acodus-glow
          font-family: "Work Sans"
          font-size: 18px
          letter-spacing: 0.36px
          line-height: 30px
          text-align: center

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

  // Only prevent zooming at smaller screen sizes.
  // Sets px sizes for larger screens.
  @media only screen and (min-width: 1440px)
    .chrome-border
      &.chrome-off-slice, &.chrome-on-slice
        border-image-width: 140px 148px 124px 90px

      .side-center-off, .side-center-on
        width: 75px
        height: 100%
        top: $topOffset

      #chrome-menu
        width: 58px

        .button-flex-item
          width: 58px
          height: 58px
          margin: 3px 0

        .spacer
          min-height: 224px

        .options-btn, .restart-btn, .map-btn, .sound-btn, .sound-btn.menuVolumeOff, .fullscreen-btn
          background-size: 45px

</style>

<style lang='sass'>

  .tooltip.layoutChromeTooltip
    $chromeTooltipBackground: #74E8CA
    display: block !important
    z-index: 10000

    font-family: 'Open Sans', serif
    font-size: 16px

    box-shadow: 0px 3px 3px rgba(0,0,0,0.3)

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
      border-radius: 5px
      padding: 7px 12px 6px

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
