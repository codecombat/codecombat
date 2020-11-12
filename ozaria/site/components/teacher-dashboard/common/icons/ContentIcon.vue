<script>
  import IconCutscene from './IconCutscene'
  import IconCapstone from './IconCapstone'
  import IconCinematic from './IconCinematic'
  import IconInteractive from './IconInteractive'
  import IconPracticeLevel from './IconPracticeLevel'
  import IconChallengeLevel from './IconChallengeLevel'
  import IconIntro from './IconIntro'

  export default {
    components: {
      IconCutscene,
      IconCinematic,
      IconCapstone,
      IconPracticeLevel,
      IconChallengeLevel,
      IconInteractive,
      IconIntro
    },

    props: {
      icon: {
        type: String,
        required: true,
        validator: value => ['cutscene', 'cinematic', 'capstone', 'interactive', 'practicelvl', 'challengelvl', 'intro'].indexOf(value) !== -1
      }
    }
  }
</script>

<template>
  <div class="flex-content" :class="icon">
    <IconCutscene v-if="icon=='cutscene'" />
    <IconCinematic v-if="icon=='cinematic'" />
    <IconCapstone v-if="icon=='capstone'" />
    <IconInteractive v-if="icon=='interactive'" />
    <IconPracticeLevel v-if="icon=='practicelvl'" />
    <IconChallengeLevel v-if="icon=='challengelvl'" />
    <IconIntro v-if="icon=='intro'" />
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
