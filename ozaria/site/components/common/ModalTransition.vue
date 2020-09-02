<script>
  import BaseModal from './BaseModal'
  import { mapActions, mapGetters } from 'vuex'
  import { internationalizeConfig, getNextLevelForLevel, getNextLevelLink, tryCopy, internationalizeLevelType, internationalizeContentType } from 'ozaria/site/common/ozariaUtils'
  import utils from 'core/utils'
  import urls from 'core/urls'
  import api from 'core/api'
  import ModalCharCustomization from 'ozaria/site/components/char-customization/ModalCharCustomization'
  import ClassroomLib from '../../../../app/models/ClassroomLib'

  export default Vue.extend({
    components: {
      BaseModal,
      ModalCharCustomization
    },
    props: {
      currentLevel: {
        type: Object,
        required: true
      },
      capstoneStage: {
        type: String,
        default: null
      },
      courseId: {
        type: String,
        default: null
      },
      courseInstanceId: {
        type: String,
        default: null
      },
      currentIntroContent: {
        type: Object,
        default: () => { return undefined }
      },
      introLevelComplete: {
        type: Boolean,
        default: undefined
      },
      goToNextDirectly: {
        type: Boolean,
        default: false
      },
      showShareModal: {
        type: Boolean,
        default: false
      }
    },
    data: () => ({
      nextLevelLink: '',
      editCapstoneLevelData: undefined,
      capstoneLevelSession: {},
      isFirstLevel: undefined,
      showCharCx: false,
      classroom: undefined,
      nextLevelIsLocked: false,
      doReload: true // Reload browser while loading the next URL. This is to fix the memory leak in cinematics.
    }),
    computed: {
      ...mapGetters({
        levelsList: 'unitMap/getCurrentLevelsList',
        userLocale: 'me/preferredLocale',
        campaignData: 'campaigns/getCampaignData'
      }),
      shareModal () {
        return !me.isSessionless() && (this.showShareModal || this.editCapstoneLevelData)
      },
      currentContent () {
        if (this.shareModal) {
          return this.editCapstoneLevelData || {}
        }
        return this.currentIntroContent || this.currentLevel.attributes || this.currentLevel || {}
      },
      contentName () {
        return utils.i18n(this.currentContent,'displayName') || utils.i18n(this.currentContent,'name')
      },
      contentType () {
        if (this.currentContent.ozariaType) {
          return internationalizeLevelType(this.currentContent.ozariaType, true)
        } else {
          return internationalizeContentType(this.currentContent.contentType)
        }
      },
      learningGoals () {
        const specificArticles = (this.currentContent.documentation || {}).specificArticles
        const learningGoals = _.find(specificArticles, { name: 'Learning Goals' })
        let learningGoalsText
        if (learningGoals) {
          learningGoalsText = internationalizeConfig(learningGoals, this.userLocale).body
        }
        return learningGoalsText
      },
      shareURL () {
        if (this.editCapstoneLevelData && this.capstoneLevelSession) {
          const shareUrlOptions = {
            level: this.editCapstoneLevelData,
            session: { _id: this.capstoneLevelSession._id }
          }
          if (this.courseId) {
            shareUrlOptions.course = { _id: this.courseId }
          }
          return urls.playDevLevel(shareUrlOptions)
        }
        return ''
      },
      charCxModal () {
        return this.isFirstLevel && !(me.get('ozariaUserOptions') || {}).tints
      },
      codeLanguage () {
        return utils.getQueryVariable('codeLanguage')
      }
    },
    async mounted () {
      if (!this.currentLevel) {
        // TODO handle_error_ozaria
        console.error('Level data are required for victory modal')
        return noty({ text: 'Error in victory screen', layout: 'topCenter', type: 'error', timeout: 2000 })
      }

      // TODO: replace with Ozaria sound
      // TODO Use new audio system post-august launch
      // Backbone.Mediator.publish('audio-player:play-sound', { trigger: 'victory' })

      try {
        if (!this.currentIntroContent || this.introLevelComplete) { // Fetch next level only if its not an intro level, or all content in intro level is complete
          await this.getNextLevelLink()
        }
        if (this.goToNextDirectly) {
          return application.router.navigate(this.nextLevelLink, { trigger: true }, this.doReload)
        }
      } catch (e) {
        // TODO handle_error_ozaria
        console.error('Error in victory modal', e)
      }
    },

    methods: {
      ...mapActions({
        buildLevelsData: 'unitMap/buildLevelsData'
      }),
      async fetchRequiredData (campaignHandle) {
        // TODO: Fix duplicate fetching here. The `buildLevelsData` also fetches this.
        //       Ideally we use vuex getters to get the already fetched classroom.
        const promises = []
        promises.push(api.courseInstances.get({ courseInstanceID: this.courseInstanceId }).then(async courseInstance => {
          const classroomId = courseInstance.classroomID
          // classroom snapshot of the levels for the course
          this.classroom = await api.classrooms.get({ classroomID: classroomId })
        }))

        promises.push(this.buildLevelsData({ campaignHandle, courseInstanceId: this.courseInstanceId, courseId: this.courseId, classroom: this.classroom }))
        return Promise.all(promises)
      },

      async getNextLevelLink () {
        const campaignHandle = this.currentLevel.campaign || this.currentLevel.attributes.campaign
        await this.fetchRequiredData(campaignHandle)
        const currentLevelData = this.levelsList[this.currentLevel.original || this.currentLevel.attributes.original]
        this.isFirstLevel = currentLevelData.first
        let currentLevelStage
        if (currentLevelData.isPlayedInStages && this.capstoneStage) {
          currentLevelStage = parseInt(this.capstoneStage)
        }
        const nextLevel = getNextLevelForLevel(currentLevelData, currentLevelStage) || {}
        this.nextLevelIsLocked = ClassroomLib.isStudentOnLockedLevel(this.classroom, me.get('_id'), this.courseId, nextLevel.original)
        if (this.nextLevelIsLocked) {
          noty({
            layout: 'center',
            type: 'info',
            text: this.$t('teacher_dashboard.teacher_locked_message'),
            buttons: [{
              text: this.$t('play.back_to_dashboard'),
              onClick: ($noty) => {
                $noty.close()
                application.router.navigate('/students', { trigger: true })
              }
            }]
          })
        }
        if (nextLevel.original && !this.showShareModal && this.levelsList[nextLevel.original]) {
          const nextLevelLinkOptions = {
            courseId: this.courseId,
            courseInstanceId: this.courseInstanceId,
            codeLanguage: this.codeLanguage
          }
          if (me.isSessionless()) {
            nextLevelLinkOptions.nextLevelStage = nextLevel.nextLevelStage
          }
          // The next level reference may be outdated. We want to use the originalId
          // and find the newest slug. This step is required due to renaming of slugs.
          this.nextLevelLink = getNextLevelLink(this.levelsList[nextLevel.original], nextLevelLinkOptions)
        } else { // last level of the campaign or this.showShareModal=true
          const urlOptions = {
            courseId: this.courseId,
            courseInstanceId: this.courseInstanceId,
            campaignId: campaignHandle,
            codeLanguage: this.codeLanguage
          }
          this.nextLevelLink = urls.courseWorldMap(urlOptions)
          this.editCapstoneLevelData = Object.values(this.levelsList).find((l) => l.ozariaType === 'capstone')
          if (this.editCapstoneLevelData && !me.isSessionless()) {
            this.capstoneLevelSession = await this.getLevelSession(this.editCapstoneLevelData.slug)
            window.tracker.trackEvent('Completed Capstone Level', {
              category: 'Play Level',
              levelOriginalId: this.editCapstoneLevelData.original,
              levelSessionId: (this.capstoneLevelSession || {})._id
            }, ['Google Analytics'])
          }
        }
      },
      async getLevelSession (levelIdOrSlug) {
        try {
          // TODO: drive level session from Vuex store
          return await api.levels.upsertSession(levelIdOrSlug, { courseInstanceId: this.courseInstanceId, codeLanguage: this.codeLanguage })
        } catch (err) {
          console.error('Error in finding level session', err)
        }
      },
      nextButtonClick () {
        if (this.currentIntroContent && !this.introLevelComplete) {
          this.$emit('next-content') // handled by vue IntroLevelPage
        } else if (this.charCxModal && this.nextLevelLink) {
          this.showCharCx = true
        } else if (this.nextLevelLink) {
          return application.router.navigate(this.nextLevelLink, { trigger: true }, this.doReload)
        }
      },
      // PlayLevelView is a backbone view, so replay button dismisses modal for that
      // IntroLevelPage is vue component and handles the event `replay`
      replayButtonClick () {
        this.$emit('replay', this.currentIntroContent)
      },
      continueEditingButtonClick () {
        const capstoneLevelLinkOptions = {
          courseId: this.courseId,
          courseInstanceId: this.courseInstanceId,
          codeLanguage: this.codeLanguage
        }
        let capstoneLink = getNextLevelLink(this.editCapstoneLevelData, capstoneLevelLinkOptions) // if next level stage is not set, capstone is loaded from the last completed stage
        let capstoneLinkAppend = `?continueEditing=true`
        if (capstoneLink.split('?').length > 1) {
          capstoneLinkAppend = `&continueEditing=true`
        }
        capstoneLink += capstoneLinkAppend
        return application.router.navigate(capstoneLink, { trigger: true }, this.doReload)
      },
      copyUrl () {
        this.$refs['share-text-box'].select()
        tryCopy()
      },
      onCharCxSaved () {
        return application.router.navigate(this.nextLevelLink, { trigger: true }, this.doReload)
      }
    }
  })
</script>

<template>
  <base-modal
    v-if="!goToNextDirectly && !showCharCx"
    class="victory-modal"
  >
    <template #header>
      <div class="victory-header">
        <span class="text-capitalize status-text"> {{ contentType }} {{ $t("common.complete") }} </span>
        <span
          v-if="contentName"
          class="text-capitalize"
        > {{ contentName }} </span>
      </div>
    </template>

    <template #body>
      <div v-if="learningGoals && !shareModal">
        <span class="learning-goals"> {{ $t("play_level.learning_goals") }}:&nbsp; </span>
        <span>  {{ learningGoals }} </span>
      </div>

      <div
        v-else-if="shareModal"
        class="share-modal-body"
      >
        <span> {{ $t("play_level.share_your_project") }} </span>
        <span class="keep-editing-text"> {{ $t("play_level.keep_editing_your_project") }} </span>
        <input
          ref="share-text-box"
          readonly="true"
          type="text"
          class="ozaria-secondary-button share-text-box"
          :value="shareURL"
        >
        <div class="share-buttons">
          <button
            class="copy-url-button ozaria-button ozaria-primary-button"
            @click="copyUrl"
          >
            {{ $t("play_level.copy_url") }}
          </button>
        </div>
      </div>
    </template>

    <template #footer>
      <div class="victory-footer">
        <button
          v-if="shareModal"
          class="continue-editing-button ozaria-button ozaria-secondary-button"
          data-dismiss="modal"
          @click="continueEditingButtonClick"
        >
          {{ $t("common.continue_editing") }}
        </button>
        <button
          v-else
          class="replay-button ozaria-button ozaria-secondary-button"
          data-dismiss="modal"
          @click="replayButtonClick"
        >
          {{ $t("common.replay") }}
        </button>
        <!-- TODO: Button doesn't handle loading state -->
        <button
          class="next-button ozaria-button ozaria-primary-button"
          :disabled="nextLevelIsLocked"
          @click="nextButtonClick"
        >
          {{ nextLevelIsLocked ? $t("common.locked") : $t("common.next") }}
        </button>
      </div>
    </template>
  </base-modal>
  <modal-char-customization
    v-else-if="showCharCx"
    class="char-cx-modal"

    :showCancelButton="false"

    @saved="onCharCxSaved"
  />
</template>

<style lang="sass" scoped>
  .victory-header
    all: inherit
    flex-direction: column

    .status-text
      font-weight: normal
      font-size: 20px

  .learning-goals
    color: #1fbab4

  .share-modal-body
    display: flex
    flex-direction: column
    width: 100%
    .keep-editing-text
      font-size: 14px
      color: #a4a4a4
    .share-text-box
      height: 45px
      width: 100%
      margin-top: 5px
    .share-buttons
      width: 100%
      .copy-url-button
        margin-top: 10px
        width: auto
        float: right

  .victory-footer
    all: inherit
    justify-content: space-between
    padding: 0
    .replay-button
      width: 182px
    .next-button
      width: 182px
      &:disabled
        background-color: #adadad
</style>
