<template>
  <div
    v-if="child?.stats"
    class="stats"
  >
    <div class="stats__trophy">
      <img src="/images/pages/parents/dashboard/bronze-trophy.png" alt="Bronze trophy" />
    </div>
    <div
      v-if="child.stats?.hoursPlayed"
      class="stat stats__hours"
    >
      <div class="stats__number">{{ child.stats.hoursPlayed }}</div>
      <div class="stats__text">Hours Played</div>
    </div>
    <div
      v-if="child.stats?.gamesCompleted"
      class="stat stats__levels"
    >
      <div class="stats__number">{{ child.stats.gamesCompleted }}</div>
      <div class="stats__text">Levels Completed</div>
    </div>
    <div
      v-if="child.stats?.codePoints"
      class="stat stats__loc"
    >
      <div class="stats__number">{{ child.stats.codePoints }}</div>
      <div class="stats__text">Lines of Code Written</div>
    </div>
    <div
      v-if="conceptsMastered"
      class="stat stats__concepts"
    >
      <div class="stats__number">{{ conceptsMastered }}</div>
      <div class="stats__text">Concepts Mastered</div>
    </div>
    <div class="stats__trophy">
      <img src="/images/pages/parents/dashboard/bronze-trophy.png" alt="Bronze trophy" />
    </div>
  </div>
</template>

<script>
export default {
  name: 'StudentStatsComponent',
  props: {
    child: {
      type: Object
    }
  },
  computed: {
    conceptsMastered () {
      const concepts = this.child?.stats?.concepts || {}
      let count = 0
      for (const concept in concepts) {
        if (concepts[concept]) count++
      }
      return count
    }
  }
}
</script>

<style scoped lang="scss">
@import "../css-mixins/variables";
.stats {
  display: flex;
  align-items: center;
  width: 100%;
  justify-content: space-evenly;
  flex-wrap: wrap;
  padding-bottom: 1rem;

  .stat {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
  }

  &__number {
    font-family: 'Space Mono', sans-serif;
    font-style: normal;
    font-weight: 700;
    font-size: 7rem;
    line-height: 10.4rem;
    color: $color-blue-1;
  }

  &__text {
    font-weight: 600;
    font-size: 1.4rem;
    line-height: 1.8rem;
    letter-spacing: 0.4px;
    text-transform: uppercase;
    color: $color-grey-1;
    text-align: center;
  }

  &:after {
    content: "";
    height: 5px;
    display: block;
    width: 90%;
    background: linear-gradient(59.36deg, $color-yellow-2 -5.07%, $color-yellow-2 16.64%, $color-yellow-1 93.04%, $color-yellow-1 103.46%);
    margin-top: 2rem;
  }
}
</style>
