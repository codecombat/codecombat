<script>
  import { getNextLevelLink } from 'ozaria/site/common/ozariaUtils'
  export default Vue.extend({
    props: {
      levelData: {
        type: Object,
        required: true
      },
      courseId: {
        type: String,
        default: undefined
      },
      courseInstanceId: {
        type: String,
        default: undefined
      },
      campaignId: {
        type: String,
        default: undefined
      },
      codeLanguage: {
        type: String,
        default: undefined
      }
    },
    data: () => ({
      levelType: '',
      levelStatus: '',
      levelIcon: {},
      concepts: ''
    }),
    computed: {
      isCutsceneLevel: function () {
        if (this.levelData.type !== 'intro') {
          return false
        }
        const introContent = this.levelData.introContent
        return introContent.length === 1 && introContent[0].type === 'cutscene-video'
      },
      levelDotPosition: function () {
        let position = {
          left: this.levelData.position.x + '%',
          bottom: this.levelData.position.y + '%'
        }
        return position
      },
      levelDotClasses: function () {
        return {
          locked: this.levelData.locked,
          next: this.levelData.next,
          'has-tooltip': this.levelData.next || !this.levelData.locked
        }
      },
      playLevelLink: function () {
        if (this.levelData.locked) { return '#' }

        const nextLevelOptions = {
          courseId: this.courseId,
          courseInstanceId: this.courseInstanceId,
          campaignId: this.campaignId
        }
        const link = getNextLevelLink(this.levelData, nextLevelOptions)
        return link || '#'
      },
      tooltipText: function () {
        if ((this.concepts || []).length > 0) {
          return `<p>${this.levelData.name}</p><p>${this.levelType}: ${this.concepts}</p><p>Status: ${this.levelStatus}</p>`
        } else {
          return `<p>${this.levelData.name}</p><p>${this.levelType}</p><p>Status: ${this.levelStatus}</p>`
        }
      }
    },
    created () {
      this.setLevelTypeAndIcon()
      this.setLevelStatus()
      this.setLevelConcepts()
    },
    mounted () {
      $('.level-dot-image.has-tooltip').tooltip({ html: true })
    },
    methods: {
      setLevelTypeAndIcon () {
        if (this.levelData.ozariaType === 'practice') {
          this.levelType = 'Practice'
          this.levelIcon['Complete'] = '/images/ozaria/unit-map/complete_practice.png'
          this.levelIcon['Locked'] = '/images/ozaria/unit-map/locked_practice.png'
          this.levelIcon['In Progress'] = '/images/ozaria/unit-map/unlocked_practice.png'
        } else if (this.levelData.ozariaType === 'challenge') {
          this.levelType = 'Challenge'
          this.levelIcon['Complete'] = '/images/ozaria/unit-map/complete_challenge.png'
          this.levelIcon['Locked'] = '/images/ozaria/unit-map/locked_challenge.png'
          this.levelIcon['In Progress'] = '/images/ozaria/unit-map/unlocked_challenge.png'
        } else if (this.isCutsceneLevel) {
          this.levelType = 'Cutscene'
          this.levelIcon['Complete'] = '/images/ozaria/unit-map/complete_cutscene.png'
          this.levelIcon['Locked'] = '/images/ozaria/unit-map/locked_cutscene.png'
          this.levelIcon['In Progress'] = '/images/ozaria/unit-map/unlocked_cutscene.png'
        } else if (this.levelData.ozariaType === 'capstone') {
          this.levelType = 'Capstone'
          this.levelIcon['Complete'] = '/images/ozaria/unit-map/complete_capstone.png'
          this.levelIcon['Locked'] = '/images/ozaria/unit-map/locked_capstone.png'
          this.levelIcon['In Progress'] = '/images/ozaria/unit-map/unlocked_capstone.png'
        } else if (this.levelData.type === 'intro') {
          this.levelType = 'Intro'
          this.levelIcon['Complete'] = '/images/ozaria/unit-map/complete_intro.png'
          this.levelIcon['Locked'] = '/images/ozaria/unit-map/locked_intro.png'
          this.levelIcon['In Progress'] = '/images/ozaria/unit-map/unlocked_intro.png'
        } else {
          // Using practice as the default values
          this.levelType = 'Practice'
          this.levelIcon['Complete'] = '/images/ozaria/unit-map/complete_practice.png'
          this.levelIcon['Locked'] = '/images/ozaria/unit-map/locked_practice.png'
          this.levelIcon['In Progress'] = '/images/ozaria/unit-map/unlocked_practice.png'
        }
      },
      setLevelStatus () {
        if (this.levelData.locked) {
          this.levelStatus = 'Locked'
        } else if (this.levelData.next) {
          this.levelStatus = 'In Progress'
        } else {
          this.levelStatus = 'Complete'
        }
      },
      setLevelConcepts () {
        if ((this.levelData.concepts || []).length > 0) {
          this.concepts = this.levelData.concepts
        }
      }
    }
  })
</script>

<template>
  <div
    class="level-dot"
    :style="levelDotPosition"
  >
    <a
      class="level-dot-link"
      :href="playLevelLink"
    >
      <img
        class="level-dot-image"
        :class="levelDotClasses"
        :src="levelIcon[levelStatus]"
        :title="tooltipText"
      >
    </a>
  </div>
</template>

<style lang="sass">
  .has-tooltip + .tooltip > .tooltip-inner
    background-color: #fff
    color: #000
    width: 150px
    font-style: italic
    border-radius: 0

  .has-tooltip + .tooltip.top > .tooltip-arrow
    border-top-color: #fff
</style>

<style scoped lang="sass">
  .level-dot
    position: absolute
    width: 1.5%
    height: 2%

  .level-dot-link
    width: 100%
    height: 100%
    position: absolute

  .level-dot-image
    width: 100%
    height: 100%
    position: absolute

    &:not(.locked):hover
      border: 2px groove red
</style>
