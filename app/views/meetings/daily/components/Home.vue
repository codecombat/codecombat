<template>
  <home-screen
    v-if="appState === 'idle'"
    :join-call="joinCall"
  />
  <call-tile
    v-else-if="appState === 'incall'"
    :leave-call="leaveCall"
    :name="name"
    :room-url="roomUrl"
  />
</template>

<script>
import CallTile from './CallTile.vue'
import HomeScreen from './HomeScreen.vue'

export default {
  name: 'DailyHome',
  components: {
    CallTile,
    HomeScreen
  },
  data () {
    return {
      appState: 'idle',
      name: 'Guest',
      roomUrl: null
    }
  },
  methods: {
    /**
     * Set name and URL values entered in Home.vue form in data obj
     */
    joinCall (name, url) {
      this.name = name
      this.roomUrl = url
      this.appState = 'incall'
    },
    // Reset app state to return to the home screen after leaving call
    leaveCall () {
      this.appState = 'idle'
    }
  }
}
</script>

<style scoped>
#app {
  font-family: Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #2c3e50;
  display: flex;
  flex-direction: column;
  height: 100vh;
  overflow-x: hidden;
  background-color: #121a24;
}
a {
  text-decoration: none;
  color: #2c3e50;
  display: flex;
  align-items: center;
}
body {
  margin: 0;
}
</style>
