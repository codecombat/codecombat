<script>
  import IconCutscene from './IconCutscene'
  import IconCapstone from './IconCapstone'
  import IconCinematic from './IconCinematic'
  import IconInteractive from './IconInteractive'
  import IconPracticeLevel from './IconPracticeLevel'
  import IconChallengeLevel from './IconChallengeLevel'

  export default {
    components: {
      IconCutscene,
      IconCinematic,
      IconCapstone,
      IconPracticeLevel,
      IconChallengeLevel,
      IconInteractive
    },

    props: {
      icon: {
        type: String,
        required: true,
        validator: value => ['cutscene', 'cinematic', 'capstone', 'interactive', 'practicelvl', 'challengelvl'].indexOf(value) !== -1
      }
    }
  }
</script>

<template>
  <div>
    <IconCutscene v-if="icon=='cutscene'" />
    <IconCinematic v-if="icon=='cinematic'" />
    <IconCapstone v-if="icon=='capstone'" />
    <IconInteractive v-if="icon=='interactive'" />
    <IconPracticeLevel v-if="icon=='practicelvl'" />
    <IconChallengeLevel v-if="icon=='challengelvl'" />
  </div>
</template>
