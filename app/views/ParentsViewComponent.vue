<template lang="jade">
#parent-view.style-flat
  #jumbotron.container-fluid
    .container
      .row
        #slogan.col-lg-6.col-md-6
          h3.quote "CodeCombat is an awesome game that inspired me to code"
          h3.text-right - T. Galantis, Age 12
      .refer-btn.row.pull-right
        button.btn.btn-forest.btn-lg(v-on:click="$emit('referTeacher')") Refer a Teacher
  .container
    .row.focus-quote
      h3.text-center Unlock Their Future With The Tutor Your Kids Will Thank You For
    #value-prop.row
      .col-lg-4.col-md-4
        img.img-responsive(src="/images/pages/parents/valueprop1.png")
        h4 The most effective way to learn type based code
        p CodeCombat teaches the two most common coding languages. Students will cover material aligned with national curriculum standards, and cover topics from computational thinking and algorithms, to big data and cybersecurity.
      .col-lg-4.col-md-4
        img.img-responsive(src="/images/pages/parents/valueprop2.png")
        h4 Help them create their best future
        p Students will learn how to navigate and become citizens in the digital world. Problem-to-solution methods taught by programming support creative learning and help your child develop resilience and determination.
      .col-lg-4.col-md-4
        img.img-responsive(src="/images/pages/parents/valueprop3.png")
        h4 You've got growing super heroes, so we have heroes too
        p We know how important fun and engagement is for the developing brain, so we’ve packed in as much learning as any other CS classroom, while wrapping it up in a game they love.
    .row.text-center
      .refer-btn
        button.btn.btn-forest.btn-lg(v-on:click="$emit('referTeacher')") Refer a Teacher

  #deep-dive.container
    .row.text-center
      #dive-graphic-1.col-lg-5.col-md-12.col-sm-12
        div
        img.img-responsive.img-circle.deep-img(src="/images/pages/parents/deepdive1.png")
        h2 Coding, not just for Engineers
      
      .col-lg-6.col-md-12.col-sm-12.col-sm-offset-1
        .row
          img(src="/images/pages/parents/flag.png").col-lg-4.flag-img
          .col-lg-8.col-md-12.col-sm-12
            h5 Medical and Healthcare
            p.small From mapping of the human genome, to MRI machines, coding allows us to understand the body in ways we’ve never been able to before.
        .row
          img(src="/images/pages/parents/flag.png").col-lg-4.flag-img
          .col-lg-8.col-md-12.col-sm-12
            h5 Exploration Scientists
            p.small Apollo got to the moon thanks to hardworking human computers, and scientists use computer programs to analyze the gravity of planets and search for new stars.
        .row
          img(src="/images/pages/parents/flag.png").col-lg-4.flag-img
          .col-lg-8.col-md-12.col-sm-12
            h5 Filmmaking and Animation
            p.small From the robotics of Jurassic Park to the incredible Animation of Dreamworks and Pixar, films wouldn’t be the same without computer science and the creatives behind the scenes.
  
    .row
      #dive-graphic-2.col-lg-6.col-md-12.col-sm-12.col-lg-push-6.text-center
        div
        h2 The Reason For Game Based Learning
        img.img-responsive.deep-img(src="/images/pages/parents/deepdive2.png")
      .col-lg-5.col-md-12.col-sm-12.col-lg-pull-6
        p
          span.spr Multiple studies repeatedly found that game based learning promoted
          a(href="https://www.learntechlib.org/p/19982/") cognitive development
          span.spl.spr in kids, while also proving to be
          a(href="http://webcache.googleusercontent.com/search?q=cache:v-UZ4U5_b7cJ:www.ejmste.com/A-Study-of-the-Effects-of-Digital-Learning-on-Learning-Motivation-and-Learning-Outcome,69635,0,2.html+&amp;cd=1&amp;hl=en&amp;ct=clnk&amp;gl=us") more effective
          span.spl.spr in helping students
          a(href="https://www.healio.com/nursing/journals/jcen/2016-8-47-8/%7B4c67edb9-1a9c-432d-af17-0f2856f3ce2c%7D/importance-of-gamification-in-increasing-learning") learn and retain knowledge
          span.spr ,
          a(href="http://www.sun.ac.za/english/learning-teaching/ctl/Documents/Gamification%20in%20education.pdf") concentrate
          span.spl and perform at a higher level of achievement.
        p
          span.spr Game based learning is also good for teaching
          a(href="https://mitpress.mit.edu/books/ecology-games") resilience
          span.spr , cognitive reasoning, and develop
          a(href="https://link.springer.com/chapter/10.1007/978-3-319-26508-7_20") executive functions
          span . Science is just telling us what you teachers already know. Kids learn best by playing. 
    .row
      #dive-graphic-3.col-lg-5.col-md-12.col-sm-12.text-center
        div
        img.img-responsive.deep-img(src="/images/pages/parents/deepdive3.png")
        h2 The Reason For Game Based Learning
      .col-lg-6.col-md-12.col-sm-12.col-sm-offset-1
        p
          a(href="https://www.theatlantic.com/technology/archive/2012/05/six-reasons-non-computer-nerd-might-want-learn-code/328102/") In the future
          span.spl coding is going to be as fundamental a school as learning to read and write. We’ve worked closely with teachers to design and develop our levels, now your kids need you to help them learn. Educational technology works best when the teachers can implement it correctly which means that as a parent, students need your help to create that connection.
    .row.text-center
      .refer-btn
        button.btn.btn-forest.btn-lg(v-on:click="$emit('referTeacher')") Refer a Teacher
    .row.focus-quote
      h3.text-center CodeCombat's Mission
    
    #mission.row
      .col-md-4.col-sm-12
        img.img-responsive(src="/images/pages/parents/mission1.png")
        p
          b Level up computer science education in and out of the classroom
        p Our education specialist works closely with teachers to meet children where they are in the educational landscape. Kids learn coding skills that can be applied outside of the game because it’s more than just copy and paste. They learn how to solve problems. And because we’ve worked with teachers, we’ve made sure that CodeCombat supports all different learning styles. 
      .col-md-4.col-sm-12
        img.img-responsive(src="/images/pages/parents/mission2.png")
        p
          b How and Why We Began
        p CodeCombat was built to be the most engaging way to teach coding to students. A 2016 survey showed that 64% of girls in 3-5th grade want to learn how to code. There were 7 million job openings in 2015 required coding skills and with barriers to entry becoming higher, we built codecombat to because every child should be given a chance to create their best future. 
      .col-md-4.col-sm-12
        img.img-responsive(src="/images/pages/parents/mission3.png")
        p
          b We’re parents too
        p Here at CodeCombat, we’re experts in the CS field. But more than that, we’re parents too. Nick and Matt each have two growing superheros. At CodeCombat we’re parents. We’re coders. But most of all, we’re people who believe in giving our kids the best opportunity for success in whatever it is they decide to do.

</template>

<script lang="coffee">
module.exports = Vue.extend({
})
</script>

<style lang="sass">
@import "../styles/style-flat-variables"

$red: #7D0101
$blue: #0E4C60
$green: #20572B
.row
  margin: 25px 0

#parent-view
  @media (min-width: 1200px)
      overflow-x: hidden

.refer-btn
  margin: 36px auto
  button
    border: 0
    h3
      padding: 20px
      color: white
.deep-img
  margin: 0 auto
  max-height: 200px

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

.focus-quote
  h3
    margin-top: 36px
    padding: 20px
    color: #0E4C60
    margin: 0 auto
    @media (min-width: 992px)
      max-width: 60%

#value-prop
  img
    width: 100%
  h3
    margin: 10px 0
  div
    padding: 0 30px
    h4
      text-align: center
      padding: 10px
  div:nth-of-type(1)
    h4
      color: $red
  div:nth-of-type(2)
    h4
      color: $blue
  div:nth-of-type(3)
    h4
      color: $green

#deep-dive
  .row
    margin: 40px 0

// These are styles universal with the deep dive sections.
#dive-graphic-1, #dive-graphic-2, #dive-graphic-3
  min-height: 250px
  position: relative
  padding: 20px 30px
  h2
    color: white
  div
    height: 100%
    position: absolute
    width: 2000px
    background-color: inherit
    top: 0
    @media (max-width: 1200px)
      display: none

.flag-img
  max-height: 100px
  width: auto
  margin: -20px 0 20px 0

#dive-graphic-1
  background-color: $red
  div
    right: 100%

#dive-graphic-2
  background-color: $blue
  div
    left: 100%

#dive-graphic-3
  background-color: $green
  div
    right: 100%

#mission
  div
    padding: 0 30px
    img
      width: 100%
</style>