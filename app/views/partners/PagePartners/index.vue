<template lang="pug">
.container-fluid#partners-page
  .header
    .width-container.text-center.row
      .col-lg-12
        h1.text-h1.text-navy {{ $t("partners.headline") }}

    .width-container.text-center.row
      .col-lg-12
        a.btn.btn-primary.btn-lg(href="https://form.typeform.com/to/loZIh0I9" target="_blank") {{ $t('general.contact_us') }}

    .width-container.text-center.row
      .col-lg-12
        h5.text-h5.text-teal {{ $t("partners.below_headline_blurb") }}

  .width-container.row.image-row
    .col-md-9
      p.text-navy
        strong {{ $t("partners.coding_title") }}
        | &nbsp;
        span {{ $t("partners.coding_blurb") }}
    .col-md-3
      img.img-responsive(src="/images/pages/partners/coding.jpg")

  .width-container.row.image-row
    .col-md-3
      img.img-responsive(src="/images/pages/partners/powered-by-hyper.png")
    .col-md-9
      p.text-navy
        strong {{ $t("partners.esports_title") }}
        | &nbsp;
        span(v-html="$t('partners.esports_blurb', i18nData)")

  .width-container.row.image-row
    .col-sm-12
      p.text-navy
        strong {{ $t("partners.distribution_title") }}
        | &nbsp;
        span(v-html="$t('partners.distribution_blurb', i18nData)")

  .width-container.row.image-row
    .col-md-9
      p.text-navy
        strong {{ $t("partners.equity_social_title") }}
        | &nbsp;
        span(v-html="$t('partners.equity_social_blurb', i18nData)")
        span(v-html="$t('partners.seek_relationships_blurb', i18nData)")
    .col-md-3
      img.img-responsive(src="/images/pages/partners/seeds-of-light.jpg" alt="Seeds of Light")

  .width-container.row
    .col-lg-12
      p.text-navy
        span(v-html="$t('partners.latin_superstar_blurb', i18nData)")



  .row.width-container.image-row.quote-row
    .col-md-5.col-md-offset-1.col-sm-12.teacher-quote.col-sm-offset-0
      h3.text-h3.text-navy {{ $t("partners.eugenio_derbez_blurb") }}
    .col-md-5.col-sm-12
      img.img-responsive(src="/images/pages/partners/Eugenio-Derbez.png" alt="Eugenio Derbez")

  .width-container.row.image-row
    .col-md-3
      img.img-responsive(src="/images/pages/partners/corporate.png")
    .col-md-9
      p.text-navy
        strong {{ $t("partners.corporate_team_building_title") }}
        | &nbsp;
        span(v-html="$t('partners.corporate_team_building_blurb', i18nData)")


  .width-container.row
    .col-lg-12
      p.text-navy {{ $t("partners.footer_blurb") }}

  .width-container.text-center.row
    .col-lg-12
      a.btn.btn-primary.btn-lg(href="https://form.typeform.com/to/loZIh0I9" target="_blank") {{ $t("partners.talk_with_us") }}

</template>

<script>
export default Vue.extend({
  data() {
    return {
      i18nData: {
        hyperx: `<a href='/league' target='_blank'>${$.i18n.t('partners.hyperx')}</a>`,
        respawn: `<a href='/league/#winners' target='_blank'>${$.i18n.t('partners.respawn')}</a>`,
        forty_languages: `<a href='/contribute/diplomat' target='_blank'>${$.i18n.t('partners.forty_languages')}</a>`,
        reach_latinx: `<a href='https://www.yahoo.com/now/mexican-superstar-eugenio-derbez-partners-200100110.html' target='_blank'>${$.i18n.t('partners.reach_latinx')}</a>`,
        seeds_of_light: `<a href='https://www.accesswire.com/702186/Seeds-of-Light-and-CodeCombat-Expand-Partnership-with-Launch-of-Glow-Academies-for-Middle-School-Students' target='_blank'>${$.i18n.t('partners.seeds_of_light')}</a>`,
        eugenio_derbez: "<a href='https://www.businesswire.com/news/home/20210316006024/en/Mexican-Superstar-Eugenio-Derbez-Partners-with-CodeCombat-to-Get-the-Latinx-Community-Coding' target='_blank'>Eugenio Derbez</a>",
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
  font-size: 28px;
  line-height: 40px;
  letter-spacing: 0.52px;
}


.text-h5 {
  font-family: $body-font;
  font-size: 36px;
  line-height: 46px;
  letter-spacing: 0.48px;
  font-weight: normal;
}

p, .text-p {
  font-family: $body-font;
  font-size: 28px;
  font-weight: 300;
  letter-spacing: 0.75px;
  line-height: 38px;
  text-align: justify;
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

  .header .row {
    padding: 20px 0;
  }

  & > .row {
    padding: 5px 0 0;
    &.image-row {
      padding-bottom: 15px;

      @media (max-width: $screen-md-min) {
        padding: 40px 0;
      }
    }
    &.quote-row {
      padding: 30px 0;
    }

  }

  overflow: hidden;

  .img-responsive {
    width: 100%;
  }
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
