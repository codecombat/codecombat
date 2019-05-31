<script>

import { getInteractive, getSession } from '../../../api/interactive'
import draggableOrderingComponent from './draggableOrdering'
import insertCodeComponent from './insertCode'
import draggableStatementCompletionComponent from './draggableStatementCompletion'

module.exports = Vue.extend({
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
      type: String
    }
  },
  data: () => ({
    interactive: {},
    interactiveSession: {},
    interactiveType: '',
    dataLoaded: false
  }),
  components: {
    'draggable-ordering': draggableOrderingComponent,
    'insert-code': insertCodeComponent,
    'draggable-statement-completion': draggableStatementCompletionComponent
  },
  watch : {
    interactiveIdOrSlug: async function() {
      await this.getInteractiveData()
    }
  },
  async created() {
    if (!me.hasInteractiveAccess()) {
      alert('You must be logged in as an admin to use this page.')
      return application.router.navigate('/', { trigger: true })
    }
    await this.getInteractiveData()
    this.dataLoaded = true
  },
  methods: {
    onCompleted() {
      this.$emit('completed')
    },
    async getInteractiveData() {
      try {
        this.interactive = await getInteractive(this.interactiveIdOrSlug)
        this.interactiveType = this.interactive.interactiveType
        if (!this.interactiveType) {
          return Promise.reject("Interactive type is not set for the interactive " + this.interactiveIdOrSlug)
        }
        if (!me.isSessionless()) { // not saving progress/session for teachers
          const getSessionOptions = {
            introLevelId: this.introLevelId,
            courseInstanceId: this.courseInstanceId
          }
          this.interactiveSession = await getSession(this.interactiveIdOrSlug, getSessionOptions )
        }
      } catch (err) {
        console.error("Error:", err)
        return noty({ text: 'Error occured in creating interactives data.', type: 'error', timeout: '2000' })
      }
    }
  }
})
</script>

<template>
  <div v-if="dataLoaded">
    <draggable-ordering
      v-if="interactiveType == 'draggable-ordering'"
      :interactive="interactive"
      :introLevelId="introLevelId"
      :interactiveSession="interactiveSession"
      :courseInstanceId="courseInstanceId"
      v-on:completed="onCompleted">
    </draggable-ordering>
    <insert-code
      v-else-if="interactiveType == 'insert-code'"
      :interactive="interactive"
      :introLevelId="introLevelId"
      :interactiveSession="interactiveSession"
      :courseInstanceId="courseInstanceId"
      v-on:completed="onCompleted">
    </insert-code>
    <draggable-statement-completion
      v-else-if="interactiveType == 'draggable-statement-completion'"
      :interactive="interactive"
      :introLevelId="introLevelId"
      :interactiveSession="interactiveSession"
      :courseInstanceId="courseInstanceId"
      v-on:completed="onCompleted">
    </draggable-statement-completion>
  </div>
</template>

<style scoped>

</style>


