
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
    treema: null,
    state: {
      saving: false
    }
  }),
  mounted: function() {
    if (!me.hasCutsceneEditorAccess()) {
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
        filePath: 'cutscene',
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
    },

    /**
     * Ensures that there is an empty `i18n` field set on the cutscene.
     * Allows fields to be translated via /i18n route.
     */
    makeTranslatable () {
      if (!(this.treema || {}).data) {
        noty({ text: 'Nothing to translate', timeout: 1000 })
        return
      }

      if (!window.confirm('This will populate any missing i18n fields so that cutscene can be translated. Do you want to continue?')) {
        noty({ text: 'Cancelled', timeout: 1000 })
        return
      }

      const cutsceneData = this.treema.data;
      const i18n = cutsceneData.i18n
      if (i18n === undefined) {
        cutsceneData.i18n = { '-': { '-': '-' } }
      }

      noty({ text: 'Translations added. Please save to keep changes', type: 'success', timeout: 8000 })
      this.onTreemaChange()
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
      <button @click="makeTranslatable">Make Translatable</button>
    </div>
  </div>
  <div id="treema-editor" ref="treemaEditor" v-once></div>
</div>

</template>

<style>

</style>
