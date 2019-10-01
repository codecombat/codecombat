<template>
  <div class="modal-content">
    <div class="modal-header">
      <div
        class="modal-header-content"
        style="text-align:center;"
      >
        <span class="title text-capitalize">
          {{ title }}
        </span>
      </div>
    </div>
    <div class="modal-body">
      <div class="narrative-row row">
        <div class="vega-face">
          <img
            class="vega-face-image"
            src="/images/ozaria/level/vega_face.png"
          >
        </div>
        <div class="narrative-div">
          <div class="narrative-speech-bubble">
            <span class="narrative-text"> {{ narrative }} </span>
          </div>
          <div class="learning-goals-div">
            <span class="learning-goals-title"> {{ $t("play_level.learning_goals") }}: </span>
            <span class="learning-goals"> {{ learningGoals }} </span>
          </div>
        </div>
      </div>
      <div class="button-row">
        <button
          class="ozaria-primary-button start-button"
          data-dismiss="modal"
          @click="onStart"
        >
          {{ $t("play_level.start") }}
        </button>
      </div>
    </div>
  </div>
</template>

<script>
  export default Vue.extend({
    name: 'LevelIntroModal',
    props: {
      levelName: {
        type: String,
        required: true
      },
      levelType: {
        type: String,
        required: true
      },
      narrative: {
        type: String,
        required: true
      },
      learningGoals: {
        type: String,
        required: true
      },
      onStart: {
        type: Function,
        required: true
      }
    },
    computed: {
      title: function () {
        return this.levelType + ' Level: ' + this.levelName
      }
    }
  })
</script>

<style lang="sass" scoped>
@import "ozaria/site/styles/common/variables.sass"

.modal-content
  width: 661px
  background-color: #d4d5d5

.modal-header
  padding: 25px 25px 0px 25px

  .title
    color: #0E4C60
    font-family: $title-font-style
    font-size: 33px
    font-weight: bold
    letter-spacing: 2.58px
    line-height: 62px

.modal-body
  padding: 20px

  .narrative-row
    padding: 0px 35px
    height: 246px

    .vega-face
      position: relative
      top: 100px
      left: -10px
      width: 17%

      .vega-face-image
        width: 100%
        height: 100%

    .narrative-div
      position: relative
      width: 92%
      height: 100%
      left: 40px
      top: -97px

      .narrative-speech-bubble
        height: 189px
        margin-left: 60px
        background-color: #eaeeee
        position: relative

        &::before
          position: absolute
          left: -13px
          top: 60px
          content: ""
          width: 50px
          height: 40px
          background: #eaeeee
          transform: skew(-60deg)

        .narrative-text
          position: absolute
          top: 0px
          width: 442px
          margin: 13px 15px
          font-family: $title-font-style
          font-size: 24px
          letter-spacing: 0.48px
          line-height: 32px
          color: #0e4c60

      .learning-goals-div
        background-color: #ffffff
        height: 57px
        position: absolute
        width: 88.8%
        left: 60px
        padding: 13px 13px

        .learning-goals-title
          color: #1fbab4
          font-family: $title-font-style
          font-size: 17px
          font-weight: bold
          letter-spacing: 0.59px
          line-height: 24px

        .learning-goals
          color: #232323
          font-family: $body-font-style
          font-size: 15px
          font-weight: 600
          letter-spacing: 0.51px
          line-height: 20px

  .button-row
    padding: 27px 0px 0px

    .start-button
      width: 182px
      height: 45px
      margin: 0px 220px
</style>
