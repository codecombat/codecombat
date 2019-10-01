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
          div(v-if="showChinaVideo")
            video(controls width="568" height="320")
              source(:src="videoUrls.basic_syntax" type="video/mp4")
          div(v-else)
            iframe.video(:src="videoUrls.basic_syntax" frameborder= "2" webkitallowfullscreen mozallowfullscreen allowfullscreen)
        .col-md-6.rtl-allowed.concept-text
          .semibold.m-l-5.concept-heading
            span.spr(data-i18n="courses.concept")
            span.spr(data-i18n="courses.basic_syntax")
          p.m-l-5.m-t-2.concept-desc
            span(data-i18n="courses.basic_syntax_desc")
      
      .row.m-t-5
        .col-md-6
          div(v-if="showChinaVideo")
            video(controls width="568" height="320")
              source(:src="videoUrls.while_loops" type="video/mp4")
          div(v-else)
            iframe.video(:src="videoUrls.while_loops" frameborder= "0" webkitallowfullscreen mozallowfullscreen allowfullscreen)
        .col-md-6.rtl-allowed.concept-text
          .semibold.m-l-5.concept-heading
            span.spr(data-i18n="courses.concept")
            span.spr(data-i18n="courses.while_loops")
          p.m-l-5.m-t-2.concept-desc
            span(data-i18n="courses.while_loops_desc")

      .row.m-t-5
        .col-md-6
          div(v-if="showChinaVideo")
            video(controls width="568" height="320")
              source(:src="videoUrls.variables" type="video/mp4")
          div(v-else)
            iframe.video(:src="videoUrls.variables" frameborder= "0" webkitallowfullscreen mozallowfullscreen allowfullscreen)
        .col-md-6.rtl-allowed.concept-text
          .semibold.m-l-5.concept-heading
            span.spr(data-i18n="courses.concept")
            span.spr(data-i18n="courses.variables")
          p.m-l-5.m-t-2.concept-desc
            span(data-i18n="courses.variables_desc")
</template>

<script>

import utils from 'core/utils'
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
  },
  data: () => ({
    videoUrls: {
        basic_syntax:"",
        while_loops:"",
        variables:""
    }
  }),
  created() {
    let levelMap = {
        basic_syntax: "54173c90844506ae0195a0b4",
        while_loops: "55ca293b9bc1892c835b0136",
        variables: "5452adea57e83800009730ee"
    }
    for (let level in levelMap){
        let levelId = levelMap[level];
        this.videoUrls[level] = me.showChinaVideo() ?
            utils.videoLevels[levelId].cn_url :
            utils.videoLevels[levelId].url;
    }
  },
  computed: {
    showChinaVideo: function() {
      return me.showChinaVideo();
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