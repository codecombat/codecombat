<script>

import levelDot from './UnitMapLevelDot'
import ModalCharCustomization from 'ozaria/site/components/char-customization/ModalCharCustomization'
import { mapGetters, mapActions } from 'vuex'
import urls from 'app/core/urls'
import UnitMapNav from '../Nav'

export default Vue.extend({
  components: {
    'level-dot': levelDot,
    'modal-char-customization': ModalCharCustomization,
    UnitMapNav,
  },
  props: {
    campaignData: {
      type: Object,
      required: true,
      default: () => {},
    },
    levels: {
      type: Object,
      required: true,
      default: () => {},
    },
    campaignPage: {
      type: Number,
      default: 1,
    },
    courseId: {
      type: String,
      default: undefined,
    },
    courseInstanceId: {
      type: String,
      default: undefined,
    },
    codeLanguage: {
      type: String,
      default: undefined,
    },
    classroomId: {
      type: String,
      default: '',
    },
  },
  data: () => ({
    showCharCx: false,
    heroName: undefined,
  }),
  computed: {
    ...mapGetters({
      isAnonymous: 'me/isAnonymous',
      isTeacher: 'me/isTeacher',
      isStudent: 'me/isStudent',
      getLevelNumber: 'gameContent/getLevelNumber',
    }),
    backgroundImage: function () {
      if (this.campaignData.backgroundImage) {
        // Fetch the background relevant for current campaign page
        const background = this.campaignData.backgroundImage.find((b) => b.campaignPage === this.campaignPage) || {}
        return {
          'background-image': 'url(/file/' + background.image + ')',
        }
      }
      return undefined
    },
    currentPageLevels () {
      // Fetch the levels relevant for current campaign page
      const currentPageLevelIds = Object.keys(this.levels).filter((l) => this.levels[l].campaignPage === this.campaignPage)
      return _.pick(this.levels, currentPageLevelIds)
    },
    totalPages: function () {
      // get max value of campaignPage from the classroom levels
      return Math.max(...Object.values(this.levels).map((l) => l.campaignPage || 1), 0) || 0
    },
    showNavDots: function () {
      return this.totalPages > 1
    },
    backButtonLink: function () {
      if (this.isTeacher) {
        return '/teachers'
      } else if (this.isStudent) {
        return '/students'
      } else {
        return '/'
      }
    },
  },
  mounted () {
    // heroName is not working as computed property for some reason
    // TODO move heroName to Vuex store `me` and use its getter as computed property.
    this.heroName = (me.get('ozariaUserOptions') || {}).playerHeroName

    this.generateLevelNumberMap({ campaignId: this.campaignData._id, language: this.codeLanguage })
  },
  methods: {
    ...mapActions({
      generateLevelNumberMap: 'gameContent/generateLevelNumberMap',
    }),

    customizeHero () {
      this.showCharCx = true
    },
    onCharCxSaved () {
      this.showCharCx = false
      this.heroName = (me.get('ozariaUserOptions') || {}).playerHeroName
    },
    onCharCxClose () {
      this.showCharCx = false
    },
    clickPageNav (page) {
      if (page !== this.campaignPage) {
        const url = urls.courseWorldMap({
          courseId: this.courseId,
          courseInstanceId: this.courseInstanceId,
          campaignPage: page,
          campaignId: this.campaignData._id,
          codeLanguage: this.codeLanguage,
        })
        return application.router.navigate(url, { trigger: true })
      }
    },
    previousPage () {
      if (this.campaignPage > 1) {
        this.clickPageNav(this.campaignPage - 1)
      }
    },
    nextPage () {
      if (this.campaignPage < this.totalPages) {
        this.clickPageNav(this.campaignPage + 1)
      }
    },
  },
})
</script>

<template>
  <div
    class="unit-map-background"
    :style="[backgroundImage]"
  >
    <level-dot
      v-for="level in currentPageLevels"
      :key="level.original"
      :level-data="level"
      :course-id="courseId"
      :course-instance-id="courseInstanceId"
      :code-language="codeLanguage"
      :classroom-id="classroomId"
      :level-number="getLevelNumber(level.original)"
    />
    <unit-map-nav
      :back-button-link="backButtonLink"
      @customizeHero="customizeHero"
    />
    <div
      v-if="showNavDots"
      id="dot-nav"
    >
      <div
        class="arrow left"
        :class="{ inactive: campaignPage === 1 }"
        role="button"
        :aria-label="$t('play_level.navigate_to_previous_page')"
        :aria-disabled="campaignPage === 1"
        @click="previousPage"
      />
      <ul>
        <li
          v-for="page in totalPages"
          :key="page"
          :class="{ selected: page === campaignPage }"
          :title="page"
          @click="clickPageNav(page)"
        />
      </ul>
      <div
        class="arrow right"
        :class="{ inactive: campaignPage === totalPages }"
        role="button"
        :aria-label="$t('play_level.navigate_to_next_page')"
        :aria-disabled="campaignPage === totalPages"
        @click="nextPage"
      />
    </div>
    <modal-char-customization
      v-if="showCharCx"
      class="char-cx-modal"
      @saved="onCharCxSaved"
      @close="onCharCxClose"
    />
  </div>
</template>

<style lang="sass" scoped>
@import "ozaria/site/styles/common/variables"

.unit-map-background
  position: absolute
  width: 100%
  height: 100%
  background-size: 100%
  background-repeat: no-repeat
  display: flex
  justify-content: center

  .char-cx-modal
    position: fixed
    width: 100vw
    height: 100vh
    top: 0
    left: 0

  #dot-nav
    position: absolute
    z-index: 999
    bottom: 15px
    display: flex
    background-color: rgba(0, 0, 0, 0.6)
    padding: 10px
    border-radius: 20px

    .arrow
      width: 0
      height: 0
      border-style: solid
      position: relative
      cursor: pointer

      &::before
        content: ""
        position: absolute
        width: 0
        height: 0
        border-style: solid
        z-index: 1

      &.inactive
        opacity: 0.5
        cursor: default

      &.left
        border-width: 20px 30px 20px 0
        border-color: transparent white transparent transparent
        &::before
          border-width: 15px 25px 15px 0
          border-color: transparent #bdc3c7 transparent transparent
          left: 3px
          top: -15px

      &.right
        border-width: 20px 0 20px 30px
        border-color: transparent transparent transparent white
        &::before
          border-width: 15px 0 15px 25px
          border-color: transparent transparent transparent #bdc3c7
          right: 3px
          top: -15px

    ul
      list-style: none
      margin: 0
      padding: 0
      display: flex
      justify-content: center
      align-items: center

    li
      position: relative
      float: left
      background-color: #bdc3c7
      border: 3px solid #bdc3c7
      border-radius: 15px 15px 15px 15px
      cursor: pointer
      padding: 5px
      height: 10px
      margin: 10px 10px 10px 10px
      width: 10px
      vertical-align: bottom

    li.selected
      background-color: #3c4f69
      cursor: default

</style>
