<template lang="pug">
  div#base-school-facts
    .row.teacher-portrait-section
      .col-xs-4.teacher-img
        img.img-responsive(src="/images/pages/impact/Scott.png")
      .col-xs-8
        h3.text-gold {{ $t('impact.featured_teacher') }}
        h4.text-gold {{ $t('impact.teacher_title') }}
    .row.teal-line
    .row.extra-bottom-margin
      h3.text-gold.text-center {{ $t('impact.implementation') }}
      .row.single-stat
        .col-xs-7.left-text-header
          p.text-teal {{ $t('impact.grades_taught') }}
        .col-xs-5.right-text-stat
          p.text-white 7-8
      .row.single-stat
        .col-xs-7.left-text-header
          p.text-teal {{ $t('impact.length_use') }}
        .col-xs-5.right-text-stat
          p.text-white {{ $t('impact.length_use_time') }}
      .row.single-stat
        .col-xs-7.left-text-header
          p.text-teal {{ $t('impact.students_enrolled') }}
        .col-xs-5.right-text-stat
          p.text-white {{ $t('impact.students_enrolled_number') }}
    .row.extra-bottom-margin
      h3.text-gold.text-center {{ $t('impact.courses_covered') }}
      .col-xs-6.courses-covered-left-column
        ul
          li
            span.text-white {{ $t('impact.course1') }}
          li
            span.text-white {{ $t('impact.course2') }}
          li
            span.text-white {{ $t('impact.course3') }}
      .col-xs-6
        ul
          li
            span.text-white {{ $t('impact.course4') }}
          li
            span.text-white {{ $t('impact.course5') }}
    .row.extra-bottom-margin
      h3.text-gold.text-center {{ $t('impact.fav_features') }}
      .col-xs-12.favourite-features
        ul
          li
            span.text-white {{ $t('impact.responsive_support') }}
          li
            span.text-white {{ $t('impact.immediate_engagement') }}
</template>

<style lang="scss" scoped>
@import "app/styles/style-flat-variables";

#base-school-facts {
  background-color: $navy;
  padding: 31px 21px;
}

.teacher-portrait-section {
  display: flex;
  justify-content: center;
  h3 {
    margin: 0;
  }
}

.single-stat {
  display: flex;
  margin-bottom: 15px;

  .left-text-header {
    padding-right: 0px;
  }
  .right-text-stat {
    padding-left: 8px;

    display: flex;
    flex-direction: column;
    justify-content: center;
  }
  
  p {
    font-size: 14px;
    letter-spacing: 0.58px;
    line-height: 19px;
    margin: 0;
  }

  p.text-teal {
    font-family: $body-font;
    font-size: 14px;
    font-weight: bold;
    text-align: right;
  }
}

h3 {
  font-family: $headline-font;
  line-height: 23px;
  letter-spacing: 1px;
  font-size: 18px;
  font-weight: bold;
  margin-bottom: 16px;
}

h4 {
  font-family: $body-font;
  font-size: 14px;
  line-height: 19px;
  letter-spacing: 0.58px;
}

.teacher-img {
  padding-right: 0;
  max-width: 80px;
}

.row.teal-line {
  margin: 10px 0 20px;
  border-top: 2.59px $teal solid;
}

ul li {
  font-family: $body-font;
  font-size: 14px;
  line-height: 19px;
  letter-spacing: 0.58px;
  color: $teal;
  font-weight: normal;
}

ul {
  padding: 0;
  display: inline-block;
}

.courses-covered-left-column {
  text-align: right;
}

.favourite-features {
  display: flex;
  justify-content: center;
  /* Lines up dot point with point above */
  padding-left: 6px;
}

.extra-bottom-margin{
  margin-bottom: 15px;
}


</style>
