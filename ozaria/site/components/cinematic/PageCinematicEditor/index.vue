<script>
import { getCinematic, putCinematic, createCinematic, getAllCinematics } from '../../../api/cinematic'
import Cinematic from '../../../models/Cinematic'
import ListItem from '../../common/BaseListItem'
import CinematicCanvas from '../common/CinematicCanvas'
import CocoCollection from 'app/collections/CocoCollection'
const api = require('core/api')

require('lib/setupTreema')

module.exports = Vue.extend({
  props: {
    slug: String
  },
  data: () => ({
    cinematic: null,
    treema: null,
    cinematicList: null,
    rawData: null,
    state: {
      saving: false
    },
    rerenderKey: 0,
    cinematicSlug: '',
    programmingLanguage: 'python'
  }),
  components: {
    'editor-list': ListItem,
    'cinematic-canvas': CinematicCanvas
  },
  mounted () {
    if (!me.hasCinematicEditorAccess()) {
      alert('You must be logged in as an admin to use this page.')
      return application.router.navigate('/editor', { trigger: true })
    }

    if (this.slug)  {
      this.cinematicSlug = this.slug
    }
    if (this.cinematicSlug) {
      this.fetchCinematic(this.cinematicSlug)
    } else {
      this.fetchList()
    }
  },
  methods: {
    /**
     * Fetch and populate treema with cinematic slug.
     */
    async fetchCinematic(slug) {
      this.cinematicList = null
      try {
        this.cinematic = new Cinematic(await getCinematic(slug))
      } catch (e) {
        return noty({
          text: `Error finding slug '${slug}'.`,
          type:'error',
          timeout: 3000,
          callback: {
            onClose: () => {
              application.router.navigate('/editor/cinematic', { trigger: true })
            }
          }
        })
      }
      const c = this.cinematic
      const data = $.extend(true, {}, c.attributes)
      const el = $(`<div></div>`);
      const files = new CocoCollection(await api.files.getDirectory({path: 'cinematic'}), { model: Cinematic })
      const treema = this.treema = TreemaNode.make(el, {
        data: data,
        schema: Cinematic.schema,
        // Automatically uploads the file to /file/cinematic/<fileName>
        // You can view files at /admin/files
        filePath: 'cinematic',
        files,
        callbacks: {
          change: this.pushChanges
        }
      })
      treema.build()
      $(this.$refs.treemaEditor).append(el)
    },
    /**
     * Fetch all names and slugs of cinematics from the database.
     * Clears the slug.
     */
    async fetchList () {
      this.cinematicSlug = ''
      this.cinematic = null
      this.treema = null
      this.rawData = null
      this.cinematicList = await getAllCinematics();
    },
    /**
     * Pushes changes from treema to the cinematic model.
     */
    pushChanges() {
      this.cinematic.set(_.cloneDeep(this.treema.data))
    },

    /**
     * Ensures that there is an empty `i18n` field set on the cinematic.
     * Allows fields to be translated via /i18n route.
     */
    makeTranslatable () {
      if (!(this.treema || {}).data) {
        noty({ text: 'Nothing to translate', timeout: 1000 })
        return
      }

      if (!window.confirm("This will populate any missing i18n fields so that cinematics can be translated. Do you want to continue?")) {
        noty({ text: 'Cancelled', timeout: 1000 })
        return
      }

      const cinematicData = this.treema.data;

      const i18n = cinematicData.i18n
      if (i18n === undefined) {
        cinematicData.i18n = {"-": { "-": "-" }}
      }

      const shots = cinematicData.shots || []
      for (const shot of shots) {
        const dialogNodes = shot.dialogNodes || []
        for (const dialogNode of dialogNodes) {
          const i18n = dialogNode.i18n
          if ((!i18n) && dialogNode.text) {
            dialogNode.i18n = {"-": { "-": "-" }}
          }
        }
      }

      noty({ text: 'Translations added. Please save to keep changes', type:"success", timeout: 8000 })
      this.pushChanges()
    },

    /**
     * Saves the cinematic to the database.
     * Only the shots property will be saved.
     */
    async saveCinematic() {
      this.state.saving = true
      try {
        await putCinematic({ data: this.cinematic.toJSON() })
        noty({ text: 'Saved', type: 'success', timeout: 1000 })
      } catch (e) {
        noty({ text: e.message, type: 'error', timeout: 1000 })
      }
      this.state.saving = false
    },

    /**
     * Runs the cinematic on the right hand side of the editor.
     */
    runCinematic() {
      this.rerenderKey += 1;
      this.rawData = this.rawData || {}
      this.rawData.shots = JSON.parse(JSON.stringify(this.treema.data.shots))
    },

    async createCinematic() {
      const name = window.prompt("Name of new cinematic?")
      if (!name) { return }

      const result = await createCinematic({ name })
      return this.fetchList()
    },

  },
  computed: {
    heading: function() {
      if (!this.cinematic) {
        return "Cinematic Editor"
      }
      return `Cinematic Editor: '${this.cinematic.get('name')}'`
    }
  }
})
</script>

<template>
  <div class="container">
    <div v-if="!cinematic">
      <div class="row">
        <div class="col-md-12"><h1>{{ heading }}</h1></div>
      </div>
      <div class="row">
        <!-- List of cinematics -->
        <div class="container">
          <div class="row headings">
            <div class="col-xs-4">
              <h2>Name</h2>
            </div>
            <div class="col-xs-4">
              <h2>Slug</h2>
            </div>
            <div class="col-xs-4">
              <h2>Id</h2>
            </div>
          </div>
          <editor-list
            v-for="cinematic in cinematicList"
            :key="cinematic.slug"
            :text="cinematic.name + (cinematic.displayName ? `\t\t| ${cinematic.displayName}` : '')"
            :slug="cinematic.slug"
            :id="cinematic._id"
            :clickHandler="() => fetchCinematic(cinematic.slug)"
            ></editor-list>
            <li><button v-on:click="createCinematic">+</button></li>
        </div>
        
      </div>
    </div>

    <div v-else>
      <!-- Have a cinematic Slug -->
      <div class="row">
        <div class="col-md-8"><h1>{{ heading }}</h1></div>
        <div class="col-md-4">
          <span>There is no autosave.</span>
          <button v-on:click="saveCinematic" :disabled="state.saving || !cinematic">save</button>
          <button v-on:click="runCinematic">Test Cinematic</button>
          <button><a v-on:click="fetchList">Back to list view</a></button>
          <button v-on:click="makeTranslatable">Make Translatable</button>
        </div>
      </div>

      <div class="row">
        <div class="col-md-6">
          <label>User Language:</label><select v-model="programmingLanguage">
            <option>python</option>
            <option>javascript</option>
          </select>
          <div id="treema-editor" ref="treemaEditor" v-once></div>
        </div>
        <div class="col-md-6" v-if="rawData" style="width:1366px; height:768px;">
          <cinematic-canvas :cinematicData="rawData" :key="rerenderKey" :userOptions="{ programmingLanguage }" />
        </div>
      </div>

    </div>
  </div>
</template>

<style scoped>
  .container {
    margin-top: 30px;
    background-color: white;
    padding: 20px;
  }
  button {
    margin: 5px;
    padding: 5px;
  }

  .list-item:nth-child(odd) {
    background-color: #f2f2f2;
  }

  .headings {
    border-bottom: 2px solid #dddddd;
    margin-bottom: 20px
  }

</style>
