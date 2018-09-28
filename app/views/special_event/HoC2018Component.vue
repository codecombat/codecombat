<template lang="pug">
  #hoc-2018-page
    .hoc-header
      .center
        h4(data-i18n="hoc_2018.learn_more_copy")
        a.btn.btn-primary(href="/", data-i18n="hoc_2018.learn_more")

    .container

      .row
        h1#page-heading(data-i18n="hoc_2018.page_heading")

      .row.get-started
        .col-md-6
          h4.bold-header(data-i18n="hoc_2018.get_started")
          <iframe width="560" height="315" src="https://www.youtube.com/embed/5ouY7khrA8M?rel=0&amp;showinfo=0" frameborder="0" allow="autoplay; encrypted-media" allowfullscreen></iframe>

        .col-md-5.col-md-offset-1
          h4.bold-header(data-i18n="hoc_2018.download_lesson")
          p(data-i18n="hoc_2018.lesson_copy")
          a.btn.btn-primary.btn-lg(href="http://files.codecombat.com/docs/resources/hourofcode/HourofCodeCodeCombatLessonPlan2018.pdf" target="_blank" data-i18n="hoc_2018.download_pdf")

      .row.ready-to-play
        .col-xs-12
          h4.bold-header(data-i18n="hoc_2018.ready_play")
          a.btn.btn-primary.btn-lg(href="https://codecombat.com/play/hoc-2018" data-i18n="hoc_2018.play_activity")

      .row.about-heading
        h4.bold-header(data-i18n="hoc_2018.about")

      .row
        .col-md-6
          p(data-i18n="hoc_2018.about_copy")
          a.btn.btn-primary.btn-lg(href="/demo" data-i18n="hoc_2018.request_demo")
        
        .col-md-6.bullet-points
          ul
            li(data-i18n="hoc_2018.point1")
            li(data-i18n="hoc_2018.point2")
            li(data-i18n="hoc_2018.point3")
            li(data-i18n="hoc_2018.point4")
            li(data-i18n="hoc_2018.point5")
            li(data-i18n="hoc_2018.point6")

</template>

<script>
module.exports = Vue.extend({
});
</script>

<style lang="sass">
@import "../../styles/style-flat-variables"

#hoc-2018-page
  .hoc-header
    background-color: $navy
    padding: 5px 0 5px 0
    .center
      text-align: center

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
  .container h4
    font-weight: bold

  #page-heading
    margin: 20px 0
    text-align: center
    font-size: 36px

  .get-started div
    margin-bottom: 30px
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

</style>
