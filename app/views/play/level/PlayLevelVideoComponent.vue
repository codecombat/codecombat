<template lang="pug">
flat-layout
  .video-container.container
    .video-background.container
      .row.title-row
        .col-sm-12(v-if="videoData")
          h3.text-center.text-uppercase.video-title
            | {{ $t('play_level.concept_unlocked') }} : {{ $t(`courses.${videoData.i18name}`) }}
      .row.video-row
        .col-sm-12.video-col(v-if="videoData")
          iframe.video(
            :src="videoUrl"
            frameborder= "0" webkitallowfullscreen mozallowfullscreen allowfullscreen
          )
      .row.buttons-row
        .col-sm-6
          a#skip-btn(
            @click="onSkip",
            :href="nextLevelLink"
          )
            u {{ $t('play_level.skip') }}
        .col-sm-6.text-uppercase
          a#next-level-btn.btn-illustrated.btn-success.btn-block.btn-lg.btn(
            @click="onNextLevel",
            :href="nextLevelLink"
            v-show="false"
          )
            | {{ $t('play_level.next_level') }}
      img.img-unlocked(src = '/images/pages/play/modal/unlocked_banner.png')
</template>

<script>
import utils from 'core/utils'
import FlatLayout from 'core/components/FlatLayout'
import VideoPlayer from '@vimeo/player'

export default Vue.extend({
  props: {
    levelSlug: {
      type: String,
      required: true
    },
    courseInstanceID: {
      type: String,
      required: true
    },
    courseID: {
      type: String,
      required: true
    },
    codeLanguage: {
      type: String
    },
    levelOriginalID: {
      type: String,
      required: true
    }
  },

  metaInfo () {
    return {
      title: this.$t('play.video_title', { video: this.videoData.title }),
      link: [
        { vmid: 'rel-canonical', rel: 'canonical', content: '/play' }
      ]
    }
  },

  data: () => ({
    originalDisplaySettings: {}
  }),

  components: {
    'flat-layout': FlatLayout
  },

  mounted() {
    this.$nextTick(function () {
      if(!me.showChinaVideo()){
        const player = new VideoPlayer($('.video')[0]);
        player.on('ended', function() {
          $('#next-level-btn')[0].style.display = "block"
        })
      }
      // hack to remove base template's header and footer
      // store existing display settings to revert to these before leaving
      this.originalDisplaySettings = {
        'main-nav': $('#main-nav')[0]? $('#main-nav')[0].style.display : "",
        'footer': $('#footer')[0]? $('#footer')[0].style.display : "",
        'final-footer': $('#final-footer')[0]? $('#final-footer')[0].style.display: ""
      }
      if ($('#main-nav')[0])  $('#main-nav')[0].style.display = "none"
      if ($('#footer')[0])  $('#footer')[0].style.display = "none"
      if ($('#final-footer')[0])  $('#final-footer')[0].style.display = "none"
    })
  },

  beforeDestroy () {
    // make header and footer visible again before leaving
    if ($('#main-nav')[0])  $('#main-nav')[0].style.display = this.originalDisplaySettings['main-nav']
    if ($('#footer')[0])  $('#footer')[0].style.display = this.originalDisplaySettings['footer']
    if ($('#final-footer')[0])  $('#final-footer')[0].style.display = this.originalDisplaySettings['final-footer']
  },

  computed: {
    videoData: function () {
      return utils.videoLevels[this.levelOriginalID] || {}
    },

    videoUrl: function () {
      return me.showChinaVideo() ? this.videoData.cn_url : this.videoData.url
    },

    nextLevelLink: function () {
      let link = ''
      if (me.isSessionless()){
        link = "/play/level/"+this.levelSlug+"?course="+this.courseID+"&codeLanguage="
        link += this.codeLanguage || 'python'
      }
      else {
        link = "/play/level/"+this.levelSlug+"?course="+this.courseID+"&course-instance="+this.courseInstanceID
        if (this.codeLanguage){
          link += "&codeLanguage=" + this.codeLanguage
        }
      }
      return link
    }
  },

  methods: {
    onNextLevel: function() {
      if (window.tracker){
        window.tracker.trackEvent(
        'Play Video Next Level',
          {
            category: 'Students',
            videoTitle: this.videoData.title,
            nextLevelSlug: this.levelSlug
          },
          []
        )
      }
    },

    onSkip: function() {
      if (window.tracker){
        window.tracker.trackEvent(
        'Play Video Skip',
          {
            category: 'Students',
            videoTitle: this.videoData.title,
            nextLevelSlug: this.levelSlug
          },
          []
        )
      }
    }
  }
});
</script>

<style lang="sass">

  @import "app/styles/mixins"
  @import "app/styles/bootstrap/variables"

  +keyframes(winnablePulse)
    from
      @include box-shadow(0px 0px 8px #333)
      color: white
    50%
      @include box-shadow(0px 0px 35px #87CEFF)
      color: #87CEFF
    to
      @include box-shadow(0px 0px 8px #333)
      color: white

  .video-container
    z-index: 3
    width: 100%
    height: 100%
    position: absolute
    background: transparent url('/images/level/videos/videos_background_dungeon.png') no-repeat
    background-position: 0px 0px
    background-size: 100% 100%

    .video-background
      position: absolute
      left: 10%
      top: 5%
      background: transparent url('/images/level/popover_background.png') no-repeat
      background-position: 0px 0px
      background-size: 100% 100%
      width: 80%
      height: 90%

      .video-title
        font-family: "Open Sans Condensed", "Helvetica Neue", Helvetica, Arial, sans-serif

      .row
        position: absolute
        margin: auto
        left: 0%

      .title-row
        width: 100%
        top: 5%

      .video-row
        top: 15%
        width: 100%
        height: 70%

        .video-col
          width: 100%
          height: 100%

          .video
            margin: auto
            width: 100%
            height: 100%

      .buttons-row
        width: 70%
        top: 88%
        left: 16%

        #next-level-btn
          @include animation(winnablePulse 3s infinite)
          border: 0
          border-style: solid
          border-image: url(/images/common/button-background-active-border.png) 14 20 20 20 fill round
          border-image-source: url(/images/common/button-background-success-active-border.png)
          border-width: 14px 20px 20px 20px
          border-radius: 0
          font-weight: bold
          font-family: "Open Sans Condensed", "Helvetica Neue", Helvetica, Arial, sans-serif

      .img-unlocked
        position: absolute
        left: -35px
        top: -10px
        width: 150px
        height: 100px

</style>
