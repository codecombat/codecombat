<template lang="pug">
.container-fluid#partners-page
  .header
    .width-container.text-center.row
      .col-lg-12
        h1.text-h1.text-navy.pixelated {{ $t("partners.headline") }}

    .width-container.text-center.row
      .col-lg-12
        a.btn.btn-primary.btn-lg(href="https://form.typeform.com/to/loZIh0I9" target="_blank") {{ $t('general.contact_us') }}

  .width-container.row.image-row.row-eq-height.container-coding
    .col-md-7.text-column
      h3.text-h3 {{ $t("partners.coding_title") }}
      p.text-navy {{ $t("partners.coding_blurb") }}
    .col-md-5.pixel-background.teal-pixel-background
      img.img-responsive.teal-border(src="/images/pages/partners/coding.jpg")

  .container-graphic-spacer
    .container
      .row
        .col-xs-12.graphic-spacer-column
          img.img-responsive-height.native-height(src="/images/pages/parents/graphic_03_speech.svg" alt="hero moving along a path" loading="lazy")

  .width-container.row.image-row.row-eq-height
    .col-md-5.pixel-background.yellow-pixel-background-2
      img.img-responsive.teal-border(src="/images/pages/partners/powered-by-hyper.png")
    .col-md-7.text-column
      h3.text-h3 {{ $t("partners.esports_title") }}
      p.text-navy(v-html="$t('partners.esports_blurb', i18nData)")

  .container-graphic-spacer
    .container
      .row
        .col-xs-12.graphic-spacer-column
          img.img-responsive-height(src="/images/pages/parents/graphic_06.svg" alt="hero moving along a path" loading="lazy")

  .width-container.row.image-row
    .col-sm-12
      h3.text-h3 {{ $t("partners.distribution_title") }}
      p.text-navy(v-html="$t('partners.distribution_blurb', i18nData)")


  .container-graphic-spacer
    .container
      .row
        .col-xs-12.graphic-spacer-column
          img.img-responsive-height(src="/images/pages/parents/graphic_05.svg" alt="hero moving along a path" loading="lazy")


  .width-container.row.image-row.row-eq-height
    .col-md-7.text-column
      h3.text-h3 {{ $t("partners.equity_social_title") }}
      p.text-navy
        span(v-html="$t('partners.equity_social_blurb', i18nData)")
        span(v-html="$t('partners.seek_relationships_blurb', i18nData)")
    .col-md-5.pixel-background.teal-pixel-background-2
      img.img-responsive.teal-border(src="/images/pages/partners/selina.jpg" alt="Seeds of Light")

  .container-graphic-spacer
    .container
      .row
        .col-xs-12.graphic-spacer-column
          img.img-responsive-height(src="/images/pages/parents/graphic_04.svg" alt="hero moving along a path" loading="lazy")

  .width-container.row.row-top-margin
    .col-lg-12
      p.text-navy
        span(v-html="$t('partners.latin_superstar_blurb', i18nData)")

  .row.width-container.image-row.quote-row
    .col-md-5.col-md-offset-1.col-sm-12.teacher-quote.col-sm-offset-0
      h3.text-h3.text-navy {{ $t("partners.eugenio_derbez_blurb") }}
    .col-md-5.col-sm-12
      img.img-responsive.teal-border(src="/images/pages/partners/Eugenio-Derbez.png" alt="Eugenio Derbez")


  .container-graphic-spacer
    .container
      .row
        .col-xs-12.graphic-spacer-column
          img.img-responsive-height.native-height(src="/images/pages/parents/graphic_08.svg" alt="hero moving along a path" loading="lazy")

  .width-container.row.image-row.row-eq-height
    .col-md-5.pixel-background.yellow-pixel-background
      img.img-responsive.teal-border(src="/images/pages/partners/corporate.png")
    .col-md-7.text-column
      h3.text-h3 {{ $t("partners.corporate_team_building_title") }}
      p.text-navy(v-html="$t('partners.corporate_team_building_blurb', i18nData)")


  .container-graphic-spacer
    .container
      .row
        .col-xs-12.graphic-spacer-column
          img.img-responsive-height.native-height(src="/images/pages/parents/graphic_07.svg" alt="hero moving along a path" loading="lazy")


  .width-container.row.row-top-margin.text-center
    .col-lg-10.col-sm-12.col-lg-offset-1
      p.text-navy {{ $t("partners.footer_blurb") }}

  .width-container.text-center.row.row-button
    .col-lg-12
      a.btn.btn-primary.btn-lg(href="https://form.typeform.com/to/loZIh0I9" target="_blank") {{ $t("partners.talk_with_us") }}

  .container-graphic-spacer
    .container
      .row
        .col-xs-12.graphic-spacer-column
          img.img-responsive-height(src="/images/pages/parents/graphic_09.png" alt="hero moving along a path based on code commands" loading="lazy")


  .width-container.text-center.row.brands-row
    .col-lg-12
      h3.text-h3 {{ $t("partners.our_partners") }}
    .col-lg-12.brands-column
      ul.brands
        li.item
          img(src="/images/pages/base/code-ninjas-logo-right.png")
        li.item
          img(src="/images/pages/partners/seeds-of-light.png")
        li.item
          img(src="/images/pages/league/hyperx-red-logo.png")
        li.item
          img.scale(src="/images/pages/partners/camden-education-fund-logo.png")
        li.item
          img(src="/images/pages/partners/idealab-logo.png")
        li.item
          img(src="/images/pages/partners/amdocs-logo.png")
        li.item
          img.scale(src="/images/pages/partners/brite-logo.png")
        li.item
          img(src="/images/pages/partners/galaxy-online-education-logo.png")



  .container-footer-mountains
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

$partners-body-font: 'Work Sans', 'Open Sans', sans-serif;

// style-flat overwrites
.text-h1 {
  font-family: $partners-body-font;
  font-weight: bold;
  font-size: 46px;
  line-height: 62px;
  letter-spacing: 2px;
  margin-bottom: -6px;
}

.text-h3 {
  font-family: $partners-body-font;
  font-weight: bold;
  font-size: 28px;
  line-height: 40px;
  letter-spacing: 0.52px;
}


.text-h5 {
  font-family: $partners-body-font;
  font-size: 32px;
  line-height: 38px;
  letter-spacing: 0.48px;
  font-weight: normal;
}

p, .text-p {
  font-family: $partners-body-font;
  font-size: 24px;
  font-weight: 300;
  line-height: 30px;
}

.btn-primary {
  background-color: $yellow-dark;
  border-radius: 9.5px;
  color: $pitch;
  font-weight: bold;
  font-size: 20px;
  line-height: 16px;
  min-width: 268px;
  min-height: 50px;
  padding: 16px 36px;
  &:hover {
    background-color: $yellow-light;
    transition: background-color .35s;
  }
}

#partners-page {
  background: linear-gradient(262.39deg, #D7EFF2 -1.56%, #FDFFFF 95.05%);
  .width-container {
    max-width: 1170px;
    float: unset;
    margin: 0 auto;
  }

  .header {
    min-height: 628px;
    background-image: url(/images/pages/parents/ten_testimonial.png), url(/images/pages/parents/image_cloud_3.svg), url(/images/pages/parents/image_cloud_4.svg), url(/images/pages/parents/image_cloud_3.svg), url(/images/pages/parents/image_cloud_1.svg);
    background-repeat: no-repeat, no-repeat, no-repeat, no-repeat, no-repeat;
    background-position: bottom left 5%, top 50px left 30px, top 35px right 280px, top 360px right 300px, bottom 52px right 475px;
    background-size: 500px, 260px, 90px, 260px, 250px;
    .row {
      padding: 30px 0;
      .pixelated {
        font-family: "lores12ot-bold", "VT323";
      }
    }
  }



  .row-top-margin {
    margin-top: 30px;
  }


  .img-responsive-height {
    display: block;
    max-width: 100%;
    max-height: 200px;
    &.native-height {
      max-height: none;
    }
  }

  .container-graphic-spacer {
    pointer-events: none;
    min-height: 200px;
    .graphic-spacer-column {
      display: flex;
      justify-content: center;
    }
  }


  & > .row {
    padding: 5px 0 0;
    &.image-row {
      padding-bottom: 35px;

      @media (max-width: $screen-md-min) {
        padding: 40px 0;
      }
    }
    &.brands-row,
    &.quote-row {
      padding: 40px 0;
    }

    &.row-button {
      padding: 30px 0;
    }

    &.container-coding {
      position: relative;
      padding-top: 100px;
      &::before{
        content: "";
        background-image: url(/images/pages/parents/graphic_01_anya.svg);
        background-repeat: no-repeat;
        position: absolute;
        background-size: 99%;
        background-position: center;
        width: 151px;
        height: 227px;
        top: -50px;
      }
    }

    .brands-column {
      border: 4px dashed $teal;
      border-radius: 20px;
      margin-top: 20px;
    }
  }

  .row-eq-height {
    display: flex;
    flex-wrap: wrap;
  }

  .img-responsive {
    width: 100%;
  }

  .text-column {
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: stretch;
  }

  .pixel-background {
    padding: 80px;
    background-size: contain;
    background-repeat: no-repeat;
    background-position: center center;
    &.teal-pixel-background {
      background-image: url(/images/pages/partners/pixel-bg-light-teal.svg);
    }
    &.teal-pixel-background-2 {
      background-image: url(/images/pages/partners/pixel-bg-light-teal-2.svg);
    }
    &.yellow-pixel-background {
      background-image: url(/images/pages/partners/pixel-bg-yellow.svg);
      padding-bottom: 25px;
    }
    &.yellow-pixel-background-2 {
      background-image: url(/images/pages/partners/pixel-bg-yellow-2.svg);
    }
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

.teal-border {
  border: 10px solid $teal;
  box-sizing: border-box;
  border-radius: 20px;
}



.container-footer-mountains {
  width: 100%;
  background: url(/images/pages/parents/parents_footer_mountain.svg);
  background-repeat: no-repeat;
  background-position: top;
  background-size: cover;
  height: 170px;
  margin-bottom: -50px;
}

.brands {
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  margin: 0;
  padding: 0;
  .item {
    display: flex;
    flex: 0 0 33.33%;
    justify-content: center;
    align-items: center;
    height: 100%;
    mix-blend-mode: multiply;
    img {
      place-self: center;
      object-fit: contain;
      display: block;
      max-width: 100%;
      width: 260px;
      height: 150px;
      &.scale {
        transform: scale(0.7);
      }
    }
  }
}



</style>
