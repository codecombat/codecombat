<template lang="jade">
#parent-view
  #jumbotron.container-fluid
    .container
      .row
        #slogan.col-lg-4.col-md-6
          h3.quote "CodeCombat is an awesome game that inspired me to code"
          h3.text-right - T. Galantis, Age 12
      .refer-btn.row.pull-right
        button
          h3 Refer a Teacher
  .container
    .row
      #focus-quote
        h3.text-center Unlock Their Future With The Tutor Your Kids Will Thank You For
    #value-prop.row
      .col-lg-4.col-md-4
        .thumbnail
          img(src="/images/pages/about/forest.png").img-responsive
          h3 The most effective way to learn type based code
          p Students will cover material aligned with national curriculum standards, covering topics from computational thinking and algorithms, to big data and cybersecurity. They will come out having a grasp on how the internet of things works, and the personal and global impact of computer science.
      .col-lg-4.col-md-4
        .thumbnail
          #three-img
            img(src="/images/pages/about/forest.png")
            img(src="/images/pages/about/forest.png")
            img(src="/images/pages/about/forest.png")
          h3 Help them create their best future
          p Computer Science isn’t just about coding and engineering, but also about learning how to navigate and become citizens in the digital world. The problem-to-solution methods taught by programming are something something blah blah blah just a few more words come on brain think of things
      .col-lg-4.col-md-4
        .thumbnail
          img(src="/images/pages/about/forest.png").img-responsive
          h3 You've got growing super heroes, so we have heroes too
          p CodeCombat isn’t just more homework, it’s a game that your kids will love to play. We know how important fun and engagement is for the developing brain, so we’ve packed in as much learning as any other CS classroom, while wrapping it up in a game they love. Your kids are the heroes of the future, they might as well have fun while they’re doing it.
    .row.text-center
      .refer-btn
          button
            h3 Refer a Teacher

  #deep-dive.container
    #flags.row.text-center
      .col-lg-6.col-md-3.col-sm-12
        img.img-responsive(src="/images/pages/about/forest.png").img-circle
        h3 experiment
      .col-lg-2.col-md-3
        div.img-flag
          h5 Exploration Scientists
        p flags
      .col-lg-2.col-md-3
        div
          img.img-responsive(src="/images/pages/parents/flag.png")
        h5 flags
      .col-lg-2.col-md3
        div
          img.img-responsive(src="/images/pages/parents/flag.png")
        h5 flags


</template>

<script lang="coffee">
module.exports = Vue.extend({

})
</script>

<style lang="sass">
.thumbnail
  background-color: white
  padding: 0
  border: 0

.refer-btn
  margin: 36px auto
  
  button
    background-color: rgba(242, 190, 25, 1)
    border: 0
    h3
      padding: 20px

.img-flag
  background: url("/images/pages/parents/flag.png") no-repeat center
  background-size: cover
  width: 165px

#jumbotron
  background-image: url("/images/pages/parents/jumbotron_students.png")
  background-position: 50% 55%

  @media (min-width : 1200px)
    background-size: 100% auto

  @media (max-width : 1200px)
    background-size: 1200px auto

  #slogan
    background-color: rgba(242, 190, 25, 0.65)
    padding: 20px
    margin-top: 72px
    margin-bottom: 72px
    
    h3:first-child
      margin-bottom: 20px

  .refer-btn
    margin-bottom: 72px

#focus-quote
  margin-top: 36px
  h3
    color: #0E4C60
    max-width: 50%
    margin: 0 auto

#value-prop
  img
    width: 100%
    height: auto
#three-img
  img
    width: 33%
    height: auto
</style>