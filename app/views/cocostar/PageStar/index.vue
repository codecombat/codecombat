<template lang="pug">
.container-fluid#star-page

  .row#jumbotron-container-fluid
    img.header-img(:src="baseURI + 'header.png'")
    h5.text-white.col-md-8
      | 为鼓励广大青少年学习计算机编程，扣哒世界每年同权威学术机构和技术机构开展面向青少年的人工智能创意和算法公益竞赛。本栏目收集从2019年开始历届比赛的扣哒之星获奖者，作为榜样的力量激励更多的青少年投入到代码编程、算法设计和人工智能学习中来，自强不息、精益求精、追求卓越！

  .part(v-for="event in events")
    .bobby-duke.row.width-container(v-if="event.ctype=='title'")
      h1.text-teal.title {{ event.title }}
      .row.title-row
        .title-part(v-for="part in event.data",  :class="{'margin-left': part[0].indexOf('margin-left') != -1, 'margin-left-2': part[0].indexOf('margin-2') != -1}")
          h1.value.text-forest(v-html="part[0]")
          h4.title.text-navy {{ part[1] }}
    .width-container(:class="{'row-dark': event.bg == 'dark', 'row': event.bg == 'light'}")
      .rank-row(v-if="event.ctype=='rank'")
        .champ-panel(v-for="(cp, i) in event.rank")
          img.rank-img(:src="baseURI + rankImgs[i]")
          div.flex-center
            h2.text-teal {{cp[0]}}
            | {{cp[1]}}
      .group-row.width-container.flex-center(v-if="event.ctype=='group'")
        h1.title.text-gradient {{event.title}}
        .group-panel
          .name.text-navy(v-for="m in event.members") {{m}}

      .group-desc-row.flex-center(v-if="event.ctype=='group-desc'")
        h1.title.text-gradient {{event.title}}
        .group-panel
          .name.text-navy(v-for="m in event.members")
            .username {{m[0]}}
            .desc {{m[1]}}

      .champion-group-row.flex-center(v-if="event.ctype=='champion-group'")
        h1.title.text-gradient {{event.title}}
        .champ-panel-row.flex-row
          .champ-panel(v-for="(cp, i) in event.rank")
            img.rank-img(:src="baseURI + champImgs[i]")
            div.flex-center
              h2.text-teal {{cp[0]}}
              | {{cp[1]}}
        .group-panel
          h2.text-teal {{event.rewards.title}}
          .names
            .name.text-navy(v-for="m in event.rewards.members") {{m}}

      .champion-row.flex-center(v-if="event.ctype=='champion'")
        h1.title.text-gradient {{event.title}}
        .champ-panel-row.flex-row
          .champ-panel(v-for="(cp, i) in event.rank")
            img.rank-img(:src="baseURI + champImgs[i]")
            div.flex-center(v-for="team in cp")
              h4.text-teal {{team.t}}
              div(v-for="m in team.n") {{m}}

      .row-dark(v-if="event.ctype == 'split-bar'", style="height: 60px; color:transparent;")
      .scroll-arrow(v-if="event.bg=='dark'")
        .left-arrow
        .right-arrow
</template>

<script>
const events = require('./constants')
export default Vue.extend({
  name: 'CoCoStar',
  components: {
  },
  computed: {
    baseURI () {
      return 'https://assets.koudashijie.com/images/cocostar/'
    },
    rankImgs () {
      return ['champ1.png', 'champ2.png', 'champ3.png']
    },
    champImgs () {
      return ['champgold.png', 'champsli.png', 'champcop.png']
    },
    events () {
      return events
    },
  },
  mounted () {
    window.localStorage.setItem('lastViewedCocoStarPage', Date.now())
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

.part .camp{
  margin-top: 20px;
  width: 900px;
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
  font-size: 20px;
  line-height: 28px;
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
  align-items: center;
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
  .header-img {
    width: 25em;
    margin-bottom: 1.8em;
  }
}

#star-page {
  .width-container {
    max-width: 1170px;
    float: unset;
    margin: 0 auto;
    display: flex;
    flex-direction: column;
    align-items: center;
  }

  .champion-group-row {
    padding-top: 40px;
    .champ-panel{
      text-align: center;
      border: #1C5439 1px solid ;
      box-shadow: #68D321 0 0 5px 2px;
    }
    .group-panel{
      max-width: 1070px;
      margin-top: 10px;
      flex-direction: column;
      align-items:center;

      .names {
        margin-top: 20px;
        display: flex;
        flex-wrap: wrap;
      }
    }
  }
  .champion-row {
    padding-top: 40px;
    .champ-panel{
      text-align: center;
      border: #1C5439 1px solid ;
      box-shadow: #68D321 0 0 5px 2px;
    }
  }
  .row-dark .champion-group-row .champ-panel{
    border: none;
    box-shadow: none;
  }
  .row-dark .champion-row .champ-panel{
    border: none;
    box-shadow: none;
  }
  .title.text-gradient {
    color: #FFAE00;
    background: -webkit-linear-gradient(-80deg, #FFE600, #FFAE00);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
  }
  .title-row {
    display: flex;
    flex-wrap: wrap;
    justify-content: space-around;
    align-items: center;
    width: 1000px;
  }
  .rank-row {
    display: flex;
    align-items: center;
    justify-content: center;

  }
  .group-row{
    padding-top: 60px;
  }

  .group-desc-row {
    padding-top: 40px;
    .group-panel{
      max-width: 1070px;
      justify-content: space-between;
      .name{
        width: 45%;
        display: flex;
        .username{
          width: 4em;
        }
      }
    }
  }
  .group-panel{
    max-width: 1070px;
    width: 80vw;
    margin-top: 60px;
    margin-bottom: 50px;
    border-radius: 5px;
    border: #1C5439 1px solid ;
    padding: 50px 35px;
    box-shadow: #68D321 0 0 5px 2px;
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    font-size: 22px;

    .name{
      margin-left: 4px;
      margin-right: 4px;
    }
  }
  .row-dark .group-panel {
    max-width: 1070px;
    background-color: white;
    border: none;
    box-shadow: none;
  }
  .flex-row{
    display: flex;
  }
  .flex-center {
    display: flex;
    flex-direction: column;
    align-items: center;
  }
  .champ-panel {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: space-around;
    background-color: white;
    margin-left: 20px;
    margin-right: 20px;
    margin-top: 100px;
    margin-bottom: 80px;
    border-radius: 5px;
    height: 360px;
    width: 300px;
    .rank-img{
      width: 160px;
    }
  }

  .title-part {
    min-width: 25%;
    display: flex;

    flex-direction: column;
    align-items: center;

    .value{
      border-left: 0;
      border-right: 0;
      font-size: 30px;
      font-family: bold;
      position: relative;

    }
    &.margin-left{
      margin-left: 10%;
    }
    &.margin-left-2{
      margin-left: 8%;
    }
    .value::after{
      content: ' ';
      position: absolute;
      left: 0;
      bottom: -6px;
      width: 100%;
      height: 5px;
      background-color: #FF6473;
    }

    .title {
      font-size: 20px;
      text-align: center;
    }
  }

  & > .row {
    padding-top: 62px;
  }

  overflow: hidden;
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

}

.bobby-duke {
  padding-top: 60px;
  padding-bottom: 60px;
  .title {
    margin-bottom: 40px;
  }
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

.row.teacher-quote {
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
