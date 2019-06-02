<script>
  import { merge } from 'lodash'
  import { mapGetters, mapActions } from 'vuex'

  import draggableOrderingComponent from './draggableOrdering'
  import insertCodeComponent from './insertCode'
  import draggableStatementCompletionComponent from './draggableStatementCompletion'

  module.exports = Vue.extend({
    components: {
      'draggable-ordering': draggableOrderingComponent,
      'insert-code': insertCodeComponent,
      'draggable-statement-completion': draggableStatementCompletionComponent
    },

    props: {
      interactiveIdOrSlug: {
        type: String,
        required: true,
        default: ''
      },

      introLevelId: {
        type: String,
        required: true,
        default: ''
      },

      courseInstanceId: {
        type: String,
        default: undefined
      }
    },

    computed: {
      ...mapGetters('interactives', [
        'currentInteractiveDataLoading',
        'currentInteractive',
        'currentInteractiveSession'
      ]),

      interactiveConfig () {
        switch (this.currentInteractive.interactiveType) {
        case 'draggable-statement-completion':
          return this.currentInteractive.draggableStatementCompletionData

        case 'insert-code':
          return this.currentInteractive.insertCodeData

        case 'draggable-ordering':
          return this.currentInteractive.draggableOrderingData

        default:
          noty({ text: 'Interactive type is not set for the interactive', type: 'error', timeout: '2000' })
          throw new Error('Invalid interactive type provided for interactive')
        }
      },

      localizedInteractiveConfig () {
        const interactiveConfigI18n = this.interactiveConfig.i18n || {}

        const userLocale = me.get('preferredLanguage', true) // TODO drive from store
        const userGeneralLocale = (userLocale || '').split('-')[0]
        const fallbackLocale = 'en'

        const userLocaleObject = interactiveConfigI18n[userLocale] || {}
        const generalLocaleObject = interactiveConfigI18n[userGeneralLocale] || {}
        const fallbackLocaleObject = interactiveConfigI18n[fallbackLocale] || {}

        return merge(
          {},
          this.interactiveConfig,
          fallbackLocaleObject,
          generalLocaleObject,
          userLocaleObject
        )
      },

      interactiveComponent () {
        switch (this.currentInteractive.interactiveType) {
        case 'draggable-statement-completion':
          return draggableStatementCompletionComponent

        case 'insert-code':
          return insertCodeComponent

        case 'draggable-ordering':
          return draggableOrderingComponent

        // TODO duplicate implmentation of this above - improve
        default:
          noty({ text: 'Interactive type is not set for the interactive', type: 'error', timeout: '2000' })
          throw new Error('Invalid interactive type provided for interactive')
        }
      }
    },

    watch: {
      interactiveIdOrSlug: async function () {
        await this.getInteractiveData()
      }
    },

    async created () {
      if (!me.hasInteractiveAccess()) {
        alert('You must be logged in as an admin to use this page.')
        return application.router.navigate('/', { trigger: true })
      }

      await this.getInteractiveData()
    },

    methods: {
      ...mapActions('interactives', [
        'loadInteractive',
        'loadInteractiveSession'
      ]),

      onCompleted () {
        this.$emit('completed')
      },

      async getInteractiveData () {
        this.loading = true

        try {
          const interactivePromise = this.loadInteractive(this.interactiveIdOrSlug)
          const interactiveSessionPromise = this.loadInteractiveSession({
            interactiveIdOrSlug: this.interactiveIdOrSlug,
            sessionOptions: {
              introLevelId: this.introLevelId,
              courseInstanceId: this.courseInstanceId
            }
          })

          await interactivePromise
          await interactiveSessionPromise
        } catch (err) {
          console.error('Error:', err)
          return noty({ text: 'Error occured in creating interactives data.', type: 'error', timeout: '2000' })
        }
      }
    }
  })
</script>

<template>
  <div class="interactive-container">
    <h1 v-if="currentInteractiveDataLoading">
      LOADING
    </h1>

    <component
      :is="interactiveComponent"
      v-else
      :interactive="currentInteractive"
      :localized-interactive-config="localizedInteractiveConfig"
      :intro-level-id="introLevelId"
      :interactive-session="currentInteractiveSession"
      :course-instance-id="courseInstanceId"
      @completed="onCompleted"
    />
  </div>
</template>

<style scoped>
  .interactive-container {
    background-color: #FFF;
  }
</style>
