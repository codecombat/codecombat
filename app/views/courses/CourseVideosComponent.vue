<template lang="pug">
  .container.m-t-3
    p
      a(href="/students", data-i18n="courses.back_courses")
    div.m-t-2
      h2(v-if="courseName").text-center.course-name
        | {{ courseName }}
      h1.text-center
        | {{ $t('courses.concept_videos') }}
    
    div.m-t-3#videos-content
      .row.m-t-5
        .col-md-6
          iframe.video(src="https://player.vimeo.com/video/310626758" frameborder= "2" webkitallowfullscreen mozallowfullscreen allowfullscreen)
        .col-md-6.rtl-allowed.concept-text
          .semibold.m-l-5.concept-heading
            span.spr(data-i18n="courses.concept")
            span.spr(data-i18n="courses.basic_syntax")
          p.m-l-5.m-t-2.concept-desc
            span(data-i18n="courses.basic_syntax_desc")
      
      .row.m-t-5
        .col-md-6
          iframe.video(src="https://player.vimeo.com/video/310626741" frameborder= "0" webkitallowfullscreen mozallowfullscreen allowfullscreen)
        .col-md-6.rtl-allowed.concept-text
          .semibold.m-l-5.concept-heading
            span.spr(data-i18n="courses.concept")
            span.spr(data-i18n="courses.while_loops")
          p.m-l-5.m-t-2.concept-desc
            span(data-i18n="courses.while_loops_desc")

      .row.m-t-5
        .col-md-6
          iframe.video(src="https://player.vimeo.com/video/310626807" frameborder= "0" webkitallowfullscreen mozallowfullscreen allowfullscreen)
        .col-md-6.rtl-allowed.concept-text
          .semibold.m-l-5.concept-heading
            span.spr(data-i18n="courses.concept")
            span.spr(data-i18n="courses.variables")
          p.m-l-5.m-t-2.concept-desc
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
    height: 320px

.concept-heading
  font-size: 16pt
</style>