<template lang="pug">
#modal-base-flat
  <iframe class="video-frame" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>
  #video-close-btn.btn.well.well-sm.well-parchment.close-btn(data-dismiss="modal")
    span.glyphicon.glyphicon-remove
  #course-videos-modal
    #videos-content.modal-content.style-flat
      .modal-header
        #modal-close-btn.btn.well.well-sm.well-parchment.close-btn(data-dismiss="modal")
          span.glyphicon.glyphicon-remove
        h3.text-center
          | {{ $t('courses.concept_videos') }}
      .modal-body.container
        .row.videos-row(v-if="videoLevels.length > 0")
          .col-sm-4.course-video.m-l-3(v-for="level in videoLevels")
            .locked(v-if="level.videoStatus === 'locked'")
              .video-link
                img.video-image(
                  :src='level.thumbnail_locked'
                )
                .video-status
                  img.img-locked(src = '/images/pages/play/modal/locked_banner.png')
              .video-text.m-t-2
                span.rtl-allowed.video-title.gray-text
                  | {{ level.title }}
                p.video-desc.gray-text
                  | {{ $t('courses.locked_videos_desc', { concept_name: level.title }) }}
            .unlocked(v-else-if="level.videoStatus === 'unlocked'")
              .video-link
                img.video-image(
                  :src='level.thumbnail_unlocked', 
                  @click="onImageClick"
                )
                .video-status
                  img.img-unlocked(src = '/images/pages/play/modal/unlocked_banner.png')
              .video-text.m-t-2
                span.rtl-allowed.video-title
                  | {{ level.title }}
                p.video-desc
                  | {{ $t('courses.unlocked_videos_desc', { concept_name: level.title }) }}
</template>

<script>
import api from 'core/api';
import utils from 'core/utils'
import Player from '@vimeo/player'

export default Vue.extend({
  props: {
    courseInstanceID: {
      type: String,
      required: true
    },
    courseID: {
      type: String,
      required: true
    }
  },
  data: () => ({
    videoLevels: [],
    vimeoPlayer: {}
  }),
  created() {
    // fetch the levels that contain video URLs from the classroom ID for the given course instance ID.
    api.courseInstances.get({courseInstanceID: this.courseInstanceID }).then(courseInstanceData => {
      api.classrooms.get({classroomID: courseInstanceData.classroomID}).then(classroomData => {
        const levels = classroomData.courses.find((c) => c._id == this.courseID).levels
        for (let level in levels) {
          const video = utils.videoLevels[levels[level].original]
          if (video) {
            this.videoLevels.push(video)
          }
        }
        // fetch the sessions for the given user and course instance, and check if video levels are locked or unlocked.
        api.courseInstances.getSessions({courseInstanceID: this.courseInstanceID }).then(sessions => {
          let sessionsMap = {}
          for (let s of sessions){
            sessionsMap[s.level.original] = s
          }
          for (let l of this.videoLevels){
            if (sessionsMap[l.original]){
              Vue.set(l, 'videoStatus', 'unlocked')
            }
            else{
              Vue.set(l, 'videoStatus', 'locked')
            }
          }
        }).catch((err) => {
          console.log("Error in fetching sessions:", err)
        });
      }).catch((err) => {
        console.log("Error in fetching classroom details:", err)
      });
    }).catch((err) => {
      console.log("Error in fetching course instance details:", err)
    });
  },
  methods: {
    // open video in the iframe when video thumbnail is clicked
    onImageClick: function(e) {
      let video_url = ''
      let src = e.target.src
      src = src.slice(src.search('/images'))
      for (let l of this.videoLevels){
        if (l.thumbnail_unlocked == src){
          video_url = l.url;
          break;
        }
      }
      let frame = $('.video-frame')[0]
      frame.src = video_url
      frame.style['z-index'] = 3
      $('#videos-content')[0].style.display = "none"
      const p = new Player(frame);
      $('#video-close-btn')[0].style.display = "block"
      p.play().catch((err) => console.log("Error while playing the video:", err))
    }
  },
});
</script>

<style lang="sass">
@import "app/styles/style-flat-variables"

#modal-base-flat
  position: absolute
  left: -180px
  max-width: 1000px

  .video-frame
    position: relative
    z-index: 0
    height: 500px
    width: 1000px
  
  #video-close-btn
    display: none
    right: 45px
    z-index: 3

  .close-btn
    position: absolute
    right: 0px
    color: white
    top: 0px
    background: #ba1d00
    padding: 6px 6px 3px
    border: 2px solid #14110e
    border-radius: 0px
  
  #course-videos-modal
    
    #videos-content
      background: transparent url('/images/level/popover_background.png') no-repeat 
      background-position: 0px 0px
      background-size: 100% 100%
      border: 0
      position: absolute
      top: 100px

      .modal-body
        max-width: 980px

    .course-video
      width: 280px

    .video-image
      height: 140px
      width: 250px

    .video-link
      position: relative

      .video-status
        position: absolute
        left: -20px
        top: -20px

        .img-locked, .img-unlocked
          width: 70px
          height: 50px
      
    .gray-text
      color: #565656

    .video-title
      font-size: 20px
      font-weight: bold

    .video-desc
      font-size: 14px

</style>
