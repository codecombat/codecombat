
<script>
import Cutscene from '../../../models/Cutscene'
import { getCutscene, putCutscene } from '../../../api/cutscene'
require('lib/setupTreema')
export default {
  props: {
    slugOrId: {
      type: String,
      required: true
    }
  },
  data: () => ({
    cutscene: null,
    state: {
      saving: false
    }
  }),
  mounted: function() {
    if (!me.hasCutsceneAccess()) {
      alert('You must be logged in as an admin to use this page.')
      return application.router.navigate('/editor', { trigger: true })
    }
    this.loadTreema(this.slugOrId)
  },
  methods: {
    async loadTreema(slugOrId) {
      try {
        this.cutscene = new Cutscene(await getCutscene(slugOrId))
      } catch (e) {
        return noty({
          text: `Error finding slug '${slugOrId}'.`,
          type:'error',
          timeout: 3000,
          callback: {
            onClose: () => {
              application.router.navigate('/editor/cutscene', { trigger: true })
            }
          }
        })
      }
      const c = this.cutscene
      const data = $.extend(true, {}, c.attributes)
      const el = $(`<div></div>`);
      const treema = this.treema = TreemaNode.make(el, {
        data: data,
        schema: Cutscene.schema,
        callbacks: {
          change: this.onTreemaChange
        }
      })
      treema.build()
      $(this.$refs.treemaEditor).append(el)
    },

    onTreemaChange() {
      this.cutscene.set(this.treema.data)
    },

    async saveCutscene () {
      this.state.saving = true
      try {
        await putCutscene({ data: this.cutscene.toJSON() })
        noty({ text: 'Saved', type: 'success', timeout: 1000 })
      } catch (e) {
        noty({ text: e.message, type: 'error', timeout: 1000 })
      }
      this.state.saving = false
    },

    watchCutscene () {
      application.router.navigate(`/cutscene/${this.cutscene.get('slug')}`, { trigger: true })
    }
  }
}
</script>

<template>

<div class="container">
  <div class="row">
    <div class="col-md-8"><h1>Cutscene: '{{slugOrId}}'</h1></div>
    <div class="col-md-4">
      <button v-on:click="saveCutscene" :disabled="state.saving || !cutscene">save</button>
      <button v-on:click="watchCutscene">Watch Cutscene</button>
      <button><a href="/editor/cutscene">Back to list view</a></button>
    </div>
  </div>
  <div id="treema-editor" ref="treemaEditor" v-once></div>
</div>

</template>

<style>

</style>
