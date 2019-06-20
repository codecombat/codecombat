<script>
  import { getInteractive, putInteractive, postInteractive, getAllInteractives } from '../../../api/interactive'
  import Interactive from '../../../models/Interactive'
  import ListItem from '../../common/BaseListItem'
  import Ajv from 'ajv'
  import { getAjvOptions } from 'ozaria/site/common/ozariaUtils'

  require('lib/setupTreema')

  module.exports = Vue.extend({
    components: {
      'list-item': ListItem
    },
    props: {
      slug: {
        type: String,
        default: ''
      }
    },
    data: () => ({
      interactive: null,
      treema: null,
      interactiveList: null,
      valid: true,
      state: {
        saving: false
      },
      interactiveSlug: ''
    }),
    computed: {
      heading: function () {
        if (this.interactiveSlug && this.interactive) {
          return `Interactive Editor: '${this.interactive.get('name')}'`
        }
        return 'Interactive Editor'
      }
    },
    async created () {
      if (!me.hasInteractiveAccess()) {
        alert('You must be logged in as an admin to use this page.')
        return application.router.navigate('/editor', { trigger: true })
      }
      console.log(`Got the slug: ${this.slug}`)
      this.interactiveSlug = this.slug
      if (this.interactiveSlug) {
        await this.fetchInteractive(this.interactiveSlug)
      } else {
        await this.fetchList()
      }
    },
    methods: {
      /**
       * Fetch and populate treema with interactive slug.
       * Clears the list
       */
      async fetchInteractive (slug) {
        this.interactiveList = null
        this.interactiveSlug = slug
        try {
          this.interactive = new Interactive(await getInteractive(slug))
        } catch (e) {
          noty({ text: `Error finding slug '${slug}'.`, type: 'error', timeout: 2000 })
          return this.fetchList()
        }
        const data = $.extend(true, {}, this.interactive.attributes)
        const el = $(`<div></div>`)
        const treemaOptions = {
          data: data,
          schema: Interactive.schema,
          // Automatically uploads the file to /file/interactives/<fileName>
          // You can view files at /admin/files
          filePath: 'interactives',
          callbacks: {
            change: this.onTreemaChanged
          }
        }
        const treema = this.treema = TreemaNode.make(el, treemaOptions)
        treema.build()
        $(this.$refs.treemaEditor).append(el)
      },

      /**
       * Fetch all names and slugs of interactives from the database.
       * Clears the slug and treema.
       */
      async fetchList () {
        this.interactive = null
        this.interactiveSlug = ''
        this.treema = null
        $(this.$refs.treemaEditor).children().remove()
        try {
          this.interactiveList = await getAllInteractives()
        } catch (e) {
          console.error('Error while fetching the interactive list:', e)
          noty({ text: 'Error occured while fetching the interactive list', type: 'error', timeout: 2000 })
        }
      },

      /**
       * Performs schema validation and pushes changes from treema to the interactive model.
       */
      onTreemaChanged () {
        const ajv = new Ajv(getAjvOptions())
        const data = this.treema.data
        this.valid = ajv.validate(Interactive.schema, data)
        if (this.valid) {
          this.interactive.set(data)
        } else {
          console.error('Schema validation error', ajv.errors)
          noty({
            text: 'Schema validation error. Please check the console for errors.',
            type: 'error',
            timeout: 2000
          })
        }
      },

      /**
       * Saves the properties of the interactive to the database.
       */
      async saveInteractive () {
        if (!this.valid) {
          noty({
            text: `Cant save since the schema is not valid.`,
            type: 'error',
            timeout: 2000
          })
          return
        }
        this.state.saving = true
        try {
          const interactiveData = this.interactive.toJSON()
          if (!interactiveData.unitCodeLanguage) {
            console.error('Programming language is required to save the interactive')
            noty({ text: 'Cannot save the interactive without programming language', type: 'error', timeout: 2000 })
          } else {
            this.interactive = new Interactive(await putInteractive({ data: interactiveData }))
            this.treema.set('/', $.extend(true, {}, this.interactive.attributes))
            noty({ text: 'Saved', type: 'success', timeout: 2000 })
          }
        } catch (e) {
          console.error('Error while saving the interactive', e)
          noty({ text: 'Error occured while saving the interactive', type: 'error', timeout: 2000 })
        }
        this.state.saving = false
      },

      /**
       * Creates a new interactive in the database.
       */
      async createInteractive () {
        const name = window.prompt('Name of new interactive?')
        if (!name) { return }
        try {
          await postInteractive({ name })
          return this.fetchList()
        } catch (e) {
          console.error('Error:', e)
          noty({ text: 'Cannot create interactive. Please check the console for errors.', type: 'error', timeout: 2000 })
        }
      }

    }
  })
</script>

<template>
  <div class="container">
    <div v-if="!interactiveSlug">
      <div class="row">
        <div class="col-md-12">
          <h1>{{ heading }}</h1>
        </div>
      </div>
      <div class="row">
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
        <list-item
          v-for="int in interactiveList"
          :id="int._id"
          :key="int.slug"
          :text="int.name"
          :slug="int.slug"
          :click-handler="() => fetchInteractive(int.slug)"
        />
        <li>
          <button @click="createInteractive">
            +
          </button>
        </li>
      </div>
    </div>

    <div v-else>
      <div class="row">
        <div class="col-md-8">
          <h1>{{ heading }}</h1>
        </div>
        <div class="col-md-4">
          <span>There is no autosave. Please click this button often.</span>
          <button
            :disabled="state.saving || !interactive"
            @click="saveInteractive"
          >
            save
          </button>
          <button><a @click="fetchList()">Back to list view</a></button>
        </div>
      </div>
      <div class="row">
        <div class="col-md-12">
          <p style="padding-top:20px">
            NOTE: Please save the data for interactives before adding the solution.
          </p>
          <div
            id="treema-editor"
            ref="treemaEditor"
          />
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
