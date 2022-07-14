<template lang="pug">
  section#ozaria-stats(:class="{ 'framed': framed }")
    .row.graph-boxes
      .col.col-md-6
        .graph-box.graph-box-mcintosh
          .graph-box-inner
            .graph-logo
              img(src="/images/pages/efficacy/mcintosh-logo.png" :alt="`${$t('efficacy.mcintosh_middle_school')}`").box-logo
            .graph-content
              .big-percent +47%
              p {{ $t("efficacy.graph1_description") }}
              img(src="/images/pages/efficacy/mcintosh-graph.png" )

      .col.col-md-6
        .graph-box.graph-box-mrms
          .graph-box-inner
            .graph-logo
              img(src="/images/pages/efficacy/mrms-logo.png" :alt="`${$t('efficacy.mountain_ridge_middle_school')}`").box-logo
            .graph-content
              .big-percent 90%
              p {{ $t("efficacy.graph2_description") }}
              img(src="/images/pages/efficacy/mrms-graph.png")
</template>

<script>
export default {
  name: 'OzariaStats',
  props: {
    framed: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
}
</script>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "app/styles/mixins";
@import "app/styles/style-flat-variables";
@import "ozaria/site/styles/common/common.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";



#ozaria-stats {
  display: flex;
  flex-direction: column;
  align-items: center;
  position: relative;
  overflow-x: hidden;
  margin-top: 90px;

  $teal-light-1: #1FBAB4;
  $teal-light-2: #6AE8E3;
  $teal-dark: #0E4C60;

  $body-fonts: 'Space Mono', 'Work Sans', "Open Sans", serif;
  $body-fonts2: 'Work Sans', "Open Sans", serif;


  .graph-boxes {
    border-image: linear-gradient(
            to right,
            #3272DB,
            #33ECC9
    ) 1;
    border-width: 10px;
    border-style: solid;
    border-top-width:0;
    max-width: 1395px;
    margin: 150px auto 0 auto;
    @media (max-width: $screen-lg) {
      margin: 150px 50px 0 50px;
    }
    @media (max-width: $screen-md-min) {
      border: none;
    }
  }

  .graph-box {

    @media (max-width: $screen-md-min) {
      border-image: linear-gradient(
              to right,
              #3272DB,
              #33ECC9
      ) 1;
      border-width: 10px;
      border-style: solid;
      border-top-width:0;
      margin-bottom: 150px;
    }

    .graph-logo {
      display: flex;
      margin: 0 -15px;

      @media (max-width: $screen-md-min) {
        margin: 0 -10px;
      }

      &::before, &::after {
        content: "";
        height: 10px;
        background: black;
        display: block;
        width: 100%;
      }
    }

    .graph-content {
      display: flex;
      align-items: center;
      justify-content: center;
      flex-direction: column;
      margin: -50px 40px 80px 40px;

      img {
        max-width: 100%;
      }

      .big-percent {
        font-family: $body-fonts;
        font-style: normal;
        font-weight: 700;
        font-size: 150px;
        line-height: 130px;
        display: inline;

        background: linear-gradient(85.53deg, #3272DB 5.02%, #3272DB 26.56%, #33ECC9 91.18%, #33ECC9 112.72%);
        -webkit-background-clip: text;
        -webkit-text-fill-color: transparent;
        background-clip: text;
        text-fill-color: transparent;
      }

      p {
        font-family: $body-fonts2;
        font-style: normal;
        font-weight: 400;
        font-size: 24px;
        line-height: 125%;
        letter-spacing: 0.444444px;
        color: #000000;
        margin: 50px auto 35px;
      }
    }

    &.graph-box-mcintosh .graph-logo {
      &::before {
        background: linear-gradient(to right, #3272DB, #3272DB);
        margin-right: 5px;
      }
      &::after {
        background: linear-gradient(to right, #3283D8, #32A2D4);
        margin-left: 5px;
      }
      img{
        transform: translateY(-106px);
      }
    }

    &.graph-box-mrms .graph-logo {
      &::before {
        background: linear-gradient(to right, #32A2D4, #33C7CF);
        margin-right: -15px;
      }
      &::after {
        background: linear-gradient(to right, #33DACC, #33ECC9);
        margin-left: -30px;
      }
      img {
        transform: translateY(-100px);
      }
    }

    &.graph-box .graph-logo {
      @media (max-width: $screen-md-min) {
        &::before {
          background: linear-gradient(to right, #3272DB, #32A2D4);
        }
        &::after {
          background: linear-gradient(to right, #32A2D4, #33ECC9);
        }
      }
    }

  }

  &.framed .graph-boxes {
    @media (min-width: $screen-md-min) {
      background: white;
    }
    .graph-box {
      background: white;
      &.graph-box-mcintosh .graph-logo {
        img{
          border-image-source: linear-gradient(to right, #3272DB, #3283D8);
          @media (max-width: $screen-md-min) {
            border: 10px solid #32A2D4;
          }
        }
      }

      &.graph-box-mrms .graph-logo {
        img {
          border-image-source: linear-gradient(to right, #33C7CF, #33DACC);
          @media (max-width: $screen-md-min) {
            border: 10px solid #32A2D4;
          }
        }
      }
      .graph-logo {
        img {
          border-style: solid;
          background: white;
          border-image-slice: 1;
          border-width: 10px;
        }
        &::before, &::after {
          margin: 0;
        }
      }
    }
  }

  .row.flex-row {
    display: flex;
    flex-direction: row;
    align-items: center;
  }

  // Most sections have a max width and are centered.
  & > section {
    max-width: 1728px;
    width: 100%;
    position: relative;
    z-index: 1;
  }

  // This lets us have full width sections easily.
  section.full-width {
    max-width: unset;
    padding: 0;
    margin: 0;
  }


}
</style>
