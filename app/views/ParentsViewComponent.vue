<template lang="jade">
#parent-view.style-flat
  #jumbotron.container-fluid
    .container
      .row
        #slogan.col-lg-6.col-md-6
          h3.quote "CodeCombat is an awesome game that inspired me to code"
          h3.text-right - T. Galantis, Age 12
      .refer-btn.row.pull-right
        button.btn.btn-warning.btn-lg(v-on:click="$emit('referTeacher')") Refer a Teacher
  .container
    .row.focus-quote
      h3.text-center Unlock Their Future With The Tutor Your Kids Will Thank You For
    #value-prop.row
      .col-lg-4.col-md-4
        img.img-responsive(src="/images/pages/about/forest.png")
        h3 The most effective way to learn type based code
        p Students will cover material aligned with national curriculum standards, covering topics from computational thinking and algorithms, to big data and cybersecurity. They will come out having a grasp on how the internet of things works, and the personal and global impact of computer science.
      .col-lg-4.col-md-4
        img.img-responsive(src="/images/pages/parents/best_future.png")
        h3 Help them create their best future
        p Computer Science isn’t just about coding and engineering, but also about learning how to navigate and become citizens in the digital world. The problem-to-solution methods taught by programming are something something blah blah blah just a few more words come on brain think of things
      .col-lg-4.col-md-4
        img.img-responsive(src="/images/pages/parents/cheering_warriors.png")
        h3 You've got growing super heroes, so we have heroes too
        p CodeCombat isn’t just more homework, it’s a game that your kids will love to play. We know how important fun and engagement is for the developing brain, so we’ve packed in as much learning as any other CS classroom, while wrapping it up in a game they love. Your kids are the heroes of the future, they might as well have fun while they’re doing it.
    .row.text-center
      .refer-btn
        button.btn.btn-warning.btn-lg(v-on:click="$emit('referTeacher')") Refer a Teacher

  #deep-dive.container
    .row.text-center
      #dive-graphic-1.col-lg-6.col-md-12.col-sm-12
        div
        img.img-responsive.img-circle.deep-img(src="/images/pages/parents/anya_with_map.png")
        h2 Coding, not just for Engineers
      .col-lg-2.col-md-4.col-sm-12.pad-down
        div.img-flag
          h5 Exploration Scientists
        p.small Apollo got to the moon first through a lot of clever code, and the Curiosity Rover needs a team of exception people. As we explore the known world we are using and communicating with coders to help advance across the final frontier.
      .col-lg-2.col-md-4.col-sm-12
        div.img-flag
          h5 Medical and Healthcare
        p.small From mapping of the human genome, to computational analysis of single neurons, coding allows us to understand the body in ways we’ve never been able to before. Coding knowledge is needed for the interpretation and use of medical imaging, and Google has recently launched an AI to help doctors make better decisions.
      .col-lg-2.col-md-4.col-sm-12.pad-down
        div.img-flag
          h5 Filmmaking and Animation
        p.small From the robotics of Jurassic Park to the incredible Animation of Dreamworks and Pixar, computer knowledge has allowed us to create characters that transport us to another world.
  
    .row
      #dive-graphic-2.col-lg-6.col-md-12.col-sm-12.col-lg-push-6.text-center
        div
        h2 The Reason For Game Based Learning
        img.img-responsive.deep-img(src="/images/pages/parents/chess_match.png")
      .col-lg-6.col-md-12.col-sm-12.col-lg-pull-6
        p There’s a reason we moved away from blackboard learning. Sure it may look like a game, but multiple studies repeatedly found that game based learning promoted cognitive development in kids, while also proving to be more effective in helping students learn and retain knowledge, concentrate and perform at a higher level of achievement.
        p Game based learning is also good for teaching resilience, cognitive reasoning, and develop executive functions. Early studies have even shown the effectiveness of using games to teach science. What all this means is that educational games can be the most effective method for teaching kids to be the creators of their best future.
    .row
      #dive-graphic-3.col-lg-6.col-md-12.col-sm-12.text-center
        div
        img.img-responsive.deep-img(src="/images/pages/parents/heroes_waving.png")
        h2 The Reason For Game Based Learning
      .col-lg-6.col-md-12.col-sm-12
        p We’re in almost 14,000 schools across the work and in 190 many countries because we know that in the future coding is going to be as fundamental a school as learning to read and write. Unfortunately, schools often find it difficult to find computer science teachers who can teach CS to an entire study body. We’ve worked closely with teachers to design and develop our levels, but your kids need <b>you</b> to help them learn. Neuroscience and researchers are in agreement about the positive effects of game based learning for kids, but <b>only</b> when it’s implemented correctly. Teacher participation is critical in ensuring those positive outcomes, so WE NEED YOUR HELP to create that connection between students and teachers.
    .row.text-center
      .refer-btn
        button.btn.btn-warning.btn-lg(v-on:click="$emit('referTeacher')") Refer a Teacher
    .row.focus-quote
      h3.text-center CodeCombat's Mission
    
    .row
      .col-md-4.col-sm-12
        img.img-responsive(src="/images/pages/parents/heroes_reading.png")
        h4 Level up computer science education in and out of the classroom
        p We’ve built mechanics so that kids learn coding in a way that’s cross translational,  meaning that they know more than just how to pass our levels. These are actual skills that can be applied outside of the game.
        p We have an amazing education specialist on our team who works closely with teachers to meet children where they are in the educational landscape and CodeCombat is a College Board endorsed provider for AP Computer Science principles.
      .col-md-4.col-sm-12
        img.img-responsive(src="/images/pages/about/sketch.png")
        h4 How and Why We Began
        p 30% of teenagers in secondary school fail to reach proficiency in one subject across maths, reading, or science. We believe in doing better for our kids. So we created CodeCombat. CodeCombat was built to be the most engaging way to teach coding to students. A 2016 survey showed that 64% of girls in 3-5th grade want to learn how to code and 2/3rds of all students were asking for more edtech to be available in their school. There were 7 million job openings in 2015 required coding skills and with barriers to entry becoming higher, we built codecombat to because every child should be given a chance to create their best future.
      .col-md-4.col-sm-12
        img.img-responsive(src="/images/pages/parents/matt_and_kid.jpg")
        h4 We’re parents too
        p Here at CodeCombat, we’re experts in the CS field. Our CEO, Nick, graduated Summa Cum Laude from Oberlin College in 2008. Our CTO, Matt, has been building software for the past 15 years and started off at Microsoft.
        p But more than that, we’re parents too. Nick and Matt each have two growing superheros. At CodeCombat we’re parents. We’re coders. But most of all, we’re people who believe in giving our kids the best opportunity for success in whatever it is they decide to do.

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

#parent-view
  @media (min-width: 1200px)
      overflow-x: hidden

.refer-btn
  margin: 36px auto
  
  button
    background-color: rgba(242, 190, 25, 1)
    border: 0
    h3
      padding: 20px
.deep-img
  margin: 0 auto
  max-height: 200px

.img-flag
  background: url("/images/pages/parents/flag.png") no-repeat center
  background-size: cover
  height: 165px
  width: 165px
  position: relative
  margin: 0 auto
  h5
    position: absolute
    top: 35%

.pad-down
  @media (min-width : 992px)
    padding-top: 40px

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
    button
      color: black

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
    width: auto
  h3
    margin: 10px 0
  div:nth-of-type(1)
    h3
      color: $red
  div:nth-of-type(2)
    h3
      color: $blue
  div:nth-of-type(3)
    h3
      color: $green

#deep-dive
  .row
    margin-top: 20px

// These are styles universal with the deep dive sections.
#dive-graphic-1, #dive-graphic-2, #dive-graphic-3
  min-height: 250px
  position: relative
  padding: 20px 30px
  img
    padding: 10px
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

#dive-graphic-1
  margin-top: 50px
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

</style>