<script>
import { getAllCutscenes, createCutscene } from '../../../api/cutscene'
import ListItem from '../../common/BaseListItem'
module.exports = Vue.extend({
  data: () => ({
    cutscenes: []
  }),
  components: {
    'editor-list': ListItem
  },
  mounted: function() {
    if (!me.hasCutsceneAccess()) {
      alert('You must be logged in as an admin to use this page.')
      return application.router.navigate('/editor', { trigger: true })
    }
    this.fetchList()
  },
  methods: {
    async fetchList () {
      try {
        this.cutscenes = await getAllCutscenes()
      } catch (e) {
        noty({ text: e.message, type: 'error', timeout: 3000 })
        console.error(e)
      }
    },
    async createCutscene () {
      const name = window.prompt("Name of new cutscene?")
      if (!name) { return }

      const result = await createCutscene({ name })
      return this.fetchList()
    },
    onClickCutscene (slugOrId) {
      application.router.navigate(`/editor/cutscene/${slugOrId}`, { trigger: true })
    }
  }
})
</script>

<template>
<div class="container">
  <div class="row">
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
        v-for="cutscene in cutscenes"
        :key="cutscene.slug"
        :text="cutscene.name"
        :slug="cutscene.slug"
        :id="cutscene._id"
        :clickHandler="() => onClickCutscene(cutscene.slug)"
        ></editor-list>
        <li><button v-on:click="createCutscene">+</button></li>
    </div>
  </div>
</div>
</template>


<style scoped lang="sass">
.container
  margin-top: 30px
  background-color: white
  padding: 20px

button
  margin: 5px
  padding: 5px


.list-item:nth-child(odd)
  background-color: #f2f2f2


.headings
  border-bottom: 2px solid #dddddd
  margin-bottom: 20px

</style>
