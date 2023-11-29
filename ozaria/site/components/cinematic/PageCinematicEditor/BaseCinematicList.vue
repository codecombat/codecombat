<script>
import { createCinematic, getAllCinematics } from '../../../api/cinematic'
import ListItem from '../../common/BaseListItem'
const globalVar = require('core/globalVar')

module.exports = Vue.extend({
  components: {
    'editor-list': ListItem
  },

  data: () => ({
    cinematicList: null
  }),

  mounted () {
    if (!me.hasCinematicEditorAccess()) {
      alert('You must be logged in as an admin to use this page.')
      return application.router.navigate('/editor', { trigger: true })
    }
    this.fetchList()
  },

  methods: {
    /**
     * Fetch all names and slugs of cinematics from the database.
     * Clears the slug.
     */
    async fetchList () {
      this.cinematicList = await getAllCinematics()
    },

    async createCinematic () {
      const name = window.prompt('Name of new cinematic?')
      if (!name) { return }

      await createCinematic({ name })
      return this.fetchList()
    },

    navigateToCinematic (cinematicSlug) {
      return () => globalVar.application.router.navigate(`/editor/cinematic/${cinematicSlug}`, { trigger: true })
    }
  }
})
</script>

<template>
  <div class="container">
    <div class="row">
      <div class="col-md-12">
        <h1>
          Cinematic Editor
        </h1>
      </div>
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
          :id="cinematic._id"

          :key="cinematic.slug"
          :text="cinematic.name + (cinematic.displayName ? `\t\t| ${cinematic.displayName}` : '')"
          :slug="cinematic.slug"
          :click-handler="navigateToCinematic(cinematic.slug)"
        />
        <li>
          <button @click="createCinematic">
            +
          </button>
        </li>
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
