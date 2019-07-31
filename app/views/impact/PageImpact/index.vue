<template lang="pug">
.container-fluid#impact-page
  .row#jumbotron-container-fluid
    h1.text-white {{ $t('impact.hero_heading')}}
    h5.text-white {{ $t('impact.hero_subheading') }}
  .row#featured-partner-story
    h2.text-gold {{ $t('impact.featured_partner_story') }}

    .scroll-arrow
      .left-arrow
      .right-arrow

  .row#bobby-duke
    .col-lg-12
      h1 {{ $t('impact.partner_heading') }}
      h2 {{ $t('impact.partner_school') }}
  .row
    .col-lg-1
      //- empty
    .col-lg-3
      h3 {{ $t('impact.featured_teacher') }}
      h4 {{ $t('impact.teacher_title') }}
      h3 {{ $t('impact.implementation') }}
      p {{ $t('impact.grades_taught') }} 7-8
      p {{ $t('impact.length_use') }} {{ $t('impact.length_use_time') }}
      p {{ $t('impact.students_enrolled') }} {{ $t('impact.students_enrolled_number') }}
      .row
        h3 {{ $t('impact.courses_covered') }}
        ul
          li {{ $t('impact.course1') }}
          li {{ $t('impact.course2') }}
          li {{ $t('impact.course3') }}
          li {{ $t('impact.course4') }}
          li {{ $t('impact.course5') }}
      h3 {{ $t('impact.fav_features') }}
      ul
        li {{ $t('impact.responsive_support') }}
        li {{ $t('impact.immediate_engagement') }}
    .col-lg-7
      p {{ $t('impact.paragraph1') }}
      p {{ $t('impact.paragraph2') }}
      p {{ $t('impact.paragraph3') }}
  .row
    .col-lg-1
      //- Space
    .col-lg-4
      .row
        span "
      .row
        h2 {{ $t('impact.teacher_quote') }}
        h3 {{ $t('impact.quote_attribution') }}

    .col-lg-6
      img.img-responsive(src="/images/pages/impact/image5.png" alt="Students using CodeCombat in a classroom")
  .row
    .col-lg-12
      button {{ $t('impact.read_full_story') }}
  .row
    h1.text-gold {{ $t('impact.more_stories') }}

  .row
    //- TODO: Make this duplication a component
    .col-lg-4
      img.img-responsive(src="/images/pages/impact/PrestonHSPhoto.png")
      .row
        .col-xs-3
          img.img-responsive(src="/images/pages/impact/Preston High School logo.png")
        .col-xs-9
          h4.text-teal {{ $t('impact.partners_heading_1') }}
          p {{ $t('impact.partners_school_1') }}
      .row
        button {{ $t('impact.read_full_story') }}
    .col-lg-4
      img.img-responsive(src="/images/pages/impact/RiverRidgePhoto.png")
      .row
        .col-xs-3
          img.img-responsive(src="/images/pages/impact/rrhs-logo-1-1.png")
        .col-xs-9
          h4.text-teal {{ $t('impact.partners_heading_2') }}
          p {{ $t('impact.partners_school_2') }}
      .row
        button {{ $t('impact.read_full_story') }}
    .col-lg-4
      img.img-responsive(src="/images/pages/impact/RiverdalePhoto.png")
      .row
        .col-xs-3
          img.img-responsive(src="/images/pages/impact/Riverdale High School.fw.png")
        .col-xs-9
          h4.text-teal {{ $t('impact.partners_heading_3') }}
          p {{ $t('impact.partners_school_3') }}
      .row
        button {{ $t('impact.read_full_story') }}

  //- html structure copied directly from home page
  .row.row-dark.text-center#teachers-love-codecombat
      .col-lg-12
        h1.text-white(data-i18n="new_home.teachers_love_codecombat_title")
        .row
          .col-xs-4
            .width-320
              h1.text-gold 99%
              img(src="/images/pages/home/pink_rectangle.png")
              h4.text-blue(data-i18n="new_home.teachers_love_codecombat_blurb1")
          .col-xs-4
            .width-320
              h1.text-gold 95%
              img(src="/images/pages/home/pink_rectangle.png")
              h4.text-blue(data-i18n="new_home.teachers_love_codecombat_blurb2")
          .col-xs-4
            .width-320
              h1.text-gold 94%
              img(src="/images/pages/home/pink_rectangle.png")
              h4.text-blue(data-i18n="new_home.teachers_love_codecombat_blurb3")
        p.mcrel-blurb(data-i18n="new_home.teachers_love_codecombat_subblurb")
        button {{ $t('impact.download_study') }}

  .row
    .col-lg-12
      h1.text-gold {{ $t('impact.teacher_spotlight') }}
    //- TODO: Componentize
    .col-lg-4
      .row
        .col-xs-3
          img.img-responsive(src="/images/pages/impact/teacher_thumbnail_1.png")
        .col-xs-9
          h2 {{ $t('impact.teacher_name_1') }}
          h4 {{ $t('impact.teacher_title_1') }}
          h4 {{ $t('impact.teacher_location_1') }}
      .row
        p {{ $t('impact.spotlight_1') }}
      .row
        p {{ $t('impact.continue_reading_blog') }}

    .col-lg-4
      .row
        .col-xs-3
          img.img-responsive(src="/images/pages/impact/teacher_thumbnail_2.png")
        .col-xs-9
          h2 {{ $t('impact.teacher_name_2') }}
          h4 {{ $t('impact.teacher_title_2') }}
          h4 {{ $t('impact.teacher_location_2') }}
      .row
        p {{ $t('impact.spotlight_2') }}
      .row
        p {{ $t('impact.continue_reading_blog') }}

    .col-lg-4
      .row
        .col-xs-3
          img.img-responsive(src="/images/pages/impact/teacher_thumbnail_3.png")
        .col-xs-9
          h2 {{ $t('impact.teacher_name_3') }}
          h4 {{ $t('impact.teacher_title_3') }}
          h4 {{ $t('impact.teacher_school_3') }}
          h4 {{ $t('impact.teacher_location_3') }}
      .row
        p {{ $t('impact.spotlight_3') }}
      .row
        p {{ $t('impact.continue_reading_blog') }}

  .row.row-dark.text-center#global
    .col-lg-12
      h2.text-white(data-i18n="new_home.global_title")
      .container
        .row
          .col-md-3.col-xs-6
            img(src="/images/pages/home/global_learners.png")
            h2.text-gold 12 Million
            h5.text-white(data-i18n="new_home.global_subtitle1")
          .col-md-3.col-xs-6
            img(src="/images/pages/home/global_code.png")
            h2.text-gold 1 Billion
            h5.text-white(data-i18n="new_home.global_subtitle2")
          .col-md-3.col-xs-6
            img(src="/images/pages/home/global_teachers.png")
            h2.text-gold 82,000
            h5.text-white(data-i18n="new_home.global_subtitle3")
          .col-md-3.col-xs-6
            img(src="/images/pages/home/global_countries.png")
            h2.text-gold 190
            h5.text-white(data-i18n="new_home.global_subtitle4")
    .col-lg-12
      button {{ $t('general.contact_us') }}

</template>

<script>
export default Vue.extend({})
</script>

<style lang='scss' scoped>
@import "app/styles/bootstrap/variables";
@import "app/styles/mixins";
@import "app/styles/style-flat-variables";

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
    margin: 100px auto 0;
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
  background: linear-gradient(118.13deg, #0E4C60 0%, #20572B 100%);
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

</style>
