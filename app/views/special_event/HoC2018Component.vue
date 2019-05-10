<template lang="pug">
  #hoc-2018-page
    .hoc-header
      h4(data-i18n="hoc_2018.banner")

    .container

      .row
        h1.page-heading(data-i18n="hoc_2018.page_heading")

      .row.get-started
        .col-md-4
          h4.bold-header(data-i18n="hoc_2018.step_1")
          <iframe src="https://www.youtube.com/embed/k965LUC7oww" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
        .col-md-4
          h4.bold-header(data-i18n="hoc_2018.step_2")
          img(src='/images/pages/teachers/hour-of-code/code_play_share.png')
        .col-md-4
          h4.bold-header(data-i18n="hoc_2018.step_3")
          .glyphicon.glyphicon-download-alt.download-icon

      .row.get-started
        .col-md-4
        .col-md-4
          a.btn.btn-primary.btn-lg(href="/play/hoc-2018" data-i18n="hoc_2018.try_activity")
        .col-md-4
          a.btn.btn-primary.btn-lg(href="http://files.codecombat.com/docs/resources/hourofcode/HourofCodeCodeCombatLessonPlan2018.pdf" target="_blank" data-i18n="hoc_2018.download_pdf")

      .row
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
        .col-md-4
          img(src='/images/pages/teachers/hour-of-code/escape_the_dungeon.png')
          h6(data-i18n="hoc_2018.activity_label_1")
          div
            a.btn.btn-primary.btn-md(href="/play/dungeon?hour_of_code=true" data-i18n="hoc_2018.try_activity")
          div
            a.btn.btn-primary.btn-md(href="/teachers/resources/hoc" data-i18n="hoc_2018.activity_button_1")

        .col-md-4
          img(src='/images/pages/teachers/hour-of-code/beginner_buildagame.png')
          h6(data-i18n="hoc_2018.activity_label_2")
          a.btn.btn-primary.btn-md(href="/play/game-dev-hoc?hour_of_code=true" data-i18n="hoc_2018.try_activity")

        .col-md-4
          img(src='/images/pages/teachers/hour-of-code/advanced_buildagame.png')
          h6(data-i18n="hoc_2018.activity_label_3")
          a.btn.btn-primary.btn-md(href="/play/game-dev-hoc-2?hour_of_code=true" data-i18n="hoc_2018.try_activity")

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
        a.btn.btn-primary.btn-lg(href="/demo" data-i18n="signup.sign_up")

</template>

<script>
module.exports = Vue.extend({
  metaInfo: function () {
    return {
      title: this.$t('teacher.hoc_title'),
      meta: [
        { vmid: 'meta-description', name: 'description', content: this.$t('teacher.hoc_meta_description') }
      ]
    }
  },

  data: function() {
    return {
      teacherEmail: ''
    }
  },
  props: {
    onGetCS1Free: {
      type: Function,
      required: true
    }
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
</style>
