<template lang="pug">
  #hoc-2018-page
    .hoc-header
      h4(data-i18n="hoc_2018.banner_coco")

    .container

      if activity() == 'teacher-gd'
        .row
          h1.page-heading(data-i18n="hoc_2018.page_heading")
        .row.get-started
          .col-md-4
            h4.bold-header(data-i18n="hoc_2018.step_1")
            <iframe src="https://www.youtube.com/embed/k965LUC7oww" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
          .col-md-4
            h4.bold-header(data-i18n="hoc_2018.step_2")
            img(src='/images/pages/teachers/hour-of-code/code_play_share.png' alt="")
          .col-md-4
            h4.bold-header(data-i18n="hoc_2018.step_3")
            .glyphicon.glyphicon-download-alt.download-icon

        .row.get-started
          .col-md-4
          .col-md-4
            a.btn.btn-primary.btn-lg(href="/play/hoc-2018" data-i18n="hoc_2018.try_activity")
          .col-md-4
            a.btn.btn-primary.btn-lg(href="https://files.codecombat.com/docs/resources/hourofcode/HourofCodeCodeCombatLessonPlan2020.pdf" target="_blank" data-i18n="hoc_2018.download_pdf")
            a.btn.btn-primary.btn-lg(v-if="isTeacher" href="/teachers/campaign-solution/hoc-2018/python" target="_blank" data-i18n="courses.view_guide_online")

      else if activity() == 'goblins'
        .row
          h1.page-heading(data-i18n="hoc_2018.page_heading_goblins")
        .row.get-started
          if !isTeacher
            .col-md-3
          .col-md-6
            img.activity-tile(src='/images/pages/teachers/hour-of-code/goblins_n_glory.jpeg' alt="")
          if isTeacher
            .col-md-6
              .glyphicon.glyphicon-download-alt.download-icon
          else
            .col-md-3

        .row.get-started
          if !isTeacher
            .col-md-3
          .col-md-6
            a.btn.btn-primary.btn-lg(href="/play/goblins-hoc?hour_of_code=true" data-i18n="hoc_2018.try_activity")
          if isTeacher
            .col-md-6
              a.btn.btn-primary.btn-lg(href="/teachers/resources/hoc-goblins" target="_blank" data-i18n="hoc_2018.download_pdf")
              a.btn.btn-primary.btn-lg(v-if="isTeacher" href="/teachers/campaign-solution/goblins-hoc/python" target="_blank" data-i18n="courses.view_guide_online")
          else
            .col-md-3

      else
        .row
          h1.page-heading Our latest activities are easy to implement and fun to play

          banner-webinar

        .row.get-started.featured
          if activity() != 'goblins'
            .row
              .col-md-4
                img.activity-tile(src='/images/pages/teachers/hour-of-code/goblins-n-glory.png' alt="")
              .col-md-8
                h3(data-i18n="hoc_2018.featured_title_1")
                h6(data-i18n="hoc_2018.featured_subtitle_1")
                p(data-i18n="hoc_2018.featured_blurb_1")
                div
                  a.btn.btn-primary.btn-md(href="/play/goblins-hoc?hour_of_code=true" data-i18n="hoc_2018.try_activity")
                  button.btn.btn-primary.btn-md(data-toggle="modal" data-video-id="YZjnpqb73ms" data-target="#youtubeModal" @click="playVideo" data-i18n="hoc_2018.play_video")
                  a.btn.btn-primary.btn-md(v-if="isTeacher" href="/teachers/campaign-solution/goblins-hoc/python" target="_blank" data-i18n="hoc_2018.solutions")
          .row
            .col-md-4
              img.activity-tile(src='/images/pages/teachers/hour-of-code/ai-league.jpg' alt="")
            .col-md-8
              h3(data-i18n="hoc_2018.featured_title_2")
              h6(data-i18n="hoc_2018.featured_subtitle_2")
              p(data-i18n="hoc_2018.featured_blurb_2")
              div
                a.btn.btn-primary.btn-md(href="/play/ai-league-hoc?hour_of_code=true" data-i18n="hoc_2018.try_activity")
                button.btn.btn-primary.btn-md(data-toggle="modal" data-video-id="niKXOofTckE" data-target="#youtubeModal" @click="playVideo" data-i18n="hoc_2018.play_video")
          .row
            .col-md-4
              img.activity-tile(src='/images/pages/teachers/hour-of-code/ozaria-your-journey-begins.png' alt="")
            .col-md-8
              h3(data-i18n="hoc_2018.featured_title_3")
              h6(data-i18n="hoc_2018.featured_subtitle_3")
              p(data-i18n="hoc_2018.featured_blurb_3")
              div
                a.btn.btn-primary.btn-md(href="https://www.ozaria.com/play/chapter-1-sky-mountain?hour_of_code=true" data-i18n="hoc_2018.try_activity")
                a.btn.btn-primary.btn-md(href="https://docs.google.com/presentation/d/1KgFOg2tqbKEH8qNwIBdmK2QbHvTsxnW_Xo7LvjPsxwE/present#slide=id.g89b5bc74f5_2_0" data-i18n="hoc_2018.activity_button_1")
                button.btn.btn-primary.btn-md(data-toggle="modal" data-video-id="zdKaVO5uUug" data-target="#youtubeModal" @click="playVideo" data-i18n="hoc_2018.play_video")
                a.btn.btn-primary.btn-md(v-if="isTeacher" href="https://www.ozaria.com/teachers/course-solution/5d41d731a8d1836b5aa3cba1/python" target="_blank" data-i18n="hoc_2018.solutions")

      .row(v-if="isAnonymous")
        br
        h1.page-heading(data-i18n="hoc_2018.teacher_signup_heading")
        h4(data-i18n="hoc_2018.teacher_signup_blurb")
        div
          div.get-cs1-container
            h6(data-i18n="hoc_2018.teacher_signup_input_blurb")
            div
              input.teacher-email-input(type="text" v-model="teacherEmail" data-i18n="[placeholder]hoc_2018.teacher_signup_input_placeholder")
              button.btn.btn-primary.btn-md.get-cs1-btn(v-on:click="onGetCS1Free(teacherEmail)")
                span(data-i18n="hoc_2018.teacher_signup_input_button")

      .row
        br
        h3(data-i18n="hoc_2018.activities_header")

      .row.overline.activities-row
        if activity() != 'ai-league'
          .col-md-4
            img.activity-tile(src='/images/pages/teachers/hour-of-code/codecombat_esports.jpeg' alt="")
            h6(data-i18n="hoc_2018.activity_label_ai_league")
            div
              a.btn.btn-primary.btn-md(href="/play/ai-league-hoc?hour_of_code=true" data-i18n="hoc_2018.try_activity")
              a.btn.btn-primary.btn-md(href="/teachers/hour-of-code" data-i18n="hoc_2018.activity_button_1")
              a.btn.btn-primary.btn-md(v-if="isTeacher" href="/teachers/campaign-solution/ai-league-hoc/python" target="_blank" data-i18n="hoc_2018.solutions")

        .col-md-4
          img(src='/images/pages/teachers/hour-of-code/escape_the_dungeon.png' alt="")
          h6(data-i18n="hoc_2018.activity_label_1")
          div
            a.btn.btn-primary.btn-md(href="/play/dungeon?hour_of_code=true" data-i18n="hoc_2018.try_activity")
            a.btn.btn-primary.btn-md(href="/teachers/resources/hoc" data-i18n="hoc_2018.activity_button_1")
            a.btn.btn-primary.btn-md(v-if="isTeacher" href="/teachers/campaign-solution/dungeon/python" target="_blank" data-i18n="hoc_2018.solutions")

        .col-md-4
          img(src='/images/pages/teachers/hour-of-code/beginner_buildagame.png' alt="")
          h6(data-i18n="hoc_2018.activity_label_2")
          div
            a.btn.btn-primary.btn-md(href="/play/game-dev-hoc?hour_of_code=true" data-i18n="hoc_2018.try_activity")
            a.btn.btn-primary.btn-md(v-if="isTeacher" href="/teachers/campaign-solution/game-dev-hoc/python" target="_blank" data-i18n="hoc_2018.solutions")

        if activity() != 'teacher-gd'
          .col-md-4
            // TODO: image
            img(src='/images/pages/teachers/hour-of-code/code_play_share.png' alt="")
            h6(data-i18n="hoc_2018.activity_label_hoc_2018")
            div
              a.btn.btn-primary.btn-md(href="/play/hoc-2018?hour_of_code=true" data-i18n="hoc_2018.try_activity")
              a.btn.btn-primary.btn-md(href="/teachers/hour-of-code?activity=teacher-gd" data-i18n="hoc_2018.activity_button_1")
              a.btn.btn-primary.btn-md(v-if="isTeacher" href="/teachers/campaign-solution/hoc-2018/python" target="_blank" data-i18n="hoc_2018.solutions")

        .col-md-4
          img(src='/images/pages/teachers/hour-of-code/advanced_buildagame.png' alt="")
          h6(data-i18n="hoc_2018.activity_label_3")
          div
            a.btn.btn-primary.btn-md(href="/play/game-dev-hoc-2?hour_of_code=true" data-i18n="hoc_2018.try_activity")
            a.btn.btn-primary.btn-md(v-if="isTeacher" href="/teachers/campaign-solution/game-dev-hoc-2/python" target="_blank" data-i18n="hoc_2018.solutions")

      .row
        br
        h3(data-i18n="hoc_2018.about")

      .row.overline
        .col-md-1
        .col-md-4
          img(src='/images/pages/teachers/hour-of-code/about_codecombat.png')
        .col-md-6.text-left
          p(data-i18n="hoc_2018.about_copy")
          .row
            .col-md-6.bullet-points
              ul
                li(data-i18n="hoc_2018.point1")
                li(data-i18n="hoc_2018.point2")
                li(data-i18n="hoc_2018.point3")
            .col-md-6.bullet-points
              ul
                li(data-i18n="hoc_2018.point4")
                li(data-i18n="hoc_2018.point5")
                li(data-i18n="hoc_2018.point6")
        .col-md-1

      .row
        br
        a.btn.btn-primary.btn-lg(href="/home#create-account-teacher" data-i18n="signup.sign_up")


    #youtubeModal.modal.fade(aria-labelledby='youtubeModal' aria-hidden='true' ref="modal").bs-example-modal-lg
      .modal-dialog.modal-lg
        .modal-content
          .modal-body
            button.close(type='button' data-dismiss='modal' aria-label='Close')
              span(aria-hidden='true') &times;
            youtube(:video-id="videoId" ref="youtube" width="100%" aspect-ratio="16 / 9")

</template>

<script>
import BannerWebinar from '../courses/BannerWebinar'

module.exports = Vue.extend({
  components: {
    BannerWebinar
  },

  mounted: function () {
    $(this.$refs.modal).on('shown.bs.modal',() => {
      this.player.playVideo();
    })
    $(this.$refs.modal).on('hide.bs.modal',() => {
      this.player.pauseVideo();
    })
  },

  metaInfo: function () {
    return {
      title: this.$t('teacher.hoc_title'),
      meta: [
        { vmid: 'meta-description', name: 'description', content: this.$t('teacher.hoc_meta_description') }
      ]
    }
  },

  data: function () {
    return {
      teacherEmail: '',
      isAdmin: me.isAdmin(),
      isTeacher: me.isTeacher(),
      isAnonymous: me.isAnonymous(),
      videoId: ''
    }
  },
  props: {
    onGetCS1Free: {
      type: Function,
      required: true
    },
    activity: {
      type: Function,
      required: true
    }
  },
  computed: {
    player () {
      return this.$refs.youtube.player
    }
  },

  methods: {
    async playVideo (e) {
      this.videoId = $(e.target).data('video-id')
    },
  }
});
</script>

<style lang="sass">
@import "../../styles/style-flat-variables"

#hoc-2018-page
  text-align: center

  .hoc-header
    background-color: $navy
    padding: 5px 0 5px 0

    h4
      display: inline-block
      color: white
      margin: 0 20px 0 0
      padding-top: 2px
      font-weight: normal
      font-size: 18px

    a.btn-primary
      background-color: white
      color: $navy
      vertical-align: text-bottom

      &:hover
        background-color: #eeeeee

  .page-heading
    margin: 20px 0
    text-align: center
    font-size: 36px

  .get-started div
    h4
      margin-bottom: 15px

  .ready-to-play
    text-align: center
    margin-bottom: 60px

    h4
      margin-bottom: 10px

  .about-heading
    margin: 10px 0

  .bullet-points ul li
    list-style-type: none

  iframe
    height: 212px // to match step 2 image

  img
    width: 100%

  .btn
    margin-top: 10px

  .get-cs1-container
    display: inline-block
    text-align: left
    margin-top: 10px

  .get-cs1-btn
    margin-left: 10px
    margin-top: -4px

  .teacher-email-input
    width: 30%
    min-width: 400px

  .download-icon
    font-size: 106px
    color: lightgray
    top: 50px
    left: 5px

  .overline
    border-top: solid 1px black
    padding-top: 20px

  .bold-header
    font-weight: bold

  .activities-row
    .btn
      width: 120px

    .col-md-4
      min-height: 345px

  .activity-tile
    height: 212px
    object-fit: cover

  .featured
    text-align: left

    h3, h6, p
      font-family: Arial

    p
      font-size: 20px
      line-height: 31px

    h6
      font-weight: normal

    .row
      margin-bottom: 40px


    .btn
      background-color: #0097A7
      border: 3px solid #595959
      box-shadow: none
      text-transform: uppercase
      font-weight: 700
      text-decoration: underline
      text-shadow: none
      font-family: Arial

    .activity-tile
      height: initial

  #announcement
    background-color: #0097A7
    border: 3px solid #595959
    border-radius: 20px
    margin: 10px 20px 40px

    p
      color: white

    a
      color: white
      text-decoration: underline
      font-weight: bold


  .modal
    justify-content: center
    align-items: center

  .modal-dialog
    flex: 1
    width: 80vw
    display: flex
    align-items: center
    justify-content: center
    margin: 0 auto
    top: 50%
    transform: translateY(-50%)

  .modal-content
    margin: auto
    height: fit-content
    width: 100%
    background: rgba(255, 255, 255, 0.9)

    iframe
      height: auto
      aspect-ratio: 16 / 9

</style>
