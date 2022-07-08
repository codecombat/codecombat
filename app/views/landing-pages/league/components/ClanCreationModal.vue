<script>
  import Modal from 'app/components/common/Modal'
  import Clan from 'models/Clan'

  export default Vue.extend({
    components: {
      Modal
    },
    props: {
      // If you want to edit an existing clan's name/description/type, pass it as a prop:
      clan: {
        type: Object,
        default: null
      }
    },
    data: () => ({
      name: '',
      description: '',
      isPublic: true
    }),

    mounted () {
      if (this.clan !== null) {
        this.name = this.clan.displayName || this.clan.name
        this.description = this.clan.description
        this.isPublic = this.clan.type === undefined ? true : this.clan.type === 'public'
      }
    },

    computed: {
      modalTitle() {
        if (this.clan === null) {
          return 'Create team'
        } else {
          return 'Edit team'
        }
      }
    },

    methods: {
      async submit () {
        if (!this.isPublic && !me.isPremium()) {
          noty({ type: 'error', text: 'Must be a subscriber to create private teams', timeout: 3000 })
          return
        } else if (this.name.length < 2) {
          noty({ type: 'error', text: 'Must have at least 2 letters for the team name', timeout: 3000 })
          return
        }

        if (this.clan) {
          await this.updateClan()
        } else {
          await this.createNewClan()
        }
      },
      async createNewClan () {
        try {
          // NOTE: Would prefer to move these to Vuex, keeping it simple for now:
          const clan = new Clan()
          clan.set('type', this.isPublic ? 'public' : 'private')
          clan.set('name', this.name)
          clan.set('description', this.description)
          clan.set('displayName', this.name)
          // Assume this will fail if the clan name exists
          const savedClan = await clan.save({})

          this.$emit('close')
          application.router.navigate(`/league/${savedClan._id}`, { trigger: true })
        } catch (e) {
          if (e.errorName === 'Conflict' || e.code === 409) {
            noty({ type: 'error', text: 'Team name already exists', timeout: 3000 })
            return
          } else {
            throw e
          }
        }
      },

      async updateClan () {
        try {
          const clan = new Clan(this.clan)
          // TODO: Cannot edit privacy from client side
          // clan.set('type', this.isPublic ? 'public' : 'private')
          clan.set('displayName', this.name)
          clan.set('description', this.description)

          await clan.save({})
          this.$emit('close')
          document.location.reload()
        } catch (e) {
          if (e.errorName === 'Conflict' || e.code === 409) {
            noty({ type: 'error', text: 'Team name already exists', timeout: 3000 })
            return
          } else {
            throw e
          }
        }
      }

    }
  })
</script>

<template>
  <modal @close="$emit('close')" :title="modalTitle" id="clan-creation-modal">
    <div class="container">
      <div>
        <label for="input-name">Team name:</label>
        <input id="input-name" type="text" v-model="name" />
      </div>

      <div>
        <label for="input-description">Description:</label>
        <textarea id="input-description" type="text" rows=2 v-model="description" />
      </div>

      <div v-if="!clan">
        <label for="input-is-public">Public:</label>
        <input id="input-is-public" type="checkbox" v-model="isPublic" />
      </div>

      <button @click.prevent="submit">{{ modalTitle }}</button>
    </div>
  </modal>
</template>

<style scoped>
#clan-creation-modal label {
  color: black;
  min-width: 20%;
  padding-right: 20px;
  margin-bottom: 10px;
}

#clan-creation-modal .container > div {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

</style>
