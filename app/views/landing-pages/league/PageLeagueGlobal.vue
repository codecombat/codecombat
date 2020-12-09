<script>
import { mapGetters } from 'vuex'
import Leaderboard from './components/Leaderboard'
export default {
  components: {
    Leaderboard
  },
  
  computed: {
    ...mapGetters({
      globalRankings: 'seasonalLeague/globalRankings'
    })
  }
}
</script>

<template>
  <div>
    <h1>Stub Global Rankings for Seasonal Arena: </h1>
    <leaderboard :rankings="globalRankings" />
  </div>
</template>