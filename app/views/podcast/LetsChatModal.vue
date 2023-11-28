<template>
  <modal
    title="Contact Details"
    @close="$emit('close')"
  >
    <form
      class="lets-chat-form"
      @submit.prevent="onFormSubmit"
    >
      <div class="form-group">
        <label for="name">Name</label>
        <input
          id="name"
          v-model="name"
          type="text"
          placeholder="Enter name"
          class="form-control"
        >
      </div>
      <div class="form-group">
        <label for="email">Email</label>
        <input
          id="email"
          v-model="email"
          type="email"
          placeholder="Enter email"
          class="form-control"
        >
      </div>
      <div class="form-group">
        <label for="org">Company/School</label>
        <input
          id="org"
          v-model="org"
          type="text"
          placeholder="Enter company/school"
          class="form-control"
        >
      </div>
      <div class="form-group">
        <label for="role">Role/Occupation</label>
        <input
          id="role"
          v-model="role"
          type="text"
          placeholder="Enter role"
          class="form-control"
        >
      </div>
      <div class="form-group">
        <label for="userBg">Tell us about your background in education and EdTech</label>
        <textarea
          id="userBg"
          v-model="userBackground"
          placeholder="Enter.."
          class="form-control"
        />
      </div>
      <div class="form-group">
        <label for="topicsToDiscuss">What kind of topics would you like to discuss as a guest on EdTech Adventures?</label>
        <textarea
          id="topicsToDiscuss"
          v-model="topicsToDiscuss"
          placeholder="Enter.."
          class="form-control"
        />
      </div>
      <div class="form-group pull-right">
        <span
          v-if="isSuccess"
          class="success-msg"
        >
          Success
        </span>
        <button
          class="btn btn-success btn-lg"
          type="submit"
          :disabled="inProgress"
        >
          Submit
        </button>
      </div>
    </form>
  </modal>
</template>

<script>
import Modal from '../../components/common/Modal'
import { podcastContact } from '../../core/api/podcast'

export default {
  name: 'LetsChatModal',
  components: {
    Modal
  },
  data () {
    return {
      name: me.get('firstName') || me.get('name'),
      email: me.get('email'),
      org: null,
      role: me.get('role'),
      userBackground: null,
      topicsToDiscuss: null,
      isSuccess: false,
      inProgress: false
    }
  },
  methods: {
    async onFormSubmit () {
      this.inProgress = true
      this.isSuccess = false
      const details = {
        ...this.$data
      }
      try {
        await podcastContact(details)
        this.isSuccess = true
      } catch (err) {
        console.error('podcast contact err', err)
        noty({ text: 'Failed to contact server, please reach out to support@codecombat.com', type: 'error', timeout: 5000, layout: 'topCenter' })
      }
      this.inProgress = false
    }
  }
}
</script>

<style scoped lang="scss">
.lets-chat-form {
  text-align: initial;
  padding: 2rem;
}

::v-deep .title {
  padding-top: 10px;
}

.success-msg {
  font-size: 1.6rem;
  color: #0B6125;
  display: inline-block;
  margin-right: 1rem;
}
</style>
