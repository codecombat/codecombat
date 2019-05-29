<template lang="pug">
#parent-view
  #jumbotron.container-fluid
    .container
      .row
        #slogan.col-lg-6.col-md-6
          h3.quote(data-i18n="parent_landing.slogan_quote")
          h3.text-right(data-i18n="parent_landing.quote_attr")
      .refer-btn.row.pull-right
        button.btn.btn-forest.btn-lg(v-on:click="onReferTeacher" data-i18n="parent_landing.refer_teacher")
  .container
    .row.focus-quote
      h2.text-center(data-i18n="parent_landing.focus_quote")
    #value-prop.row
      .col-lg-4.col-md-4
        img.img-responsive(src="/images/pages/parents/valueprop1.png")
        h4(data-i18n="parent_landing.value_head1")
        p(data-i18n="parent_landing.value_copy1")
      .col-lg-4.col-md-4
        img.img-responsive(src="/images/pages/parents/valueprop2.png")
        h4(data-i18n="parent_landing.value_head2")
        p(data-i18n="parent_landing.value_copy2")
      .col-lg-4.col-md-4
        img.img-responsive(src="/images/pages/parents/valueprop3.png")
        h4(data-i18n="parent_landing.value_head3")
        p(data-i18n="parent_landing.value_copy3")
    .row.text-center
      .refer-btn
        button.btn.btn-forest.btn-lg(v-on:click="onReferTeacher", data-i18n="parent_landing.refer_teacher")

  #deep-dive.container
    .row.text-center
      #dive-graphic-1.col-lg-5.col-md-12.col-sm-12
        div
        h2(data-i18n="parent_landing.dive_head1")

      .col-lg-6.col-md-12.col-sm-12.col-sm-offset-1.flags
        .row
          p(data-i18n="parent_landing.dive_intro")
        .row
          img(src="/images/pages/parents/flag.png").col-lg-4.flag-img
          .col-lg-8.col-md-12.col-sm-12
            h5(data-i18n="parent_landing.medical_flag")
            p.small(data-i18n="parent_landing.medical_flag_copy")
        .row
          img(src="/images/pages/parents/flag.png").col-lg-4.flag-img
          .col-lg-8.col-md-12.col-sm-12
            h5(data-i18n="parent_landing.explore_flag")
            p.small(data-i18n="parent_landing.explore_flag_copy")
        .row
          img(src="/images/pages/parents/flag.png").col-lg-4.flag-img
          .col-lg-8.col-md-12.col-sm-12
            h5(data-i18n="parent_landing.filmaking_flag")
            p.small(data-i18n="parent_landing.filmaking_flag_copy")

    .row
      #dive-graphic-2.col-lg-6.col-md-12.col-sm-12.col-lg-push-6.text-center
        div
        h2(data-i18n="parent_landing.dive_head2")
      .col-lg-5.col-md-12.col-sm-12.col-lg-pull-6
        p
          span.spr(data-i18n="parent_landing.dive_par1")
          a(href="https://www.learntechlib.org/p/19982/", data-i18n="parent_landing.dive_link1")
          span.spl.spr(data-i18n="parent_landing.dive_par2")
          a(href="http://www.ejmste.com/A-Study-of-the-Effects-of-Digital-Learning-on-Learning-Motivation-and-Learning-Outcome,69635,0,2.html", data-i18n="parent_landing.dive_link2")
          span.spl.spr(data-i18n="parent_landing.dive_par3")
          a(href="https://www.healio.com/nursing/journals/jcen/2016-8-47-8/%7B4c67edb9-1a9c-432d-af17-0f2856f3ce2c%7D/importance-of-gamification-in-increasing-learning", data-i18n="parent_landing.dive_link3")
          span.spr(data-i18n="parent_landing.dive_par4")
          a(href="http://www.sun.ac.za/english/learning-teaching/ctl/Documents/Gamification%20in%20education.pdf", data-i18n="parent_landing.dive_link4")
          span.spl(data-i18n="parent_landing.dive_par5")
        p
          span.spr(data-i18n="parent_landing.dive_par6")
          a(href="https://mitpress.mit.edu/books/ecology-games", data-i18n="parent_landing.dive_link5")
          span.spr(data-i18n="parent_landing.dive_par7")
          a(href="https://link.springer.com/chapter/10.1007/978-3-319-26508-7_20", data-i18n="parent_landing.dive_link6")
          span(data-i18n="parent_landing.dive_par8")
    .row
      #dive-graphic-3.col-lg-5.col-md-12.col-sm-12.text-center
        div
        h2(data-i18n="parent_landing.dive_head3")
      .col-lg-6.col-md-12.col-sm-12.col-sm-offset-1
        p
          span.spr(data-i18n="parent_landing.dive_3_par1")
          a(href="https://www.theatlantic.com/technology/archive/2012/05/six-reasons-non-computer-nerd-might-want-learn-code/328102/", data-i18n="parent_landing.dive_3_link1")
          span.spr(data-i18n="parent_landing.dive_3_par2")
    .row.text-center
      .refer-btn
        button.btn.btn-forest.btn-lg(v-on:click="onReferTeacher", data-i18n="parent_landing.refer_teacher")
    .row.focus-quote
      h3.text-center(data-i18n="parent_landing.mission")

    #mission.row
      .col-md-4.col-sm-12
        img.img-responsive(src="/images/pages/parents/mission1.png")
        p
          b(data-i18n="parent_landing.mission1_heading")
        p(data-i18n="parent_landing.mission1_copy")
      .col-md-4.col-sm-12
        img.img-responsive(src="/images/pages/parents/mission2.png")
        p
          b(data-i18n="parent_landing.mission2_heading")
        p(data-i18n="parent_landing.mission2_copy")
      .col-md-4.col-sm-12
        img.img-responsive(src="/images/pages/parents/mission3.png")
        p
          b(data-i18n="parent_landing.mission3_heading")
        p(data-i18n="parent_landing.mission3_copy")

</template>

<script lang="coffee">
module.exports = Vue.extend({
  props: {'onReferTeacher': Function }
})
</script>

<style lang="sass">
@import "../styles/style-flat-variables"

$red: #7D0101
$blue: #0E4C60
$green: #20572B

#parent-view
  .row
    margin: 25px 0

  .flags
    text-align: center
    @media (min-width: 1200px)
      text-align: left

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
    h2
      margin-top: 36px
      padding: 20px
      color: #0E4C60
      margin: 0 auto
      @media (min-width: 992px)
        // max-width: 60%

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
      margin: 0 0 20px 0

  // These are styles universal with the deep dive sections.
  #dive-graphic-1, #dive-graphic-2, #dive-graphic-3
    min-height: 280px
    position: relative
    padding: 20px 30px
    h2
      color: white
      text-shadow: 1px 1px 3px black
      position: absolute
      bottom: 20px
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
    background: $red no-repeat url("/images/pages/parents/deepdive1.png")
    background-position: center right
    div
      right: 100%

  #dive-graphic-2
    background: $blue no-repeat url("/images/pages/parents/deepdive2.png")
    div
      left: 100%

  #dive-graphic-3
    background: $green no-repeat url("/images/pages/parents/deepdive3.png")
    background-position: center right
    div
      right: 100%

  #mission
    div
      padding: 0 30px
      img
        width: 100%
</style>
