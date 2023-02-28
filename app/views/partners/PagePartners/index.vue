<template lang="pug">
  #partners-page
    .container-fluid
      .header
        .container-fluid.header-part-top
          .width-container.text-center
            .row
              .col-lg-12
                img(src="/images/pages/base/logo.png")
                h1.text-h1 {{ $t('partners.for')}}
                h1.text-h1 {{ $t('partners.business_partners')}}
                h2.text-h2 {{ $t('partners.headline') }}
            .row
              .col-lg-12
                a.btn.btn-primary.btn-lg(href="https://form.typeform.com/to/loZIh0I9" target="_blank") {{ $t('general.contact_us') }}
        .container-fluid.header-part-bottom
          .width-container.text-center
            .row
              .col-lg-12
                p Our Partnership Structures
          .scroll-arrow
            .left-arrow
            .right-arrow

      .width-container.row.image-row.row-eq-height.row-coding
        .col-md-4.col-sm-12.midnight-green-background
          img.img-responsive(src="/images/pages/partners/coding-image.png")
        .col-md-8.col-sm-12.text-column
          h3.text-h3 {{ $t('partners.coding_title') }}
          p.text-navy {{ $t('partners.coding_blurb') }}

      .width-container.row.image-row.row-eq-height.row-reverse-order.row-ai-league
        .col-md-4.col-sm-12.midnight-green-background
          img.img-responsive(src="/images/pages/partners/esports-powered-by-hyper.png")
        .col-md-8.col-sm-12.text-column
          h3.text-h3 {{ $t('partners.esports_title') }}
          p.text-navy(v-html="$t('partners.esports_blurb', i18nData)")

      .width-container.row.image-row.row-eq-height.row-international
        .col-md-4.col-sm-12.midnight-green-background
          img.img-responsive(src="/images/pages/partners/international-distribution.png")
        .col-md-8.col-sm-12.text-column
          h3.text-h3 {{ $t('partners.distribution_title') }}
          p.text-navy(v-html="$t('partners.distribution_blurb', i18nData)")

      .width-container.row.image-row.row-eq-height.row-reverse-order.row-tech-equity
        .col-md-4.col-sm-12.midnight-green-background
          img.img-responsive(src="/images/pages/partners/tech-equity.png" alt="Seeds of Light")
        .col-md-8.col-sm-12.text-column
          h3.text-h3 {{ $t('partners.equity_social_title') }}
          p.text-navy
            span(v-html="$t('partners.equity_social_blurb', i18nData)")
            span(v-html="$t('partners.seek_relationships_blurb', i18nData)")

    .container-fluid.container-fluid-gradient
      .width-container.row.heading-text
        .col-lg-12
          p
            span(v-html="$t('partners.latin_superstar_blurb', i18nData)")

      .row.width-container.image-row.white-row
        .col-md-6.col-sm-12.teacher-quote.col-sm-offset-0
          img(src="/images/pages/home/teal_quote.png")
          h3.text-h3 {{ $t('partners.eugenio_derbez_blurb') }}
          p.signature Eugenio Derbez
        .col-md-6.col-sm-12
          img.img-responsive.img-eugenio(src="/images/pages/partners/Eugenio-Derbez.png" alt="Eugenio Derbez")

    .container-fluid

      .width-container.row.image-row.row-eq-height.row-corporate
        .col-md-4.col-sm-12.midnight-green-background
          img.img-responsive(src="/images/pages/partners/corporate-user.png")
          img.img-responsive(src="/images/pages/partners/corporate-user.png")
        .col-md-8.col-sm-12.text-column
          h3.text-h3 {{ $t('partners.corporate_team_building_title') }}
          p.text-navy(v-html="$t('partners.corporate_team_building_blurb', i18nData)")

      .width-container.row.row-top-margin.text-center
        .col-lg-12.col-sm-12
          p.text-footer-blurb {{ $t('partners.footer_blurb') }}

      .width-container.text-center.row.row-button
        .col-lg-12
          a.btn.btn-primary.btn-lg.btn-talk(href="https://form.typeform.com/to/loZIh0I9" target="_blank") {{ $t('partners.talk_with_us') }}

    .container-fluid.container-fluid-gradient
      .width-container.text-center.row.brands-row
        .col-lg-12
          h3.text-h3 {{ $t('partners.our_partners') }}
      .width-container.text-center.row.brands-row.white-row
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

</template>

<script>
export default Vue.extend({
  data () {
    return {
      i18nData: {
        hyperx: `<a href='/league' target='_blank'>${$.i18n.t('partners.hyperx')}</a>`,
        respawn: `<a href='/league/#winners' target='_blank'>${$.i18n.t('partners.respawn')}</a>`,
        forty_languages: `<a href='/contribute/diplomat' target='_blank'>${$.i18n.t('partners.forty_languages')}</a>`,
        reach_latinx: `<a href='https://www.yahoo.com/now/mexican-superstar-eugenio-derbez-partners-200100110.html' target='_blank'>${$.i18n.t('partners.reach_latinx')}</a>`,
        seeds_of_light: `<a href='https://www.accesswire.com/702186/Seeds-of-Light-and-CodeCombat-Expand-Partnership-with-Launch-of-Glow-Academies-for-Middle-School-Students' target='_blank'>${$.i18n.t('partners.seeds_of_light')}</a>`,
        eugenio_derbez: '<a href=\'https://www.businesswire.com/news/home/20210316006024/en/Mexican-Superstar-Eugenio-Derbez-Partners-with-CodeCombat-to-Get-the-Latinx-Community-Coding\' target=\'_blank\'>Eugenio Derbez</a>',
        see_how: `<a href='/images/pages/partners/pdf/Flyer_-_Coding_Esports_for_Employers_with_Amdocs_Case_Study.pdf' target='_blank'>${$.i18n.t('partners.see_how')}</a>`,
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

$partners-body-font: 'Arvo';

.text-h1 {
  font-family: 'Arvo';
  font-style: normal;
  font-weight: 700;
  font-size: 60px;
  line-height: 103%;
  text-align: center;
  letter-spacing: 1.96px;
  color: #FCBB00;
  word-break: break-word;
}

.text-h2 {
  font-family: $partners-body-font;
  font-style: normal;
  font-weight: 700;
  font-size: 33px;
  line-height: 188%;
  text-align: center;
  letter-spacing: 1.96px;
  color: #FFFFFF;
}

.text-h3 {
  font-family: $partners-body-font;
  font-style: normal;
  font-weight: 700;
  font-size: 28px;
  line-height: 38px;
  /* identical to box height, or 136% */
  color: #0E4C60;
}


.text-h5 {
  font-family: $partners-body-font;
  font-size: 32px;
  line-height: 38px;
  letter-spacing: 0.48px;
  font-weight: normal;
}

p, .text-p {
  font-family: 'Open Sans';
  font-style: normal;
  font-weight: 400;
  font-size: 24px;
  line-height: 30px;
  color: #0E4C60;
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
  overflow: hidden;

  .width-container {
    max-width: 1170px;
    float: unset;
    margin: 0 auto;
  }

  .header {
    .header-part-top {
      background-size: cover;
      background-position: center center;
      background-image: url(/images/pages/partners/top-background.png);
      .text-h2 {
        margin-top: 21px;
      }
    }

    .header-part-bottom {
      background: linear-gradient(118.13deg, #0E4C60 0%, #20572B 100%);
      .scroll-arrow {
        height: 32px;
        width: 100%;
        display: flex;
        .left-arrow {
          border-bottom: 32px solid white;
          border-right: 50px solid transparent;
          height: 0;
          width: 50%;
        }
        .right-arrow {
          border-bottom: 32px solid white;
          border-left: 50px solid transparent;
          height: 0;
          width: 50%;
        }
      }

      p {
        font-family: 'Arvo';
        font-style: normal;
        font-weight: 700;
        font-size: 33px;
        line-height: 62px;
        text-align: center;
        letter-spacing: 1.96px;
        color: #FCBB00;
      }
    }

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

  .container-fluid-gradient {
    background: linear-gradient(90deg, #0E4C60 19.5%, #20572B 110.94%);
    border: 1px solid #000000;
    box-shadow: 0px 4px 4px rgba(0, 0, 0, 0.25);
    margin-top: 115px;

    .heading-text {
      padding-top: 50px;
      font-weight: 700;
      font-size: 24px;
      line-height: 125%;
      text-align: center;

      p, ::v-deep a {
        font-family: 'Arvo';
        font-style: normal;
        font-weight: 700;
        color: #FCBB00;
      }
    }

    .white-row {
      background: #FFFFFF;
      border-radius: 20px;
      margin: 16px auto 76px;
      padding: 20px;
      width: calc(100% - 30px);

      @media (min-width: $screen-md-min) {
        display: flex;
        align-items: center;
      }
    }


  }

  .image-row {
    margin: 50px auto 80px;

    .midnight-green-background {
      background: #0E4C60;
      min-height: 300px;
      @media (max-width: $screen-md-min) {
        min-height: 50px;
        width: 100%;
        margin-bottom: 15px;
      }

      > img {
        position: absolute;
        @media (max-width: $screen-md-min) {
          max-height: 100%;
          bottom: 0 !important;
          top: 0 !important;
        }
      }

      &:before {
        content: '';
        display: block;
        position: absolute;
        left: -100vw;
        right: 100%;
        bottom: 0;
        top: 0;
        background: #0E4C60;
      }

      & + .text-column {
        $paragraph-horizontal-margin: min(75px, 7vw);

        h3 {
          margin: 0 $paragraph-horizontal-margin 10px;
        }

        p {
          margin: 10px $paragraph-horizontal-margin 0
        }
      }
    }

    &.row-reverse-order {
      display: flex;

      @media (min-width: $screen-md-min) {
        > :first-child {
          order: 1;
        }
        > :last-child {
          order: 0;
        }
      }

      .midnight-green-background {
        &:before {
          right: -100vw;
          left: 100%
        }
      }
    }
  }

  .row {
    padding: 5px 0 0;

    &.image-row {
      padding-bottom: 35px;

      @media (max-width: $screen-md-min) {
        padding: 40px 0;
      }
    }

    &.brands-row,
    &.white-row {
      padding: 40px 0;
    }

    &.brands-row {
      .text-h3 {
        font-family: 'Arvo';
        font-style: normal;
        font-weight: 700;
        font-size: 24px;
        line-height: 30px;
        text-align: center;
        color: #FFFFFF;
        margin-top: 16px;
      }
    }

    &.row-button {
      padding: 30px 0;
      margin-bottom: 115px;
    }
  }

  .row-eq-height {
    display: flex;
    flex-wrap: wrap;

    &.row-coding {
      img {
        bottom: -50px;
        right: 50px;
      }
    }

    &.row-coding {
      .midnight-green-background {
        background: #FCBB00;

        &:before {
          background: #FCBB00
        }
      }
    }

    &.row-ai-league {
      .midnight-green-background {
        background: rgb(12, 16, 22);

        &:before {
          background: rgb(12, 16, 22);
        }
      }

      img {
        bottom: 20px;
        left: 50px;
      }
    }

    &.row-corporate {
      .midnight-green-background {
        background: #FCBB00;

        &:before {
          background: #FCBB00
        }
      }

      img {
        bottom: -50px;
        left: -30px;
        @media (max-width: $screen-md-min) {
          left: 50px;
        }

        + img {
          left: 100px;
          @media (max-width: $screen-md-min) {
            left: 70px
          }
        }
      }
    }

    &.row-international {
      .midnight-green-background {
        background: rgba(32, 87, 43, 1);

        &:before {
          background: rgba(32, 87, 43, 1);
        }
      }

      img {
        bottom: 0;
        right: 50px
      }
    }


    &.row-tech-equity {
      img {
        bottom: -47px;
        left: 50px
      }
    }
  }

  .text-column {
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: stretch;
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
    font-family: 'Arvo';
    font-style: normal;
    font-weight: 400;
    font-size: 24px;
    line-height: 32px;
    text-align: center;
    letter-spacing: 0.48px;
    color: #0E4C60;
    margin: 0 min(6vw, 80px);
  }

  p.signature {
    font-family: 'Open Sans';
    font-style: normal;
    font-weight: 700;
    font-size: 16px;
    line-height: 30px;
    text-align: center;
    letter-spacing: 0.32px;
    color: #0E4C60;
  }
}

img.img-eugenio {
  border-radius: 20px;
  margin: 0 auto;
  width: 100%;
}


.text-footer-blurb {
  font-family: 'Arvo';
  font-style: normal;
  font-weight: 400;
  font-size: 24px;
  line-height: 125%;
  text-align: center;
  color: #1FBAB4;
  margin: 67px auto;
}

.btn-talk {
  background-color: #1FBAB4;
  text-transform: uppercase;
  transition: background-color .35s;

  &:hover {
    background-color: #2dcec8;
  }
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
    flex: 0 0 25%;
    justify-content: center;
    align-items: center;
    height: 100%;
    mix-blend-mode: multiply;

    @media (max-width: $screen-md-min) {
      flex: 0 0 33.3%
    }

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
