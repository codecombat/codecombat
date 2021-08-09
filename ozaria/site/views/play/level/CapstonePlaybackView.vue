<template>
<div id="capstone-playback-view" v-bind:style="{ display: isPlaying ? 'none': ''}">
  <button @click="clickedPlay"> {{$t("common.play") }} </button>
</div>
</template>

<script>
import store from 'core/store'

module.exports = Vue.extend({
  mounted() {
    Backbone.Mediator.subscribe('surface:frame-changed', this.onFrameChanged, this)
    Backbone.Mediator.subscribe('tome:cast-spells', this.onTomeCast, this)
    Backbone.Mediator.subscribe('playback:real-time-playback-ended', this.onRealTimePlaybackEnded, this)
    Backbone.Mediator.subscribe('playback:stop-real-time-playback', this.onStopRealTimePlayback, this)
  },
  beforeDestroy () {
    Backbone.Mediator.unsubscribe('surface:frame-changed', this.onFrameChanged, this)
    Backbone.Mediator.unsubscribe('tome:cast-spells', this.onTomeCast, this)
    Backbone.Mediator.unsubscribe('playback:real-time-playback-ended', this.onRealTimePlaybackEnded, this)
    Backbone.Mediator.unsubscribe('playback:stop-real-time-playback', this.onStopRealTimePlayback, this)
  },
  data: () => ({
    worldCompletelyLoaded: false,
    realTime: false,
    lastProgress: 0,
    wasEnded: false,
    isPlaying: false,
  }),
  watch: {
    isPlaying (newPlay, oldPlay) {
      // Toggle Vega message so it isn't visible while capstone is playing.
      if (!oldPlay && newPlay) {
        $('#level-dialogue-view').addClass("hidden")
        $('#level-view #canvas-wrapper').addClass("undo-vega-spacing")
      } else if (oldPlay && !newPlay) {
        $('#level-dialogue-view').removeClass("hidden")
        $('#level-view #canvas-wrapper').removeClass("undo-vega-spacing")
      }
    }
  },
  methods: {
    clickedPlay() {
      store.dispatch('game/setHasPlayedGame', true)
      Backbone.Mediator.publish('tome:manual-cast', { realTime: true })
      Backbone.Mediator.publish('level:set-playing', { playing: true })
    },

    onFrameChanged(e) {
      const {progress, world} = e
      if (progress !== this.lastProgress) {
        const wasLoaded = this.worldCompletelyLoaded
        let ended = false
        this.worldCompletelyLoaded = world.frames.length === world.totalFrames
        if (this.worldCompletelyLoaded && !wasLoaded) {
          this.isPlaying = false
          Backbone.Mediator.publish('playback:real-time-playback-ended', {})
          Backbone.Mediator.publish('level:set-letterbox', { on: false })
        }

        if (this.worldCompletelyLoaded && progress >= 0.99 && this.lastProgress < 0.99) {
          ended = true
          this.isPlaying = false
          Backbone.Mediator.publish('level:set-letterbox', { on: false })
          Backbone.Mediator.publish('playback:real-time-playback-ended', {})
          Backbone.Mediator.publish('playback:playback-ended', {})
        }

        if (progress < 0.99 && this.lastProgress >= 0.99) {
          ended = false
          this.isPlaying = true
        }

        if (this.wasEnded !== ended) {
          this.wasEnded = ended
          Backbone.Mediator.publish('playback:ended-changed', { ended })
        }
      }
    },

    onStopRealTimePlayback(e) {
      this.isPlaying = false
      Backbone.Mediator.publish('level:set-letterbox', {on: false})
      Backbone.Mediator.publish('playback:real-time-playback-ended', {})
    },

    onRealTimePlaybackEnded(e) {
      if (!this.realTime) {
        return
      }
      this.realTime = false
      this.isPlaying = false
    },

    onTomeCast(e) {
      if (e.realTime !== true) {
        return
      }
      this.realTime = true
      this.isPlaying = true
      Backbone.Mediator.publish('playback:real-time-playback-started', {})
    }
  }
})
</script>

<style lang="scss" scoped>
@import "app/styles/mixins";
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/play/variables";
@import "ozaria/site/styles/play/images";

#capstone-playback-view {
  width: $game-view-width;
  padding-top: 0.5%;
  padding-bottom: 0.5%;
  position: absolute;
  bottom: 0px;
  background-color: black;
  z-index: 3;
  text-align: center;

  button {
    background-image: url($Button);
    text-align: center;
    background-position: center;
    margin: 1% 0;
    padding: 9px 36px;
    background-size: contain;
    background-color: black;
    background-repeat: no-repeat;
    border: none;
    font-family: "Work Sans";
    font-size: 17px;
    font-weight: bold;
    letter-spacing: 0.77px;
    line-height: 20px;
    text-transform: uppercase;
    color: #215055;

    &:hover:not(:disabled) {
      background-image: url($ButtonHover);
    }
  }
}
</style>
