<script>
  import Modal from 'app/components/common/Modal'

  export default Vue.extend({
    components: {
      Modal
    },
    props: {
      firstName: {
        type: String
      },
      lastName: {
        type: String
      },
      name: {
        type: String
      },
      email: {
        type: String
      },
      age: {
        type: Number
      },
      emails: {
        type: Object
      }
    },
    mounted () {
      this.userUpdates = _.pick(this, ['firstName', 'lastName', 'name', 'email', 'age', 'emails'])

      // Marketing consent is mandatory for league sign ups:
      const consent = { enabled: false }
      if (!this.userUpdates.emails) {
        this.userUpdates.emails = { generalNews: consent }
      } else if (!(this.userUpdates.emails || {}).generalNews) {
        this.userUpdates.emails.generalNews = consent
      }
    },
    data: () => ({
      userUpdates: { emails: { generalNews: { enabled: false } } }
    }),
    methods: {
      submit () {
        if (!this.canSubmit) {
          // How did we even get here?
          noty({ type: 'error', text: 'Must consent to sign up' })
          return
        }

        this.userUpdates.emails.generalNews.enabled = true // TODO: Handle mapping true to the 1 or 0 from a checkbox better
        this.$emit('submit', _.pick(this.userUpdates, ['firstName', 'lastName', 'name', 'email', 'age', 'emails']))
        this.$emit('close')
      }
    },
    computed: {
      canSubmit () {
        // TODO: Check age?
        return (this.userUpdates.emails.generalNews || {}).enabled
      }
    }
  })
</script>

<template>
  <modal title="Register">
    <div class="container">
      <h1>This could use some design love... :)</h1>

      <div>
        <label for="input-firstname">First name:</label>
        <input id="input-firstname" type="text" v-model="userUpdates.firstName" />
      </div>

      <div>
        <label for="input-lastname">Last name:</label>
        <input id="input-lastname" type="text" v-model="userUpdates.lastName" />
      </div>

      <div>
        <label for="input-username">Username: </label>
        <input id="input-username" type="text" v-model="userUpdates.name" />
      </div>

      <div>
        <label for="input-email">Email: </label>
        <input id="input-email" type="email" v-model="userUpdates.email" />
      </div>

      <div>
        <label for="input-consent">Consent to receive emails:</label>
        <input id="input-consent" type="checkbox" v-model="userUpdates.emails.generalNews.enabled" />
      </div>

      <p style="color: red; font-size: 30px;" v-show="!canSubmit">
        Leagues require marketing consent
      </p>

      <button @click.prevent="submit" :disabled="!canSubmit">Register</button>
    </div>
  </modal>
</template>

<style lang="scss" scoped>
@import "app/styles/style-flat-variables";
@import "app/styles/core/variables";

// These types of buttons could be shared better
.btn-primary.btn-moon {
  background-color: $moon;
  border-radius: 1px;
  color: $gray;
  text-shadow: unset;
  font-weight: bold;
  @include font-h-5-button-text-black;
  min-width: 260px;
  padding: 15px 0;
  background-image: unset;
  margin: 0 15px;

  &:hover {
    @include font-h-5-button-text-white;
    background-color: $goldenlight;
    transition: background-color .35s;
  }
}
</style>
