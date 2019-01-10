<template lang="pug">
  .container.m-t-3
    p
      a(href="/students", data-i18n="courses.back_courses")
    div.m-t-2
      h2(v-if="courseName").text-center
        | {{ courseName }}
      h1.text-center
        | {{ $t('courses.concept_videos') }}
    
    div.m-t-3#videos-content
      .row.m-t-5
        .col-md-6
          //- TODO: replace video links with youtube links
          iframe.video(src="https://drive.google.com/file/d/1-KXwREwK4s3kbtsXV-neSkQCnwG9DVOy/preview" frameborder= "2" allowfullscreen)
        .col-md-6.rtl-allowed
          .semibold.m-l-5.concept-text
            span.spr(data-i18n="courses.concept")
            span.spr(data-i18n="courses.basic_syntax")
          p.m-l-5.m-t-2
            span(data-i18n="courses.basic_syntax_desc")
      
      .row.m-t-5
        .col-md-6
          iframe.video(src="https://drive.google.com/file/d/1vwKu_H0YTalWQFAD45DEc6sKheKiB3Et/preview" frameborder= "0" allowfullscreen)
        .col-md-6.rtl-allowed
          .semibold.m-l-5.concept-text
            span.spr(data-i18n="courses.concept")
            span.spr(data-i18n="courses.while_loops")
          p.m-l-5.m-t-2
            span(data-i18n="courses.while_loops_desc")

      .row.m-t-5
        .col-md-6
          iframe.video(src="https://drive.google.com/file/d/1sMhk64HloRbcrXQu8wO-MWwRfpt_66oy/preview" frameborder= "0" allowfullscreen)
        .col-md-6.rtl-allowed
          .semibold.m-l-5.concept-text
            span.spr(data-i18n="courses.concept")
            span.spr(data-i18n="courses.variables")
          p.m-l-5.m-t-2
            span(data-i18n="courses.variables_desc")
</template>

<script>

export default Vue.extend({
  name: 'course-videos-component',
  props: {
    courseID:{
      type: String,
      default: null
    },
    courseName:{
      type: String,
      default: null
    }
  }
});

</script>

<style lang="sass">

#videos-content
  .video
    width: 600px
    height: 315px

.concept-text
  font-size: 16pt
</style>