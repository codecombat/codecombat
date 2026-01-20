<template lang="pug">
  PageSection.section
    template(#body)
      #featured-in-awards.container
        .col-xs-12.col-md-5.text-center.featured-in
          h1(data-i18n="new_home.featured_partners_title1")
          .row
            a.col-xs-5.col-xs-offset-1(href="https://www.bbc.co.uk/programmes/articles/56ZcVFcY47vkvnFphmNhRd3/hour-of-code-2016" target="_blank" rel="noopener noreferrer")
              .centered-flex
                img.img-responsive(src="/images/pages/home-v2/bbc-logo.png" loading="lazy" style="max-height: 120px;" alt="BBC logo")
            a.col-xs-5(href="https://www.edsurge.com/news/2016-05-02-codecombat-scores-2-million-seed-round-to-bring-programming-adventure-to-schools" target="_blank" rel="noopener noreferrer")
              .centered-flex
                img.img-responsive(src="/images/pages/home-v2/edsurge-logo.png" loading="lazy" style="height: 39px; max-width: 158px;" alt="EdSurge logo")
            a.col-xs-5.col-xs-offset-1(href="https://www.wsj.com/articles/codecombat-uses-fantasy-games-to-teach-coding-in-schools-1462188602" target="_blank" rel="noopener noreferrer")
              .centered-flex
                img.img-responsive(src="/images/pages/home-v2/wsj-logo.png" loading="lazy" style="max-height: 60px;" alt="Wall Street Journal logo")
            a.col-xs-5(href="https://techcrunch.com/2014/03/19/yc-backed-codecombat-wants-you-to-learn-to-code-by-playing-games/" target="_blank" rel="noopener noreferrer")
              .centered-flex
                img.img-responsive(src="/images/pages/home-v2/techcrunch-logo.png" loading="lazy" style="max-height: 60px;" alt="TechCrunch logo")
        .col-xs-12.col-md-7.text-center.awards-partners
          h1(data-i18n="new_home.featured_partners_title2")
          .row
            a.col-xs-3.col-xs-offset-1(href="https://www.csforall.org/projects_and_programs/member_directory/members/codecombat/" target="_blank" rel="noopener noreferrer")
              .centered-flex
                img.img-responsive(src="/images/pages/home-v2/csforall-member-logo.png" loading="lazy" style="max-height: 60px;" alt="CSforAll Logo")
                p(data-i18n="new_home.featured_partners_blurb5")
            a.col-xs-4(href="https://history.siia.net/codie/About/Past-Winners/Past/pID/2017" target="_blank" rel="noopener noreferrer")
              .centered-flex
                img.img-responsive(src="/images/pages/home-v2/codie-award.png" loading="lazy" style="max-height: 60px;" alt="CODiE award logo")
                p(data-i18n="new_home.featured_partners_blurb2")
            a.col-xs-3(href="https://www.commonsense.org/education/reviews/codecombat" target="_blank" rel="noopener noreferrer")
              .centered-flex
                img.img-responsive(src="/images/pages/home-v2/commonsense-logo.png" loading="lazy" style="max-height: 80px;" alt="CommonSense Media award logo")
                p(data-i18n="new_home.featured_partners_blurb3")
            a.col-xs-3.col-xs-offset-2(href="https://code.org/educate/curriculum/middle-school" target="_blank" rel="noopener noreferrer")
              .centered-flex
                img.img-responsive(src="/images/pages/home-v2/code-org-logo.png" loading="lazy" style="max-height: 60px;" alt="Code.org logo")
                p(data-i18n="new_home.featured_partners_blurb4")
            a.col-xs-4.col-xs-offset-1(href="https://aws.amazon.com/blogs/publicsector/aws-educate-and-amazon-future-engineer-teamed-with-codecombat-to-create-a-new-game-for-the-hour-of-code/" target="_blank" rel="noopener noreferrer")
              .centered-flex
                img.img-responsive(src="/images/pages/home-v2/afe-logo.png" loading="lazy" style="max-height: 50px;" alt="Amazong Future Engineer logo")
                p(data-i18n="new_home.featured_partners_blurb6")
</template>
<script>
import PageSection from '../../../../components/common/elements/PageSection'
export default {
  name: 'PageSection10',
  components: {
    PageSection,
  },
}

</script>
<style lang="sass" scoped>
@import "app/styles/bootstrap/variables"
@import "app/styles/mixins"
@import "app/styles/style-flat-variables"
img
  width: unset !important
#featured-in-awards
  $teal-dark: #0E4C60
  margin-top: 10px

  h1
    font-size: 40px
    line-height: 43px

  .row
    min-height: 316px
    padding: 33px 0 0 0

  .centered-flex
    height: 150px

  .featured-in, .awards-partners
    border: 4px dashed #F2D269
    padding: 50px 0 20px 0

  .featured-in
    border-radius: 20px 0 0 20px
    border-right: unset

  .awards-partners
    border-radius: 0 20px 20px 0
    .centered-flex
      flex-direction: column
      color: $teal-dark

      p
        margin-top: 10px
        font-size: 13px
        line-height: 17px
        letter-spacing: 0.25px

  @media screen and (max-width: 991px)
    .featured-in, .awards-partners
      border: unset
.centered-flex
  display: flex
  align-items: center
  justify-content: center
</style>