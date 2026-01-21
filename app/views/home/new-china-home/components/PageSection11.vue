<template lang="pug">
  PageSection.section
    template(#body)
      .container-background-faq
        .container
          .row.row-eq-height
            .col-lg-12.text-center.container-background-header
              h1.pixelated(data-i18n="nav.faqs")
          .row.row-eq-height
            .col-md-4.col-sm-6.col-xs-12
              b(data-i18n="new_home_faq.what_programming_languages")
              p(data-i18n="new_home_faq.python_and_javascript")
              b(data-i18n="new_home_faq.why_python")
              p(data-i18n="new_home_faq.why_python_blurb")
              b(data-i18n="new_home_faq.why_javascript")
              p(data-i18n="new_home_faq.why_javascript_blurb")
              p(data-i18n="new_home_faq.javascript_versus_python")
            .col-md-4.col-sm-6.col-xs-12
              b(data-i18n="new_home_faq.how_do_i_get_started")
              ol
                li(data-i18n="new_home_faq.getting_started_1")
                li(data-i18n="new_home_faq.getting_started_2")
                li(data-i18n="new_home_faq.getting_started_3")
              b(data-i18n="new_home_faq.mobile_question")
              p(data-i18n="new_home_faq.mobile_question_blurb")
            .col-md-4.col-sm-6.col-xs-12
              b(data-i18n="new_home_faq.how_much_does_it_cost")
              p(data-i18n="[html]new_home_faq.how_much_does_it_cost_blurb", data-i18n-options=JSON.stringify(i18nData))
              b(data-i18n="new_home_faq.recommended_systems")
              p(data-i18n="new_home_faq.recommended_systems_blurb")
          .text-center
            p.contact-us(data-i18n="[html]new_home_faq.other_questions", data-i18n-options=JSON.stringify(i18nData))
    template(#tail)
      .footer
        a.small(href="http://beian.miit.gov.cn/") 京ICP备19012263号-20
        a.small(href="http://www.beian.gov.cn/portal/registerSystemInfo?recordcode=11010802038619")
          img#mps(src="/images/pages/base/the_ministry_of_public_security_of_china.png")
          span='京公网安备 11010802038619号'
</template>
<script>
import PageSection from '../../../../components/common/elements/PageSection'

import FinalFooter from 'app/components/common/FinalFooter'
export default {
  name: 'PageSection11',
  components: {
    PageSection,
    FinalFooter,
  },
}

</script>
<style scoped lang="sass">
@import "app/styles/bootstrap/variables"
@import "app/styles/mixins"
@import "app/styles/style-flat-variables"
.section
  $teal-light-1: #1FBAB4
  $teal-light-2: #6AE8E3

  .row.row-eq-height
    display: flex
    flex-wrap: wrap

  .row.row-eq-height > [class*='col-']
    display: flex
    flex-direction: column
    margin-top: 30px

  .container-background-faq
    margin-top: 50px
    margin-bottom: 50px
    .row.row-eq-height
      padding: 0

    .row .text-h4
      margin-top: 30px

    .row.faq-links-row
      margin: 0
      padding: 0
      text-align: center

      p
        font-size: 18px
        line-height: 22px
        color: black

    & > .container
      border: 4px solid $teal-light-2
      border-radius: 40px
      border-top: none
      position: relative
      padding: 30px

      & > div:last-of-type
        margin: 32px 0 0

    .text-h4
      font-size: 16px
      line-height: 17px
      letter-spacing: 0.333px

    p, ol
      font-size: 14px
      line-height: 18px
      letter-spacing: 0.267px
      color: $pitch

  .container-background-header
    position: absolute
    transform: translateY(-60px)
    width: calc(100% - 30px)

  /* These create the broken top border which FAQ sits between */
  /* Top left border */
  .container-background-faq > .container::after
    content: ''
    position: absolute
    height: 100px
    width: 37%
    border-top: 4px solid $teal-light-2
    border-left: 4px solid $teal-light-2
    top: 0
    left: -4px
    border-radius: 40px 0 0 0

  /* Top right border */
  .container-background-faq > .container::before
    content: ''
    position: absolute
    height: 100px
    width: 37%
    border-top: 4px solid $teal-light-2
    border-right: 4px solid $teal-light-2
    top: 0
    right: -4px
    border-radius: 0px 40px 0 0

  .carousel-dot
    display: inline-block
    width: 13px
    height: 13px
    border-radius: 6.5px
    margin: 5px
    background-color: #C4C4C4

    &:not(.active)
      cursor: pointer

    &.active
      background-color: $teal-light-1
      cursor: default

.footer
  position: absolute
  bottom: 0
  left: -45vw
  width: 90vw
  height: 10px
  text-align: center
  .small
    margin-right: 10px
  #mps
    width: 10px
</style>