<script>
import ChangePasswordModal from 'app/views/user/ChangePasswordModal.vue'
import apiClient from 'app/core/api/api-clients'

export default Vue.extend({
  components: {
    ChangePasswordModal,
  },
  data () {
    return {
      userInput: '',
      foundUsers: [],
      showChangePasswordModal: false,
      selectedUser: '',
    }
  },
  computed: {
    isAPIClient () {
      return me.isAPIClient() || me.isAdmin()
    },
  },
  methods: {
    resetInputs () {
      this.userInput = ''
      this.foundUsers = []
      this.selectedUser = ''
    },
    async searchUser () {
      console.log(this.userInput)
      const userInput = this.userInput.trim().toLowerCase()
      try {
        const response = await apiClient.getUsersSearch(userInput)
        this.onSearchRequestSuccess(response)
      } catch (error) {
        console.log(error)
        this.foundUsers = []
      }
    },
    onSearchRequestSuccess (users) {
      this.foundUsers = []
      for (const user of Array.from(users)) {
        this.foundUsers.push({
          id: user._id,
          email: user.email,
          name: user.name,
        })
      }
    },
    openPasswordModal (userId) {
      console.log('try to open modal', userId)
      this.showChangePasswordModal = true
      this.selectedUser = userId
    },
  },
})
</script>

<template>
  <div v-if="isAPIClient">
    <div class="style-ozaria teacher-form">
      <span class="sub-title">{{ $t('password_reset_page.enter_prompt') }}</span>
      <div>
        <input
          v-model="userInput"
          type="text"
          class="form-control"
          :placeholder="$t('password_reset_page.input_placeholder')"
        >
        <button
          type="button"
          @click="searchUser"
        >
          {{ $t('password_reset_page.search_user') }}
        </button>
        <button
          type="button"
          @click="resetInputs"
        >
          {{ $t('password_reset_page.search_again') }}
        </button>
      </div>
      <div
        v-for="user in foundUsers"
        :key="user.id"
      >
        <p>{{ $t('password_reset_page.user_id') }}: {{ user.id }}</p>
        <p v-if="user.name">
          {{ $t('password_reset_page.user_name') }}: {{ user.name }}
        </p>
        <p v-if="user.email">
          {{ $t('password_reset_page.user_email') }}: {{ user.email }}
        </p>
        <button @click="openPasswordModal(user.id)">
          {{ $t('password_reset_page.reset_password') }}
        </button>
      </div>
      <change-password-modal
        v-if="showChangePasswordModal"
        :user-id-to-change-password="selectedUser"
        @close="showChangePasswordModal = false"
      />
    </div>
  </div>
</template>

<style lang="scss" scoped>
@import "app/styles/modal";

.teacher-form {
  display: flex;
  flex-direction: column;
  margin: 15px 15px 0px 15px;
  max-width: 600px;
}

.sub-title {
  @include font-p-2-paragraph-medium-gray;
  font-weight: 600;
  color: $pitch;
}

.form-container {
  width: 100%;
  min-width: 600px;
  margin-top: 10px;
}

.buttons {
  display: flex;
  flex-direction: row;
  justify-content: flex-end;
  align-items: flex-end;
  margin-top: 10px;

  button {
    width: 150px;
    height: 35px;
    margin: 0 10px;
  }
}

.control-label {
  font-size: 18px;
}
</style>
