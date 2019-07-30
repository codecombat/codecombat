<template lang="pug">
.container-fluid#impact-page
  .row#jumbotron-container-fluid
    .col-lg-12
      h1.text-white {{ $t('impact.hero_heading')}}
      h2.text-white {{ $t('impact.hero_subheading') }}
  .row#featured-partner-story
    .col-lg-12
      h1.text-gold {{ $t('impact.featured_partner_story') }}
    //- Figure out the arrow.
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

#jumbotron-container-fluid {
  background-image: url(/images/pages/impact/BannerImage.png);
  background-size: cover;
  background-repeat: no-repeat;
  background-position: center center;
  height: 627px;
  width: 100%;
  margin: auto;
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
}


</style>
