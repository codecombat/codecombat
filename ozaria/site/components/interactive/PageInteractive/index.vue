<script>
  import { mapGetters, mapActions } from 'vuex'

  import draggableOrderingComponent from './draggableOrdering/index'
  import insertCodeComponent from './insertCode/index'
  import draggableStatementCompletionComponent from './draggableStatementCompletion/index'

  import {
    defaultCodeLanguage,
    internationalizeConfig
  } from 'ozaria/site/common/ozariaUtils'

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

      codeLanguage: {
        type: String,
        default: defaultCodeLanguage
      }
    },

    computed: {
      ...mapGetters('interactives', [
        'currentInteractiveDataLoading',
        'currentInteractive',
        'currentInteractiveSession'
      ]),

      ...mapGetters({
        userLocale: 'me/preferredLocale'
      }),

      interactiveConfig () {
        switch (this.currentInteractive.interactiveType) {
        case 'draggable-statement-completion':
          return this.currentInteractive.draggableStatementCompletionData
        case 'insert-code':
          return this.currentInteractive.insertCodeData
        case 'draggable-ordering':
          return this.currentInteractive.draggableOrderingData
        default:
          // TODO handle_error_ozaria
          noty({ text: 'Interactive type is not set for the interactive', type: 'error', timeout: '2000' })
          throw new Error('Invalid interactive type provided for interactive')
        }
      },

      localizedInteractiveConfig () {
        return internationalizeConfig(this.interactiveConfig, this.userLocale)
      },

      interactiveComponent () {
        switch (this.currentInteractive.interactiveType) {
        case 'draggable-statement-completion':
          return draggableStatementCompletionComponent

        case 'insert-code':
          return insertCodeComponent

        case 'draggable-ordering':
          return draggableOrderingComponent

        default:
          noty({ text: 'Interactive type is not set for the interactive', type: 'error', timeout: '2000' })
          throw new Error('Invalid interactive type provided for interactive')
        }
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
        try {
          const interactivePromise = this.loadInteractive(this.interactiveIdOrSlug)
          const interactiveSessionPromise = this.loadInteractiveSession({
            interactiveIdOrSlug: this.interactiveIdOrSlug,
            sessionOptions: {
              codeLanguage: this.codeLanguage
            }
          })

          await interactivePromise
          await interactiveSessionPromise
        } catch (err) {
          // TODO handle_error_ozaria
          console.error('Error:', err)
          return noty({ text: 'Error occured in fetching interactives data.', type: 'error', timeout: '2000' })
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
      :interactive-session="currentInteractiveSession"
      :code-language="codeLanguage"
      @completed="onCompleted"
    />
  </div>
</template>

<style scoped>
  .interactive-container {
    background-color: #FFF;
  }
</style>
