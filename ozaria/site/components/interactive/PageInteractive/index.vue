<script>
  import { getInteractive, getSession } from '../../../api/interactive'
  import draggableOrderingComponent from './draggableOrdering/index'
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

    data: () => ({
      interactive: {},
      interactiveSession: {},
      interactiveType: ''
    }),

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
        try {
          this.interactive = await getInteractive(this.interactiveIdOrSlug)
          this.interactiveType = this.interactive.interactiveType
          if (!this.interactiveType) {
            return Promise.reject('Interactive type is not set for the interactive ' + this.interactiveIdOrSlug)
          }
          if (!me.isSessionless()) { // not saving progress/session for teachers
            const getSessionOptions = {
              introLevelId: this.introLevelId,
              courseInstanceId: this.courseInstanceId
            }
            this.interactiveSession = await getSession(this.interactiveIdOrSlug, getSessionOptions )
          }
        } catch (err) {
          console.error('Error:', err)
          return noty({ text: 'Error occured in creating interactives data.', type: 'error', timeout: '2000' })
        }
      }
    }
  })
</script>

<template>
  <draggable-statement-completion
   v-if="false"
   :interactive="interactive"
   :introLevelId="introLevelId"
   :interactiveSession="interactiveSession"
   :courseInstanceId="courseInstanceId"
   @completed="onCompleted"
  />

  <draggable-ordering
    v-else-if="true"
    :interactive="interactive"
    :introLevelId="introLevelId"
    :interactiveSession="interactiveSession"
    :courseInstanceId="courseInstanceId"
    @completed="onCompleted"
  />

  <insert-code
    v-else-if="false"
    :interactive="interactive"
    :introLevelId="introLevelId"
    :interactiveSession="interactiveSession"
    :courseInstanceId="courseInstanceId"
    @completed="onCompleted"
  />
</template>

<style scoped>

</style>

