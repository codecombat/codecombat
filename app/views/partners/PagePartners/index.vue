<template lang="pug">
.container-fluid#partners-page
  .width-container.text-center.row
    .col-lg-12
      h1.text-h1.text-navy(data-i18n="partners.headline")
  .width-container.text-center.row
    .col-lg-12
      a.btn.btn-primary.btn-lg(href="https://form.typeform.com/to/loZIh0I9" target="_blank") {{ $t('general.contact_us') }}
  .width-container.text-center.row
    .col-lg-12
      h5.text-h5.text-teal(data-i18n="partners.below_headline_blurb")

  .width-container.row.justify-content-center
    .col-sm-offset-1.col-sm-6.col-xs-12
      p.text-navy
        strong(data-i18n="partners.coding_title")
        | &nbsp;
        span(data-i18n="partners.coding_blurb")
    .col-sm-3.col-xs-8.col-xs-offset-2.col-sm-offset-0
      img.img-responsive(src="/images/pages/partners/coding.jpg")

  .width-container.row.justify-content-center
    .col-sm-offset-1.col-sm-3.col-xs-8.col-xs-offset-2
      img.img-responsive(src="/images/pages/partners/powered-by-hyper.png")
    .col-sm-6
      p.text-navy
        strong(data-i18n="partners.esports_title")
        | &nbsp;
        span(data-i18n="[html]partners.esports_blurb" :data-i18n-options="`${JSON.stringify(i18nData)}`")

  .width-container.row
    .col-lg-12
      p.text-navy
        strong(data-i18n="partners.distribution_title")
        | &nbsp;
        span(data-i18n="[html]partners.distribution_blurb" :data-i18n-options="`${JSON.stringify(i18nData)}`")


  .width-container.row
    .col-lg-12
      p.text-navy
        strong(data-i18n="partners.equity_social_title")
        | &nbsp;
        span(data-i18n="[html]partners.equity_social_blurb" :data-i18n-options="`${JSON.stringify(i18nData)}`")

  .row.width-container
    .col-md-4.col-md-offset-1.col-sm-12.teacher-quote
      img(src="/images/pages/home/teal_quote.png")
      h3.text-h3.text-navy(data-i18n="partners.eugenio_derbez_blurb")
    .col-md-6.col-sm-12
      img.img-responsive(src="/images/pages/partners/Eugenio-Derbez.png" alt="Eugenio Derbez")


  .width-container.row
    .col-lg-12
      p.text-navy(data-i18n="partners.footer_blurb")

  .width-container.text-center.row
    .col-lg-12
      a.btn.btn-primary.btn-lg(href="https://form.typeform.com/to/loZIh0I9" data-i18n="partners.talk_with_us" target="_blank")

</template>

<script>
export default Vue.extend({
  data() {
    return {
      i18nData: {
        hyperx: `<a href='https://www.yahoo.com/now/hyperx-partners-codecombat-esports-coding-175900451.html' target='_blank'>${$.i18n.t('partners.hyperx')}</a>`,
        respawn: `<a href='/league/#winners' target='_blank'>${$.i18n.t('partners.respawn')}</a>`,
        forty_languages: `<a href='/contribute/diplomat' target='_blank'>${$.i18n.t('partners.forty_languages')}</a>`,
        reach_latinx: `<a href='https://www.yahoo.com/now/mexican-superstar-eugenio-derbez-partners-200100110.html' target='_blank'>${$.i18n.t('partners.reach_latinx')}</a>`,
        interpolation: { escapeValue: false }
      }
    }
  },

})
</script>

<style lang='scss' scoped>
@import "app/styles/bootstrap/variables";
@import "app/styles/mixins";
@import "app/styles/style-flat-variables";

// style-flat overwrites
.text-h1 {
  font-family: $headline-font;
  font-weight: bold;
  font-size: 46px;
  line-height: 62px;
  letter-spacing: 2px;
  margin-bottom: -6px;
}

.text-h3 {
  font-family: $headline-font;
  font-weight: bold;
  font-size: 24px;
  line-height: 32px;
  letter-spacing: 0.52px;
}


.text-h5 {
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

#partners-page {
  .width-container {
    max-width: 1170px;
    float: unset;
    margin: 0 auto;
  }

  & > .row {
    padding-top: 31px;
    padding-bottom: 31px;
  }

  overflow: hidden;
}

.teacher-quote {
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


</style>
