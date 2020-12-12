<template lang="pug">
.container-fluid#impact-page

  .row#jumbotron-container-fluid
    h1.text-white {{ $t('impact.hero_heading')}}
    h5.text-white {{ $t('impact.hero_subheading') }}

  #featured-partner-story.row.row-dark
    h2.text-gold {{ $t('impact.featured_partner_story') }}

    .scroll-arrow
      .left-arrow
      .right-arrow

  #bobby-duke.row.width-container
    .col-md-2.col-md-offset-1
      img.img-responsive(src="/images/pages/impact/bobby-duke logo 2.png")

    .col-md-8
      h1.text-navy {{ $t('impact.partner_heading') }}
      h2.text-teal {{ $t('impact.partner_school') }}

  .row.width-container
    base-school-facts.col-md-3.col-md-offset-1
    .col-md-7#body-text-content
      p.text-navy {{ $t('impact.paragraph1') }}
      p.text-navy {{ $t('impact.paragraph2') }}
      p.text-navy {{ $t('impact.paragraph3') }}

  .row.width-container.quote-flex-container
    .col-md-4.col-md-offset-1.col-xs-6
      .row.teacher-quote
        img(src="/images/pages/home/teal_quote.png")

      .row.teacher-quote
        h3.text-navy {{ $t('impact.teacher_quote') }}
        p.text-navy {{ $t('impact.quote_attribution') }}

    .col-xs-6
      img.img-responsive(src="/images/pages/impact/image5.png" alt="Students using CodeCombat in a classroom")

  .row
    .col-md-12.read-full-story
      a.btn.btn-lg.btn-primary(href="/images/pages/impact/pdf/CodeCombat_CaseStudy_BobbyDukeMS.pdf" target="_blank") {{ $t('impact.read_full_story') }}

  #more-partner-stories.row.row-dark
    .row.width-container
      h1.text-gold {{ $t('impact.more_stories') }}
    //- TODO: Make this duplication a component
    #partner-story-tiles.row.width-container
      .col-md-4.partner-story-tile.col-xs-12
        .row
          .row
            img.img-responsive.tile-header-img(src="/images/pages/impact/PrestonHSPhoto.png")
          .row.inner-tile-school
            .col-xs-3
              img.img-responsive(src="/images/pages/impact/Preston High School logo.png")
            .col-xs-9
              h4.text-teal {{ $t('impact.partners_heading_1') }}
              p {{ $t('impact.partners_school_1') }}
        a.btn.btn-lg.btn-primary(href="/images/pages/impact/pdf/CodeCombat_CaseStudy_PrestonHS.pdf" target="_blank") {{ $t('impact.read_full_story') }}
      .col-md-4.partner-story-tile.col-xs-12
        .row
          .row
            img.img-responsive.tile-header-img(src="/images/pages/impact/RiverRidgePhoto.png")
          .row.inner-tile-school
            .col-xs-3
              img.img-responsive(src="/images/pages/impact/rrhs-logo-1-1.png")
            .col-xs-9
              h4.text-teal {{ $t('impact.partners_heading_2') }}
              p {{ $t('impact.partners_school_2') }}
        a.btn.btn-lg.btn-primary(href="/images/pages/impact/pdf/CodeCombat_CaseStudy_RiverRidgeHS.pdf" target="_blank") {{ $t('impact.read_full_story') }}
      .col-md-4.partner-story-tile.col-xs-12
        .row
          .row
            img.img-responsive.tile-header-img(src="/images/pages/impact/RiverdalePhoto.png")
          .row.inner-tile-school
            .col-xs-3
              img.img-responsive(src="/images/pages/impact/Riverdale High School.fw.png")
            .col-xs-9
              h4.text-teal {{ $t('impact.partners_heading_3') }}
              p {{ $t('impact.partners_school_3') }}
        a.btn.btn-lg.btn-primary(href="/images/pages/impact/pdf/CodeCombat_CaseStudy_RiverdaleHS.pdf" target="_blank") {{ $t('impact.read_full_story') }}

  //- html structure copied and modified from home page
  #teachers-love-codecombat.width-container.row.text-center
    .col-md-12
      h1.text-teal(data-i18n="new_home.teachers_love_codecombat_title")
      .row
        .col-xs-4
          .width-320
            h1.text-forest 99%
            img(src="/images/pages/home/pink_rectangle.png")
            h4.text-navy(data-i18n="new_home.teachers_love_codecombat_blurb1")
        .col-xs-4
          .width-320
            h1.text-forest 95%
            img(src="/images/pages/home/pink_rectangle.png")
            h4.text-navy(data-i18n="new_home.teachers_love_codecombat_blurb2")
        .col-xs-4
          .width-320
            h1.text-forest 94%
            img(src="/images/pages/home/pink_rectangle.png")
            h4.text-navy(data-i18n="new_home.teachers_love_codecombat_blurb3")
      a.btn.btn-primary.btn-lg(href="/images/pages/impact/pdf/CodeCombat_ImplementationStudy_Summary.pdf" target="_blank") {{ $t('impact.download_study') }}
      p.mcrel-blurb.text-navy(data-i18n="new_home.teachers_love_codecombat_subblurb")

  #teacher-student-spotlight.row.row-dark
    .row.width-container
      .col-md-12
        h2.text-gold.text-center {{ $t('impact.teacher_spotlight') }}
      #teacher-student-tiles.row
        .col-md-4.teacher-student-tile
          div
            .row.teacher-description
              .col-xs-3.teacher-thumbnail
                img.img-responsive(src="/images/pages/impact/teacher_thumbnail_1.png")
              .col-xs-9.teacher-bio
                h3.text-navy {{ $t('impact.teacher_name_1') }}
                h5.text-navy {{ $t('impact.teacher_title_1') }}
                h5.text-navy {{ $t('impact.teacher_location_1') }}
            .row
              p.text-navy {{ $t('impact.spotlight_1') }}
          .row.text-right
            a.text-teal.continue-reading-link(href="https://blog.codecombat.com/codecombat-teacher-spotlight-amanda-henry/" target="_blank") {{ $t('impact.continue_reading_blog') }}

        .col-md-4.teacher-student-tile
          div
            .row.teacher-description
              .col-xs-3.teacher-thumbnail
                img.img-responsive(src="/images/pages/impact/teacher_thumbnail_2.png")
              .col-xs-9.teacher-bio
                h3.text-navy {{ $t('impact.teacher_name_2') }}
                h5.text-navy {{ $t('impact.teacher_title_2') }}
                h5.text-navy {{ $t('impact.teacher_location_2') }}
            .row
              p.text-navy {{ $t('impact.spotlight_2') }}
          .row.text-right
            a.text-teal.continue-reading-link(href="https://blog.codecombat.com/codecombat-student-spotlight-kaila/" target="_blank") {{ $t('impact.continue_reading_blog') }}

        .col-md-4.teacher-student-tile
          div
            .row.teacher-description
              .col-xs-3.teacher-thumbnail
                img.img-responsive(src="/images/pages/impact/teacher_thumbnail_3.png")
              .col-xs-9.teacher-bio
                h3.text-navy {{ $t('impact.teacher_name_3') }}
                h5.text-navy {{ $t('impact.teacher_title_3') }}
                h5.text-navy {{ $t('impact.teacher_school_3') }}
                h5.text-navy {{ $t('impact.teacher_location_3') }}
            .row
              p.text-navy {{ $t('impact.spotlight_3') }}
          .row.text-right
            a.text-teal.continue-reading-link(href="https://blog.codecombat.com/codecombat-teacher-spotlight-susan-jones-szabo/" target="_blank") {{ $t('impact.continue_reading_blog') }}

  .row.text-center#global
    .row
      .col-lg-12
        h2.text-teal(data-i18n="new_home.global_title")
      .container
        .row
          .col-md-3.col-xs-6
            img(src="/images/pages/home/global_learners.png")
            h2.text-navy 20 Million
            h5.text-navy(data-i18n="new_home.global_subtitle1")
          .col-md-3.col-xs-6
            img(src="/images/pages/home/global_code.png")
            h2.text-navy 1 Billion
            h5.text-navy(data-i18n="new_home.global_subtitle2")
          .col-md-3.col-xs-6
            img(src="/images/pages/home/global_teachers.png")
            h2.text-navy 140,000
            h5.text-navy(data-i18n="new_home.global_subtitle3")
          .col-md-3.col-xs-6
            img(src="/images/pages/home/global_countries.png")
            h2.text-navy 190
            h5.text-navy(data-i18n="new_home.global_subtitle4")
    .row
      .col-lg-12
        a.btn.btn-primary.btn-lg(href="/teachers/quote") {{ $t('general.contact_us') }}

</template>

<script>
import BaseSchoolFacts from './BaseSchoolFacts'
export default Vue.extend({
  components: {
    'base-school-facts': BaseSchoolFacts
  }
})
</script>

<style lang='scss' scoped>
@import "app/styles/bootstrap/variables";
@import "app/styles/mixins";
@import "app/styles/style-flat-variables";

.row-dark {
    background: linear-gradient(118.13deg, #0E4C60 0%, #20572B 100%);
}

// style-flat overwrites
h1, .text-h1 {
  font-family: $headline-font;
  font-weight: bold;
  font-size: 46px;
  line-height: 62px;
  letter-spacing: 2px;
  margin-bottom: -6px;
}

h2, .text-h2 {
  font-family: $headline-font;
  font-weight: bold;
  font-size: 33px;
  line-height: 62px;
  letter-spacing: 2.58px;
}

h3, .text-h3 {
  font-family: $headline-font;
  font-weight: bold;
  font-size: 24px;
  line-height: 32px;
  letter-spacing: 0.52px;
}

h4, .text-h4 {
  font-family: $body-font;
  font-weight: bold;
  font-size: 24px;
  line-height: 40px;
  letter-spacing: 0.56px;
}

h5, .text-h5 {
  font-family: $body-font;
  font-size: 24px;
  line-height: 30px;
  letter-spacing: 0.48px;
  font-weight: normal;
}

p, .text-p {
  font-family: $body-font;
  font-size: 18px;
  font-weight: 300;
  letter-spacing: 0.75px;
  line-height: 26px;
}

.btn-primary, .btn-navy, .btn-teal {
  background-color: $teal;
  border-radius: 4px;
  color: $gray;
  text-shadow: unset;
  text-transform: uppercase;
  font-weight: bold;
  letter-spacing: 0.71px;
  line-height: 24px;
  width: 247px;
  &:hover {
    background-color: #2DCEC8;
    transition: background-color .35s;
  }
}

.btn-primary-alt, .btn-navy-alt, .btn-teal-alt {
  background-color: transparent;
  border: 2px solid $teal;
  color: $teal;
  border-radius: 4px;
  text-shadow: unset;
  text-transform: uppercase;
  font-weight: bold;
  letter-spacing: 0.71px;
  line-height: 24px;
  width: 247px;
  &:hover {
    background-color: $teal;
    box-shadow: unset;
    color: $gray;
    transition: color .35s, background-color .35s, box-shadow .35s;
  }
}

#jumbotron-container-fluid {
  background-image: url(/images/pages/impact/BannerImage.png);
  background-size: cover;
  background-repeat: no-repeat;
  background-position: center center;
  height: 580px;
  width: 100%;
  margin: auto;

  display: flex;
  justify-content: center;
  flex-direction: column;
  text-align: center;

  & > h1 {
    font-size: 45px;
    letter-spacing: 1.96px;
    line-height: 62px;
    max-width: 801px;
    margin: 100px auto 25px;
  }
}

#impact-page {
  .width-container {
    max-width: 1170px;
    float: unset;
    margin: 0 auto;
  }

  & > .row {
    padding-top: 62px;
  }

  overflow: hidden;
}

#featured-partner-story {
  text-align: center;
  min-height: 193px;
  &.row {
    padding-top: 52px;
  }

  display: flex;
  flex-direction: column;

  & > h2 {
    flex-grow: 1;
  }

  .scroll-arrow {
    height: 32px;
    width: 100%;
    display: flex;
    .left-arrow {
      border-bottom: 32px solid white;
      border-right: 50px solid transparent;
      height: 0;
      width: 50%;
    }
    .right-arrow {
      border-bottom: 32px solid white;
      border-left: 50px solid transparent;
      height: 0;
      width: 50%;
    }
  }
}

#bobby-duke {
  h1 {
    margin-bottom: 12px;
  }
  h2 {
    letter-spacing: 0.66px;
    line-height: 30px;
    font-family: $body-font;
  }

  img {
    max-width: 165px;
  }
}

#body-text-content > p {
  margin-bottom: 24px;
  margin-left: 12px;
}

.row.teacher-quote {
  text-align: center;

  img {
    height: 33px;
    width: 35px;
    margin-bottom: 24px;
  }

  h3 {
    letter-spacing: 0.48px;
    margin-bottom: 10px;
  }

  p {
    font-size: 16px;
    line-height: 30px;
    letter-spacing: 0.32px;
    font-weight: 600;
  }
}

.quote-flex-container {
  display: flex;
  & > div {
    display: flex;
    flex-direction: column;
  }

  & > div:first-child {
    margin-right: 15px;
  }
}

.read-full-story {
  text-align: center;

  & > a.btn-primary {
    background-color: $gold;
    color: $gray;
    font-size: 18px;
    letter-spacing: 0.71px;

    &:hover {
      background-color: #FDD147;
    }
  }
}

#more-partner-stories {
  margin-top: 62px;
  h1 {
    text-align: center;
    padding-bottom: 45px;
  }

  #partner-story-tiles {
    padding-bottom: 62px;
    display: flex;
    @media (max-width: $screen-md-min) {
      flex-direction: column;
    }
    .partner-story-tile {
      background-color: white;

      display: flex;
      flex-direction: column;
      justify-content: space-between;
      align-items: center;

      margin: 0 14px;
      padding: 30px;
      border-radius: 6px;

      img.tile-header-img {
        margin-bottom: 22px;
        padding: 0 14px;
      }

      .inner-tile-school {
        &>div:first-child {
          padding-right: 0;
        }

        p {
          font-size: 14px;
          letter-spacing: 0.58px;
          line-height: 19px;
          color: $gray;
          margin-bottom: 26px;
        }
      }
    }

    h4 {
      font-size: 18px;
      line-height: 22px;
      letter-spacing: 0.75px;
    }
  }
}

#teachers-love-codecombat {
  padding-bottom: 62px;

  h1.text-teal {
    margin-bottom: 45px;
  }

  h4 {
    line-height: 30px;
    letter-spacing: 0.48px;
    margin: 0 auto 45px;
    max-width: 320px;
  }

  img {
    margin-bottom: 20px;
  }

  .mcrel-blurb {
    font-size: 18px;
    letter-spacing: 0.75px;
    line-height: 26px;
    font-style: italic;
    margin-bottom: 0;
  }

  .btn.btn-primary.btn-lg {
    width: unset;
    margin-bottom: 45px
  }

}

#teacher-student-spotlight {
  & > div:nth-child(1) {
    display: flex;
    flex-direction: column;
  }

  padding-bottom: 62px;

  h2 {
    margin-bottom: 45px;
  }
  #teacher-student-tiles {
    display: flex;

    @media (max-width: $screen-md-min) {
      flex-direction: column;
    }

    .teacher-student-tile {
      margin: 15px;
      background-color: white;
      border-radius: 6px;
      padding: 9px 45px 10px;

      display: flex;
      flex-direction: column;
      justify-content: space-between;

    }
  }

  .teacher-description {
    display: flex;
    align-items: center;

    min-height: 133px;
    margin-bottom: 20px;
    border-bottom: 2.59px $teal solid;
    
  }

  h3 {
    font-size: 20px;
    line-height: 30px;
    letter-spacing: 0.4px;
  }

  h5 {
    font-size: 18px;
    line-height: 24px;
    letter-spacing: 0.36px;
  }

  .teacher-thumbnail {
    padding: 0;
  }

  .teacher-bio {
    padding: 0 0 0 10px;
  }

  .continue-reading-link {
    font-size: 14px;
    line-height: 19px;
    letter-spacing: 0.58px;
  }
}

#global {
  &.row {
    padding-top: 0;
    padding-bottom: 12px;
  }
  .row {
    padding: 62px 15px 0;
  }
  img {
    height: 82px;
    }
  h2.text-teal {
    margin-bottom: 30px;
  }
  h2.text-navy {
    margin-top: 14px;
    margin-bottom: -14px;
  }
  h5 {
    font-weight: normal;
  }
  .col-xs-6 {
    padding: 10px 15px;
  }
}

</style>
