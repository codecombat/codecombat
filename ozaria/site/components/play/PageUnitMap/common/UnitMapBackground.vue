<script>

  import levelDot from './UnitMapLevelDot'
  import ModalCharCustomization from 'ozaria/site/components/char-customization/ModalCharCustomization'
  import { mapGetters } from 'vuex'

  export default Vue.extend({
    components: {
      'level-dot': levelDot,
      'modal-char-customization': ModalCharCustomization
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
        // using dungeon image for now, update later as per UI specs
        if (this.campaignData.backgroundImage) {
          return {
            'background-image': 'url(/file/' + this.campaignData.backgroundImage[0].image + ')'
          }
        }
        return undefined
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
      window.currentView.logoutRedirectURL = null // this is needed so that user stays on the unit map after logout.
      // heroName is not working as computed property for some reason
      // TODO move heroName to Vuex store `me` and use its getter as computed property.
      this.heroName = (me.get('ozariaHeroConfig') || {}).playerHeroName
    },
    methods: {
      backButtonClick () {
        return application.router.navigate(this.backButtonLink, { trigger: true })
      },
      settingsButtonClick () {
        return application.router.navigate('/account/settings', { trigger: true })
      },
      customizeHero () {
        this.showCharCx = true
      },
      onCharCxSaved () {
        this.showCharCx = false
        this.heroName = (me.get('ozariaHeroConfig') || {}).playerHeroName
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
      v-for="level in levels"
      :key="level.original"
      :level-data="level"
      :course-id="courseId"
      :course-instance-id="courseInstanceId"
      :code-language="codeLanguage"
    />
    <button
      class="ozaria-button ozaria-primary-button back-button"
      @click="backButtonClick"
    >
      <span v-if="isAnonymous"> {{ $t("play.back_to_ozaria") }} </span>
      <span v-else> {{ $t("play.back_to_dashboard") }} </span>
    </button>
    <div
      class="unit-map-footer"
    >
      <span class="hero-name text-capitalize"> {{ heroName }} </span>
      <a
        class="customize-link"
        @click="customizeHero"
      >
        ({{ $t("play.customize_hero") }})
      </a>
      <div class="footer-buttons">
        <button
          v-if="!isAnonymous"
          class="ozaria-button ozaria-primary-button settings-button"
          @click="settingsButtonClick"
        >
          {{ $t("account.settings_title") }}
        </button>
        <button
          v-if="!isAnonymous"
          id="logout-button"
          class="ozaria-button ozaria-primary-button logout-button"
        >
          {{ $t("common.logout") }}
        </button>
        <button
          v-if="isAnonymous"
          class="ozaria-button ozaria-primary-button signup-button"
        >
          {{ $t("signup.sign_up") }}
        </button>
      </div>
    </div>
    <modal-char-customization
      v-if="showCharCx"
      class="char-cx-modal"
      @saved="onCharCxSaved"
    />
  </div>
</template>

<style lang="sass" scoped>
@import "ozaria/site/styles/common/variables"

.unit-map-background
  display: flex
  flex-wrap: nowrap
  overflow-x: auto
  position: absolute
  width: 100%
  height: 100%
  background-size: 100%
  background-repeat: no-repeat

  .back-button
    position: absolute
    margin: 15px
    z-index: 1

  .back-button, .settings-button, .logout-button, .signup-button
    background-color: #487ec6
    font-weight: normal
    font-style: italic

  .unit-map-footer
    position: absolute
    bottom: 15px
    left: 15px

    .hero-name
      color: #000000
      font-family: $body-font-style
      font-size: 20px

    .customize-link
      color: #000000
      text-decoration: underline
      font-family: $body-font-style

    .footer-buttons
      margin-top: 5px

      .settings-button, .logout-button, .signup-button
        font-size: 15px

</style>
