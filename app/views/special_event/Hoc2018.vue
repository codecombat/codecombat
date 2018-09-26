<template lang="pug">
  #hoc-2018-page
    .hoc-header
      .center
        h4 Replace this copy. Codecombat is awesome.
        a.btn.btn-primary(href="/") Learn More
    .container
      .row
        h1#page-heading Heading about teaching students of arcade games.
      .row.get-started
        .col-md-6
          h3 Get Started:
          <iframe width="560" height="315" src="https://www.youtube-nocookie.com/embed/lKTo7aDf0bE?rel=0&amp;showinfo=0" frameborder="0" allow="autoplay; encrypted-media" allowfullscreen></iframe>
        .col-md-5.col-md-offset-1
          h3 Download Lesson Plan:
          p Text about lesson plan.
          button.btn.btn-primary.btn-lg Download PDF

      .row.ready-to-play
        .col-xs-12
          h3 Ready to Play?
          button.btn.btn-primary.btn-lg Play Activity

      .row
        .col-md-12
          h3 About Codecombat
          p Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Nibh venenatis cras sed felis eget velit aliquet sagittis. Eu tincidunt tortor aliquam nulla facilisi. Sed faucibus turpis in eu. Amet facilisis magna etiam tempor orci eu lobortis elementum nibh.
          a.btn.btn-primary.btn-lg(href="/demo") Request a Demo
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