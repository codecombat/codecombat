<script>
  import { getInteractive, getSession } from '../../../api/interactive'
  import draggableOrderingComponent from './draggableOrdering/index'
  import insertCodeComponent from './insertCode/index'
  import draggableStatementCompletionComponent from './draggableStatementCompletion/index'
  import { defaultCodeLanguage } from 'ozaria/site/common/ozariaUtils'

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

    data: () => ({
      loading: false,
      interactive: {},
      interactiveSession: {},
      interactiveType: ''
    }),

    computed: {
      interactiveComponent () {
        switch (this.interactive.interactiveType) {
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
      onCompleted () {
        this.$emit('completed')
      },

      async getInteractiveData () {
        this.loading = true

        try {
          this.interactive = await getInteractive(this.interactiveIdOrSlug)
          this.interactiveType = this.interactive.interactiveType
          if (!this.interactiveType) {
            return Promise.reject('Interactive type is not set for the interactive ' + this.interactiveIdOrSlug)
          }
          if (!me.isSessionless()) { // not saving progress/session for teachers
            const getSessionOptions = {
              codeLanguage: this.codeLanguage
            }
            // TODO: throws error regarding intro and language session
            this.interactiveSession = await getSession(this.interactiveIdOrSlug, getSessionOptions)
          }
        } catch (err) {
          console.error('Error:', err)
          return noty({ text: 'Error occured in creating interactives data.', type: 'error', timeout: '2000' })
        } finally {
          this.loading = false
        }
      }
    }
  })
</script>

<template>
  <div class="interactive-container">
    <h1 v-if="loading">
      LOADING
    </h1>

    <component
      :is="interactiveComponent"
      v-else
      :interactive="interactive"
      :interactive-session="interactiveSession"
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
