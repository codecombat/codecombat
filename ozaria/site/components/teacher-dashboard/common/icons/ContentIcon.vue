<script>
import IconCutscene from './IconCutscene'
import IconCapstone from './IconCapstone'
import IconCinematic from './IconCinematic'
import IconInteractive from './IconInteractive'
import IconPracticeLevel from './IconPracticeLevel'
import IconChallengeLevel from './IconChallengeLevel'
import IconIntro from './IconIntro'
import IconAIUse from './IconAIUse'
import IconAILearn from './IconAILearn'

export default {
  components: {
    IconCutscene,
    IconCinematic,
    IconCapstone,
    IconPracticeLevel,
    IconChallengeLevel,
    IconInteractive,
    IconIntro,
    IconAILearn,
    IconAIUse,
  },

  props: {
    icon: {
      type: String,
      required: true,
      validator: value => { return ['ai-use', 'ai-learn', 'cutscene', 'cinematic', 'capstone', 'interactive', 'practicelvl', 'challengelvl', 'intro', 'hero', 'course-ladder', 'game-dev', 'web-dev', 'ladder', 'challenge'].indexOf(value) !== -1 }
    }
  }
}
</script>

<template>
  <div
    class="flex-content"
    :class="icon"
  >
    <IconCutscene v-if="icon=='cutscene'" />
    <IconCinematic v-else-if="icon=='cinematic'" />
    <IconCapstone v-else-if="['capstone'].includes(icon)" />
    <IconInteractive v-else-if="icon=='interactive'" />
    <IconPracticeLevel v-else-if="icon=='practicelvl'" />
    <IconChallengeLevel v-else-if="['challengelvl', 'hero'].includes(icon)" />
    <IconIntro v-else-if="icon=='intro'" />
    <IconAIUse v-else-if="icon=='ai-use'" />
    <IconAILearn v-else-if="icon=='ai-learn'" />
    <IconIntro v-else />
  </div>
</template>

<style lang="scss" scoped>
  /* Allows us to resize this container and keep icons centered */
  .flex-content {
    display: flex;

    justify-content: center;
    align-items: center;
  }

  /*
    This style is used to ever so slightly
    balance the icons so they appear the same size.
  */
  .capstone, .practicelvl, .challengelvl {
    padding: 1px;
  }

  .cutscene {
    transform: translateX(2px);
  }
</style>
