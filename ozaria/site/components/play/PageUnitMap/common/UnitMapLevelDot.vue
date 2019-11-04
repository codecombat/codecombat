<script>
  import { getNextLevelLink } from 'ozaria/site/common/ozariaUtils'
  import { mapGetters } from 'vuex'
  import { internationalizeLevelType } from 'ozaria/site/common/ozariaUtils'

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
      ...mapGetters({
        isTeacher: 'me/isTeacher'
      }),
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
          codeLanguage: this.codeLanguage
        }

        const link = getNextLevelLink(this.levelData, nextLevelOptions)
        return link || '#'
      },
      displayName: function () {
        return this.levelData.displayName || this.levelData.name
      },
      tooltipText: function () {
        if ((this.concepts || []).length > 0) {
          return `<p>${this.displayName}</p><p>${this.levelType}: ${this.concepts}</p><p>${$.i18n.t("play_level.level_status")}: ${this.levelStatus}</p>`
        } else {
          return `<p>${this.displayName}</p><p>${this.levelType}</p><p>${$.i18n.t("play_level.level_status")}: ${this.levelStatus}</p>`
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
        let type = this.levelData.ozariaType || 'practice'
        if (this.levelData.ozariaType === 'practice') {
          this.levelIcon['Complete'] = '/images/ozaria/unit-map/complete_practice.png'
          this.levelIcon['Locked'] = '/images/ozaria/unit-map/locked_practice.png'
          this.levelIcon['In Progress'] = '/images/ozaria/unit-map/unlocked_practice.png'
        } else if (this.levelData.ozariaType === 'challenge') {
          this.levelIcon['Complete'] = '/images/ozaria/unit-map/complete_challenge.png'
          this.levelIcon['Locked'] = '/images/ozaria/unit-map/locked_challenge.png'
          this.levelIcon['In Progress'] = '/images/ozaria/unit-map/unlocked_challenge.png'
        } else if (this.isCutsceneLevel) {
          type = 'cutscene'
          this.levelIcon['Complete'] = '/images/ozaria/unit-map/complete_cutscene.png'
          this.levelIcon['Locked'] = '/images/ozaria/unit-map/locked_cutscene.png'
          this.levelIcon['In Progress'] = '/images/ozaria/unit-map/unlocked_cutscene.png'
        } else if (this.levelData.ozariaType === 'capstone') {
          this.levelIcon['Complete'] = '/images/ozaria/unit-map/complete_capstone.png'
          this.levelIcon['Locked'] = '/images/ozaria/unit-map/locked_capstone.png'
          this.levelIcon['In Progress'] = '/images/ozaria/unit-map/unlocked_capstone.png'
        } else if (this.levelData.type === 'intro') {
          type = 'intro'
          this.levelIcon['Complete'] = '/images/ozaria/unit-map/complete_intro.png'
          this.levelIcon['Locked'] = '/images/ozaria/unit-map/locked_intro.png'
          this.levelIcon['In Progress'] = '/images/ozaria/unit-map/unlocked_intro.png'
        } else {
          // Using practice as the default values
          this.levelIcon['Complete'] = '/images/ozaria/unit-map/complete_practice.png'
          this.levelIcon['Locked'] = '/images/ozaria/unit-map/locked_practice.png'
          this.levelIcon['In Progress'] = '/images/ozaria/unit-map/unlocked_practice.png'
        }
        this.levelType = internationalizeLevelType(type) + $.i18n.t()
      },
      setLevelStatus () {
        if (this.levelData.locked) {
          this.levelStatus = $.i18n.t('play_level.level_status_locked')
        } else if (this.levelData.next) {
          this.levelStatus = $.i18n.t('play_level.level_status_in_progress')
        } else {
          this.levelStatus = $.i18n.t('play_level.level_status_complete')
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

  // TODO calculate level-dot css based on unit map dimensions similar to campaign-view.sass
  .level-dot
    position: absolute
    width: 2%
    height: 3.0599%
    margin-left: -1%
    margin-bottom: -0.45499%

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
