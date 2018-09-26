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
          h3(data-i18n="hoc_2018.get_started")
          <iframe width="560" height="315" src="https://www.youtube-nocookie.com/embed/lKTo7aDf0bE?rel=0&amp;showinfo=0" frameborder="0" allow="autoplay; encrypted-media" allowfullscreen></iframe>
        .col-md-5.col-md-offset-1
          h3(data-i18n="hoc_2018.download_lesson")
          p(data-i18n="hoc_2018.lesson_copy")
          button.btn.btn-primary.btn-lg(data-i18n="hoc_2018.download_pdf")

      .row.ready-to-play
        .col-xs-12
          h3(data-i18n="hoc_2018.ready_play")
          button.btn.btn-primary.btn-lg(data-i18n="hoc_2018.play_activity")

      .row
        .col-md-12
          h3(data-i18n="hoc_2018.about")
          p(data-i18n="hoc_2018.about_copy")
          a.btn.btn-primary.btn-lg(href="/demo" data-i18n="hoc_2018.request_demo")
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

    a.btn-primary
      background-color: white
      color: $navy
      vertical-align: text-bottom

      &:hover
        background-color: #eeeeee

  #page-heading
    margin: 60px 0
  .get-started div
    margin-bottom: 60px
      
  .ready-to-play
    text-align: center
    margin-bottom: 60px
    h3
      margin-bottom: 30px


</style>