<script>
/**
 * Creates the module heading for the all students table.
 */

  import IconCutscene from '../../common/icons/IconCutscene'
  import IconCapstone from '../../common/icons/IconCapstone'
  import IconCinematic from '../../common/icons/IconCinematic'
  import IconInteractive from '../../common/icons/IconInteractive'
  import IconPracticeLevel from '../../common/icons/IconPracticeLevel'
  import IconChallengeLevel from '../../common/icons/IconChallengeLevel'

  import ProgressDot from '../../common/progress/progressDot'

  export default {
    components: {
      IconCutscene,
      IconCinematic,
      IconCapstone,
      IconPracticeLevel,
      IconChallengeLevel,
      IconInteractive,
      ProgressDot
    },
    props: {
      moduleHeading: {
        type: String,
        required: true
      },
      listOfContent: {
        type: Array,
        required: true
      },
      classSummaryProgress: {
        type: Array,
        required: true
      }
    },

    computed: {
      cssVariables () {
        return {
          '--cols': this.listOfContent.length
        }
      }
    }
  }
</script>

<template>
  <div class="moduleHeading" :style="cssVariables">
    <div class="title">
      <h3>{{ moduleHeading }}</h3>
    </div>
    <div class="content-icons" v-for="({type}, idx) of listOfContent" :key="`${idx}-${type}`">
      <IconCutscene v-if="type=='cutscene'" />
      <IconCinematic v-if="type=='cinematic'" />
      <IconCapstone v-if="type=='capstone'" />
      <IconInteractive v-if="type=='interactive'" />
      <IconPracticeLevel v-if="type=='practicelvl'" />
      <IconChallengeLevel v-if="type=='challengelvl'" />
    </div>
    <div class="golden-backer" v-for="({ status }, idx) of classSummaryProgress" :key="idx">
      <ProgressDot :status="status" />
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "ozaria/site/styles/common/variables.scss";
@import "app/styles/ozaria/_ozaria-style-params.scss";

.moduleHeading {
  display: grid;
  grid-template-columns: repeat(var(--cols), 28px);
  grid-template-rows: repeat(3, 38px);
  align-items: center;
  justify-items: center;

  background-color: #ddd;
  border: 1px solid white;
}

.title {
  /* Makes title span entire grid row */
  grid-column: 1 / -1;
  justify-self: normal;

  height: 100%;
  display: flex;
  align-items: center;

  background-color: #413c55;
  border-bottom: 1px solid white;
}

.golden-backer {
  background-color: #fff9e3;
  border-top: 0.5px solid #d4b235;
  border-bottom: 0.5px solid #d4b235;

  /* TODO: This isn't working. Why? */
  &:first-child {
    border-left: 0.5px solid #d4b235;
  }

  &:last-child {
    border-right: 0.5px solid #d4b235;
  }

  width: 100%;
  height: 100%;
  display: flex;
  justify-content: center;
  align-items: center;
}

.content-icons {
  height: 100%;
  width: 100%;

  display: flex;
  align-items: center;
  justify-content: center;

  background-color: #d8d8d8;
  border-top: 1px solid white;
  border-bottom: 1px solid white;
}

h3 {
  @include font-p-4-paragraph-smallest-gray;
  color: white;
  padding-left: 12px;
}
</style>
