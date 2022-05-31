<template lang="pug">
.container-fluid#partners-page
  .width-container.text-center.row
    .col-lg-12
      h1.text-navy Join us in our mission to make coding engaging and accessible to all
  .width-container.text-center.row
    .col-lg-12
      a.btn.btn-primary.btn-lg(href="/teachers/quote") {{ $t('general.contact_us') }}
  .width-container.text-center.row
    .col-lg-12
      h5.text-teal At CodeCombat we’ve developed comprehensive tools that make learning to code fun and teaching programming easy. Our turnkey solutions can be leveraged in many executions.

  .width-container.row
    .col-md-8
      p.text-navy
        strong Coding & STEAM Education Businesses:
        | Valued partners like Code Ninjas and IDEA Lab Kids use our game to teach real Python and JavaScript coding to students in their franchise locations. We offer an easy to use program, implementation resources and training options to ensure an amazing student experience.
    .col-md-4
      img.img-responsive(src="/images/pages/partners/coding.png")

  .width-container.row
    .col-md-4
      img.img-responsive(src="/images/pages/partners/esports.jpg")
    .col-md-8
      p.text-navy
        strong Educational Esports Sponsors:
        | We are reinventing what an esport can be while engaging thousands of students to learn to code. Endemic esports mainstays like HyperX and RESPAWN have supported the CodeCombat AI League from its inaugural season, building compelling promotional programs around this unique esport.

  .width-container.row
    .col-lg-12
      p.text-navy
        strong International Distribution:
        | Our programs have served students in over 190 countries and our content is translated into over 40 languages. While the US and China are markets where we sell directly, we work closely with local Saas and EdTech distribution partners around the world to expand our reach.

  .width-container.row
    .col-lg-12
      p.text-navy
        strong Tech Equity & Social Impact:
        | Not every partnership is built on the bottom line. As a mission-based organization we seek ways to give back as well. We work closely with foundations and other philanthropy partners to expand access to high-quality coding education.  Latin superstar Eugenio Derbez has helped us reach the Latinx community with a partnership to engage students in this often underserved and underrepresented group. We also seek relationships with nonprofits and community-based organizations working with groups underrepresented in computer science and technology careers.

  .row.width-container
    .col-md-4.col-md-offset-1.col-sm-12.teacher-quote
      img(src="/images/pages/home/teal_quote.png")
      h3.text-navy "It is important to me to see Latino boys and girls represented in this space," said Eugenio Derbez, "Coding is the language of the future and if we want to be a part of that future then we need to get our kids coding."
    .col-md-6.col-sm-12
      img.img-responsive(src="/images/pages/partners/Eugenio-Derbez.png" alt="Eugenio Derbez")


  .width-container.row
    .col-lg-12
      p.text-navy These are just a few of the partnership structures we have succe ssfully supported. If you would like to initiate a discussion with our business development team on any of these models or have a different partnership opportunity, please reach out today.

  .width-container.text-center.row
    .col-lg-12
      a.btn.btn-primary.btn-lg(href="/teachers/quote") Talk with Us

</template>

<script>
export default Vue.extend({
  components: {
  }
})
</script>

<style lang='scss' scoped>
@import "app/styles/bootstrap/variables";
@import "app/styles/mixins";
@import "app/styles/style-flat-variables";

.row-dark {
    background: linear-gradient(118.13deg, #0E4C60 0%, #20572B 100%);
}

// style-flat overwrites
h1, .text-h1 {
  font-family: $headline-font;
  font-weight: bold;
  font-size: 46px;
  line-height: 62px;
  letter-spacing: 2px;
  margin-bottom: -6px;
}

h2, .text-h2 {
  font-family: $headline-font;
  font-weight: bold;
  font-size: 33px;
  line-height: 62px;
  letter-spacing: 2.58px;
}

h3, .text-h3 {
  font-family: $headline-font;
  font-weight: bold;
  font-size: 24px;
  line-height: 32px;
  letter-spacing: 0.52px;
}

h4, .text-h4 {
  font-family: $body-font;
  font-weight: bold;
  font-size: 24px;
  line-height: 40px;
  letter-spacing: 0.56px;
}

h5, .text-h5 {
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

.btn-primary-alt, .btn-navy-alt, .btn-teal-alt {
  background-color: transparent;
  border: 2px solid $teal;
  color: $teal;
  border-radius: 4px;
  text-shadow: unset;
  text-transform: uppercase;
  font-weight: bold;
  letter-spacing: 0.71px;
  line-height: 24px;
  width: 247px;
  &:hover {
    background-color: $teal;
    box-shadow: unset;
    color: $gray;
    transition: color .35s, background-color .35s, box-shadow .35s;
  }
}

#jumbotron-container-fluid {
  background-image: url(/images/pages/impact/BannerImage.png);
  background-size: cover;
  background-repeat: no-repeat;
  background-position: center center;
  height: 580px;
  width: 100%;
  margin: auto;

  display: flex;
  justify-content: center;
  flex-direction: column;
  text-align: center;

  & > h1 {
    font-size: 45px;
    letter-spacing: 1.96px;
    line-height: 62px;
    max-width: 801px;
    margin: 100px auto 25px;
  }
}

#partners-page {
  .width-container {
    max-width: 1170px;
    float: unset;
    margin: 0 auto;
  }

  & > .row {
    padding-top: 62px;
  }

  overflow: hidden;
}

#featured-partner-story {
  text-align: center;
  min-height: 193px;
  &.row {
    padding-top: 52px;
  }

  display: flex;
  flex-direction: column;

  & > h2 {
    flex-grow: 1;
  }

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
}

#bobby-duke {
  h1 {
    margin-bottom: 12px;
  }
  h2 {
    letter-spacing: 0.66px;
    line-height: 30px;
    font-family: $body-font;
  }

  img {
    max-width: 165px;
  }
}

#body-text-content > p {
  margin-bottom: 24px;
  margin-left: 12px;
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

.quote-flex-container {
  display: flex;
  & > div {
    display: flex;
    flex-direction: column;
  }

  & > div:first-child {
    margin-right: 15px;
  }
}

.read-full-story {
  text-align: center;

  & > a.btn-primary {
    background-color: $gold;
    color: $gray;
    font-size: 18px;
    letter-spacing: 0.71px;

    &:hover {
      background-color: #FDD147;
    }
  }
}

#more-partner-stories {
  margin-top: 62px;
  h1 {
    text-align: center;
    padding-bottom: 45px;
  }

  #partner-story-tiles {
    padding-bottom: 62px;
    display: flex;
    @media (max-width: $screen-md-min) {
      flex-direction: column;
    }
    .partner-story-tile {
      background-color: white;

      display: flex;
      flex-direction: column;
      justify-content: space-between;
      align-items: center;

      margin: 0 14px;
      padding: 30px;
      border-radius: 6px;

      img.tile-header-img {
        margin-bottom: 22px;
        padding: 0 14px;
      }

      .inner-tile-school {
        &>div:first-child {
          padding-right: 0;
        }

        p {
          font-size: 14px;
          letter-spacing: 0.58px;
          line-height: 19px;
          color: $gray;
          margin-bottom: 26px;
        }
      }
    }

    h4 {
      font-size: 18px;
      line-height: 22px;
      letter-spacing: 0.75px;
    }
  }
}

#teachers-love-codecombat {
  padding-bottom: 62px;

  h1.text-teal {
    margin-bottom: 45px;
  }

  h4 {
    line-height: 30px;
    letter-spacing: 0.48px;
    margin: 0 auto 45px;
    max-width: 320px;
  }

  img {
    margin-bottom: 20px;
  }

  .mcrel-blurb {
    font-size: 18px;
    letter-spacing: 0.75px;
    line-height: 26px;
    font-style: italic;
    margin-bottom: 0;
  }

  .btn.btn-primary.btn-lg {
    width: unset;
    margin-bottom: 45px
  }

}

#teacher-student-spotlight {
  & > div:nth-child(1) {
    display: flex;
    flex-direction: column;
  }

  padding-bottom: 62px;

  h2 {
    margin-bottom: 45px;
  }
  #teacher-student-tiles {
    display: flex;

    @media (max-width: $screen-md-min) {
      flex-direction: column;
    }

    .teacher-student-tile {
      margin: 15px;
      background-color: white;
      border-radius: 6px;
      padding: 9px 45px 10px;

      display: flex;
      flex-direction: column;
      justify-content: space-between;

    }
  }

  .teacher-description {
    display: flex;
    align-items: center;

    min-height: 133px;
    margin-bottom: 20px;
    border-bottom: 2.59px $teal solid;
    
  }

  h3 {
    font-size: 20px;
    line-height: 30px;
    letter-spacing: 0.4px;
  }

  h5 {
    font-size: 18px;
    line-height: 24px;
    letter-spacing: 0.36px;
  }

  .teacher-thumbnail {
    padding: 0;
  }

  .teacher-bio {
    padding: 0 0 0 10px;
  }

  .continue-reading-link {
    font-size: 14px;
    line-height: 19px;
    letter-spacing: 0.58px;
  }
}

#global {
  &.row {
    padding-top: 0;
    padding-bottom: 12px;
  }
  .row {
    padding: 62px 15px 0;
  }
  img {
    height: 82px;
    }
  h2.text-teal {
    margin-bottom: 30px;
  }
  h2.text-navy {
    margin-top: 14px;
    margin-bottom: -14px;
  }
  h5 {
    font-weight: normal;
  }
  .col-xs-6 {
    padding: 10px 15px;
  }
}

</style>
