<script>
import CocoCollection from 'app/collections/CocoCollection'
import { getClan } from 'core/api/clans'
import Clan from 'app/models/Clan'
const api = require('core/api')
require('lib/setupTreema')

export default {
  data: () => ({
    clan: null,
    treema: null
  }),

  async mounted () {
      if (!me.isAdmin()) {
        alert('You must be logged in as an admin to use this page.')
        return application.router.navigate('/', { trigger: true })
      }
      this.clan = await getClan(this.$route.params.clanId)
    
      const data = $.extend(true, {}, this.clan)
      const el = $(`<div></div>`)
      const files = new CocoCollection(await api.files.getDirectory({ path: `clan/${this.clan._id}` }), { model: Clan })

      const treema = this.treema = TreemaNode.make(el,
      {
        data: data,
        schema: Clan.schema,
        // Automatically uploads the file to /file/clan/<clanId>/<fileName>
        // You can view files at /admin/files
        // clan _id ensures we don't overwrite another clans image.
        filePath: `clan/${this.clan._id}`,
        files
      })
      treema.build()
      $(this.$refs.treemaEditor).append(el)
    },

    methods: {
      /**
       * Pushes changes from treema to the cinematic model.
       */
      async saveChanges () {
        this.clan = _.cloneDeep(this.treema.data)
        const clan = new Clan(this.clan)
        clan.validate()
        console.log({ clan })
        if (confirm("Are you sure you want to save these changes?")) {
          await clan.save()
          noty({text: "Clan save successful", layout: 'topCenter', type: 'success'})
        }
      },
    }
}
</script>

<template>
  <div>
    <h1>Internal Admin Team/Clan edit tool</h1>

    <p>Search for school and district <a href="/admin/clan">clans here.</a></p>
    <div v-if="clan !== null">
      <p>This internal tool lets admin and internal accounts customize teams.
        For engineers - 'team' refers to a 'clan' in the code and database.
        Use the tool for:
      </p>
      <ul>
        <li>censoring a name or description on a team</li>
        <li>changing or adding an owner user to a team</li>
        <li>adding a custom image for a team</li>
        <li>editing any other data of a team</li>
      </ul>

      <p><a :href="`/league/${clan.slug}`">Esports page</a></p>
      <p><a :href="`/clan/${clan.slug}`">Legacy clan page</a></p>

      <h2>Clan Stats</h2>
      <ul>
        <li>{{(clan.members || []).length}} members</li>
      </ul>

      <div
            v-once
            id="treema-editor"
            ref="treemaEditor"
      ></div>
      <button @click="saveChanges">Save Changes</button>
    </div>
    <div v-else>
      Loading...
    </div>
  </div>
</template>
