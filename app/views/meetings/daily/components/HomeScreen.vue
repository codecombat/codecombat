<template>
  <main>
    <div class="wrapper">
      <h1>Call object Vue demo</h1>
      <p>Demo a custom call interface built using Daily call object for Vue</p>

      <form
        class="join-form"
        @submit="joinWithName"
      >
        <div class="name-container">
          <label for="name">Your name</label>
          <input
            id="name"
            v-model="name"
            type="text"
            required
          >
          <label for="name">Daily URL</label>
          <input
            id="url"
            v-model="url"
            type="text"
            placeholder="https://your-daily-domain.daily.co/room-name"
            required
          >
        </div>
        <div class="submit-container">
          <button type="submit">
            Start demo
          </button>
        </div>
      </form>

      <p class="subtext">
        If prompted, select "Allow" to use your camera and mic for this call
      </p>
    </div>
  </main>
</template>

<script>
export default {
  name: 'HomeScreen',
  props: {
    joinCall: {
      type: Function,
      required: true
    }
  },
  data () {
    return {
      name: '',
      url: ''
    }
  },
  methods: {
    // Submit form with prop method defined in App.vue
    joinWithName () {
      this.joinCall(this.name, this.url)
    }
  }
}
</script>

<style scoped>
main {
  display: flex;
  justify-content: center;
  align-items: center;
  flex: 1;
  background-color: #fff;
}
.wrapper {
  max-width: 1200px;
  margin: auto;
  padding: 0 16px;
}
.wrapper p {
  margin: 8px 0;
}
.join-form {
  display: flex;
  flex-direction: column;
  width: 300px;
  margin: auto;
}

.join-form label {
  font-size: 12px;
  color: #6b7785;
  text-align: left;
  margin: 8px 0 4px;
}
.join-form input {
  padding: 8px;
  border: 1px solid #c8d1dc;
  border-radius: 12px;
}
.join-form div {
  display: flex;
  justify-content: center;
}
.join-form .submit-container button {
  padding: 7px 16px 9px;
  font-size: 12px;
  font-weight: bold;
  border: none;
  border-radius: 12px;
  margin-top: 16px;
  margin-bottom: 12px;
  background-color: #1bebb9;
  cursor: pointer;
}
.join-form .name-container {
  flex-direction: column;
}
.subtext {
  font-size: 12px;
  color: #6b7785;
}
</style>
