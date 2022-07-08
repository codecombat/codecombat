<script>
  import { getNextLevelLink, internationalizeLevelType } from 'ozaria/site/common/ozariaUtils'
  import { mapGetters } from 'vuex'
  import utils from 'core/utils'

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
      levelStatusText: '',
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
          next: this.levelData.next
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
        return utils.i18n(this.levelData, 'displayName') || utils.i18n(this.levelData, 'name')
      }
    },

    created () {
      this.setLevelTypeAndIcon()
      this.setLevelStatus()
      this.setLevelConcepts()
    },

    methods: {
      setLevelTypeAndIcon () {
        let type = this.levelData.ozariaType
        if (type === 'practice') {
          this.levelIcon['Complete'] = '/images/ozaria/unit-map/complete_practice.png'
          this.levelIcon['Locked'] = '/images/ozaria/unit-map/locked_practice.png'
          this.levelIcon['In Progress'] = '/images/ozaria/unit-map/unlocked_practice.png'
        } else if (type === 'challenge') {
          this.levelIcon['Complete'] = '/images/ozaria/unit-map/complete_challenge.png'
          this.levelIcon['Locked'] = '/images/ozaria/unit-map/locked_challenge.png'
          this.levelIcon['In Progress'] = '/images/ozaria/unit-map/unlocked_challenge.png'
        } else if (this.isCutsceneLevel) {
          type = 'cutscene'
          this.levelIcon['Complete'] = '/images/ozaria/unit-map/complete_cutscene.png'
          this.levelIcon['Locked'] = '/images/ozaria/unit-map/locked_cutscene.png'
          this.levelIcon['In Progress'] = '/images/ozaria/unit-map/unlocked_cutscene.png'
        } else if (type === 'capstone') {
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
        this.levelType = internationalizeLevelType(type)
      },
      setLevelStatus () {
        if (this.levelData.locked) {
          this.levelStatus = 'Locked'
          this.levelStatusText = $.i18n.t('play_level.level_status_locked')
        } else if (this.levelData.next) {
          this.levelStatus = 'In Progress'
          this.levelStatusText = $.i18n.t('play_level.level_status_in_progress')
        } else {
          this.levelStatus = 'Complete'
          this.levelStatusText = $.i18n.t('play_level.level_status_complete')
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
    <v-popover
      popover-base-class="level-dot-tooltip"
      trigger="hover"
      placement="top"
      offset="10"
    >
      <a
        class="level-dot-link"
        :href="playLevelLink"
      >
        <img
          class="level-dot-image"
          :class="levelDotClasses"
          :src="levelIcon[levelStatus]"
        >
      </a>

      <template slot="popover">
        <div class="tooltip-container">
          <div class="tooltip-title">
            {{ levelType }}
          </div>
          <div class="tooltip-body">
            <div class="level-title">
              {{ displayName }}
            </div>

            <div class="level-status">
              {{ $t("play_level.level_status") }}: {{levelStatusText}}
            </div>
          </div>
        </div>
      </template>
    </v-popover>
  </div>
</template>

<style lang="sass">
    .level-dot-tooltip
        padding: 0
        box-shadow: 4px 4px 15px 0 rgba(0,0,0,0.5)

        &:before
            content: ""
            position: absolute
            top: calc(100% - 11px)
            left: calc(50% - 10px)

            width: 20px
            height: 20px
            transform: rotate(45deg)

            background-color: rgba(238,236,237,1)
            border: 5px solid #401A1A
            border-top: none
            border-left: none

            z-index: 2

        .tooltip-title
            background-color: #401A1A
            padding: 11px 22px

            color: #FFF
            font-family: "Work Sans"
            font-size: 14px
            letter-spacing: 0.23px
            line-height: 16px

        .tooltip-inner
            padding: 0

            border: 5px solid #401A1A
            background-color: rgba(238,236,237,1)

            text-align: center

            .tooltip-body
                padding: 9px

            .level-title
                color: #401A1A
                font-family: "Work Sans"
                font-size: 17px
                font-weight: 600
                letter-spacing: 0.32px
                line-height: 24px

            .level-status
                color: #401A1A
                font-family: "Open Sans"
                font-size: 14px
                letter-spacing: 0.48px
                line-height: 19px
</style>

<style scoped lang="sass">
    // TODO calculate level-dot css based on unit map dimensions similar to campaign-view.sass
    .level-dot
        position: absolute
        width: 3.5vmin
        height: 3.5vmin
        max-width: 30px
        max-height: 30px
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
            z-index: 3 // Make sure progress dot sits above invisible navigation

            &.locked
                cursor: auto

        ::v-deep .trigger
            display: block !important
</style>
