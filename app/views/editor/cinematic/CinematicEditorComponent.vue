<template>
  <div class="container">
    <div v-if="!cinematicSlug">
      <div class="row">
        <div class="col-md-12"><h1>{{ heading }}</h1></div>
      </div>
      <div class="row">
        <!-- List of cinematics -->
        <ul>
          <editor-list
            v-for="cinematic in cinematicList"
            :key="cinematic.slug"
            :text="cinematic.name"
            :slug="cinematic.slug"
            ></editor-list>
            <li><button v-on:click="createCinematic">+</button></li>
        </ul>
        
      </div>
    </div>

    <div v-else>
      <!-- Have a cinematic Slug -->
      <div class="row">
        <div class="col-md-8"><h1>{{ heading }}</h1></div>
        <div class="col-md-4">
          <span>There is no autosave. Please click this button often.</span>
          <button v-on:click="saveCinematic" :disabled="state.saving || !cinematic">save</button>
          <button v-on:click="runCinematic">Test Cinematic</button>
          <button><a href="/cinematic">Play View (please save first)</a></button>
        </div>
      </div>

      <div class="row">
        <div class="col-md-6">
          <div id="treema-editor" ref="treemaEditor" v-once></div>
        </div>
        <div class="col-md-6" v-if="rawData">
          <cinematic-canvas :cinematicData="rawData" :key="rerenderKey" />
        </div>
      </div>

    </div>
  </div>
</template>

<script>
import { get, put, create, getAll } from 'core/api/cinematic'
import Cinematic from 'app/models/Cinematic'
import ListItem from 'app/components/cinematic/editor/ListItem'
import CinematicCanvas from 'app/views/CinematicCanvas'

require('lib/setupTreema')

module.exports = Vue.extend({
  props: {
    cinematicSlug: String
  },
  data: () => ({
    cinematic: null,
    treema: null,
    cinematicList: null,
    rawData: null,
    state: {
      saving: false
    },
    rerenderKey: 0
  }),
  components: {
    'editor-list': ListItem,
    'cinematic-canvas': CinematicCanvas
  },
  mounted () {
    if (!me.isAdmin()) {
      alert('You must be logged in as an admin to use this page.')
      return application.router.navigate('/editor', { trigger: true })
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
      try {
        this.cinematic = new Cinematic(await get(slug))
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
      const treema = this.treema = TreemaNode.make(el, {
        data: data,
        schema: Cinematic.schema,
        callbacks: {
          change: this.pushChanges
        }
      })
      treema.build()
      $(this.$refs.treemaEditor).append(el)
    },
    /**
     * Fetch all names and slugs of cinematics from the database.
     */
    async fetchList() {
      this.cinematicList = await getAll();
    },
    /**
     * Pushes changes from treema to the cinematic model.
     */
    pushChanges() {
      const shots = this.treema.data.shots
      this.cinematic.set('shots', shots)
    },

    /**
     * Saves the cinematic to the database.
     * Only the shots property will be saved.
     */
    async saveCinematic() {
      this.state.saving = true
      try {
      await put({ data: this.cinematic.toJSON() })
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
      this.rawData.shots = this.treema.data.shots
    },

    async createCinematic() {
      const name = window.prompt("Name of new cinematic?")
      if (!name) { return }

      const result = await create({ name })
      return this.fetchList()
    }
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
</style>
