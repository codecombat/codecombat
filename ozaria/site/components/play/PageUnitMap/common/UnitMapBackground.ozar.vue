<script>

  import levelDot from './UnitMapLevelDot'
  import ModalCharCustomization from 'ozaria/site/components/char-customization/ModalCharCustomization'
  import { mapGetters } from 'vuex'
  import urls from 'app/core/urls'
  import UnitMapNav from '../Nav'

  export default Vue.extend({
    components: {
      'level-dot': levelDot,
      'modal-char-customization': ModalCharCustomization,
      UnitMapNav
    },
    props: {
      campaignData: {
        type: Object,
        required: true,
        default: () => {}
      },
      levels: {
        type: Object,
        required: true,
        default: () => {}
      },
      campaignPage: {
        type: Number,
        default: 1
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
      showCharCx: false,
      heroName: undefined
    }),
    computed: {
      ...mapGetters({
        isAnonymous: 'me/isAnonymous',
        isTeacher: 'me/isTeacher',
        isStudent: 'me/isStudent'
      }),
      backgroundImage: function () {
        if (this.campaignData.backgroundImage) {
          // Fetch the background relevant for current campaign page
          const background = this.campaignData.backgroundImage.find((b) => b.campaignPage === this.campaignPage) || {}
          return {
            'background-image': 'url(/file/' + background.image + ')'
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
      }
    },
    mounted () {
      // heroName is not working as computed property for some reason
      // TODO move heroName to Vuex store `me` and use its getter as computed property.
      this.heroName = (me.get('ozariaUserOptions') || {}).playerHeroName
    },
    methods: {
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
            campaignId: this.campaignData._id
          })
          return application.router.navigate(url, { trigger: true })
        }
      }
    }
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
    />
    <unit-map-nav
      @customizeHero="customizeHero"
      :backButtonLink="backButtonLink"
    />
    <div
      v-if="showNavDots"
      id="dot-nav"
    >
      <ul>
        <li
          v-for="page in totalPages"
          :key="page"
          :class="{ active: page === campaignPage }"
          :title="page"
          @click="clickPageNav(page)"
        />
      </ul>
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

    ul
      list-style: none
      margin: 0
      padding: 0

    li
      position: relative
      float: left
      background-color: #bdc3c7
      border: 3px solid #bdc3c7
      border-radius: 15px 15px 15px 15px
      cursor: pointer
      padding: 5px
      height: 10px
      margin: 10px 10px 0px 0px
      width: 10px
      vertical-align: bottom

    li.active
      background-color: #3c4f69

</style>
