<script>
  import store from 'app/core/store'
  import { mapState } from 'vuex'
  import visualChalkboardModule from './visualChalkboardModule'

  /**
   * Converts a string such as "3 &lt; 2" into "3 < 2".
   * Reference: https://stackoverflow.com/a/7394787
   * @param {string} text
   * @returns {string} Text with escaped values decoded
   */
  function decodeHtml (text) {
    const txt = document.createElement('textarea')
    txt.innerHTML = text
    return txt.value
  }

  export default {
    data: () => ({
      displayed: false,
      displayInterval: null
    }),
    computed: {
      ...mapState({
        html: state => (state.visualChalkboard || {}).chalkboardHtml || '',
        chalkboardWidth: state => (state.visualChalkboard || {}).width || 45,
        chalkboardHeight: state => (state.visualChalkboard || {}).height || 80,
        xOffset: state => {
          // This getter returns either the onscreen xOffset or the value xOffsetHiddenOverride
          // that triggers the chalkboard to move off the screen.
          const xOffset = (state.visualChalkboard || {}).xOffset || 0
          const xOffsetHiddenOverride = (state.visualChalkboard || {}).xOffsetHiddenOverride || 0
          if (xOffsetHiddenOverride !== 0) {
            return xOffsetHiddenOverride
          } else {
            return xOffset
          }
        },
        yOffset: state => (state.visualChalkboard || {}).yOffset,
        transitionTime: state => (state.visualChalkboard || {}).transitionTime || 0
      }),

      compiledHtml () {
        return decodeHtml(this.html)
      }
    },

    mounted () {
      store.registerModule('visualChalkboard', visualChalkboardModule())

      // Hack: Fixes chalkboard flying across screen when loading
      this.displayInterval = setTimeout(() => { this.displayed = true }, 1200)
    },

    beforeDestroy () {
      clearInterval(this.displayInterval)
      store.unregisterModule('visualChalkboard')
    }
  }
</script>

<template>
  <div id="cinematic-chalkboard-container">
    <!-- TODO: Refactored to use vue transitions? -->
    <div
      v-if="displayed"
      id="chalkboard-modal"
      :style="{
        width: `${chalkboardWidth}%`,
        height: `${chalkboardHeight}%`,
        transform: `translateX(${xOffset}%) translateY(${yOffset}%)`,
        transition: `transform ${transitionTime}s`
      }"
    >
      <div id="chalkboard">
        <div class="chalkboard-decoration-container">
          <div class="chalkboard-decoration" />
        </div>
        <div
          id="markdown-contents"
          v-html="compiledHtml"
        />
      </div>
    </div>
  </div>
</template>

<style lang="scss">
#chalkboard-modal img {
  max-width: 80%;
  height: auto;
}
</style>

<style lang="scss">
  #markdown-contents {
    font-size: 24px;
    line-height: 28px;
    font-weight: normal;
    padding: 0.2vh 0.2vw;
    p {
      margin-bottom: 0;
    }
    span {
      font-size: 2vmax;
    }
  }
</style>

<style lang="scss" scoped>
#cinematic-chalkboard-container {
  width: 100%;
  height: 100%;
  position: absolute;
  z-index: 1;

  display: flex;
  justify-content: center;
  align-items: center;

  overflow: hidden;

  #chalkboard-modal {
    width: 50%;
    height: 80%;

    display: flex;
    flex-direction: column;
  }

  #markdown-contents {
    width: 100%;
    height: 100%;

    display: flex;
    justify-content: center;
    align-content: center;
    flex-direction: column;
    text-align: center;
  }

  #markdown-contents ::v-deep .rich-text-content {
    display: flex;
    justify-content: center;
    align-content: center;
    flex-direction: column;
    text-align: left;
    padding: 20px;
    white-space: pre;
    height: 100%;
    width: 100%
  }

  #chalkboard {
    position: relative;
    min-height: 70%;
    width: 100%;

    border-image: url('/images/ozaria/cinematic/CN_Acodus.png');
    background-color: white;
    border-image-slice: 200 183 170 151 fill;
    border-image-width: 5rem 5.5rem 5rem 4.5rem;
    border-image-outset: 2.7rem 4.7rem 3rem 3rem;
    border-image-repeat: repeat;

    .chalkboard-decoration-container {
      position: absolute;
      height: 100%;
      width: 100%;
      display: flex;
      justify-content: flex-end;
      align-items: center;
      transform: translateX(4.4rem);

      .chalkboard-decoration {
        background-image: url('/images/ozaria/cinematic/CN_Acodus_Sticker.png');
        width: 3vw;
        height: 7vh;
        background-size: contain;
        background-position: center;
        background-repeat: no-repeat;
      }
    }

  }
}
</style>
