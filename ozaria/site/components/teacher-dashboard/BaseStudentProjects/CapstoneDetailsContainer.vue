<script>
  import utils from 'core/utils'
  import { getOzariaAssetUrl } from '../../../common/ozariaUtils'

  export default {
    props: {
      capstoneLevel: {
        type: Object,
        default: () => {}
      },
      course: {
        type: Object,
        default: () => {}
      }
    },
    computed: {
      learningGoals () {
        const specificArticles = (this.capstoneLevel.documentation || {}).specificArticles || []
        const learningGoals = specificArticles.filter((s) => s.name === 'Learning Goals').map((l) => utils.i18n(l, 'body'))

        return learningGoals
      },
      conceptsCovered () {
        return this.capstoneLevel.concepts
      },
      cstaStandards () { // TODO update from course
        return []
      },
      capstoneImage () {
        if (this.capstoneLevel.screenshot) {
          return getOzariaAssetUrl(this.capstoneLevel.screenshot)
        } else {
          return ''
        }
      }
    }
  }
</script>

<template>
  <div>
    <div class="capstone-img">
      <img :src="capstoneImage">
    </div>
    <div class="description text">
      {{ capstoneLevel.description }}
    </div>
    <div class="learning-goals text">
      <div class="title">
        Learning Goals
      </div>
      <ul>
        <li
          v-for="learningGoal in learningGoals"
          :key="learningGoal"
        >
          <img
            class="check-mark"
            src="/images/ozaria/teachers/dashboard/svg_icons/CheckMark.svg"
          >
          {{ learningGoal }}
        </li>
      </ul>
    </div>
    <div class="concepts text">
      <div class="title">
        Concepts Covered
      </div>
      <ul>
        <li
          v-for="concept in conceptsCovered"
          :key="concept"
        >
          <img
            class="check-mark"
            src="/images/ozaria/teachers/dashboard/svg_icons/CheckMark.svg"
          >
          {{ $t(`concepts.${concept}`) }}
        </li>
      </ul>
    </div>
    <div class="csta-standards text">
      <div class="title">
        CSTA Standards
      </div>
      <ul>
        <li
          v-for="csta in cstaStandards"
          :key="csta"
        >
          <img
            class="check-mark"
            src="/images/ozaria/teachers/dashboard/svg_icons/CheckMark.svg"
          >
          {{ csta }}
        </li>
      </ul>
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

.title {
  @include font-p-3-small-button-text-black;
  color: $twilight;
  text-align: left;
  margin: 10px 0px;
}

.text {
  @include font-p-3-paragraph-small-gray;
  margin: 20px 0px;
}

ul {
  list-style: none;
  padding: 0px;
}

.check-mark {
  height: 10px;
}

.capstone-img {
  margin: 20px 0px;
  img {
    width: 100%;
  }
}
</style>
