<template>
  <div class="level-list">
    <ul
      class="levels"
    >
      <li
        v-for="level in levelsToShow"
        class="level"
        :key="level.id"
      >
        <div class="level__dot"></div>
        <div class="level__name">{{ level.name }}</div>
      </li>
    </ul>
  </div>
</template>

<script>
export default {
  name: 'LevelListComponent',
  props: {
    levels: {
      type: Array
    }
  },
  data () {
    return {
      currentIndex: 0
    }
  },
  computed: {
    levelsToShow () {
      return this.levels.slice(this.currentIndex * 4, (this.currentIndex * 4) + 4)
    }
  }
}
</script>

<style scoped lang="scss">
.level-list {
  background: #F2F2F2;
  box-shadow: 0 4px 1rem rgba(0, 0, 0, 0.25);
  padding-top: 1.5rem;
  padding-bottom: 1rem;
}

.levels {
  list-style: none;
  display: flex;
  justify-content: space-evenly;
  margin-bottom: 0;

  font-size: 1.4rem;
  line-height: 1.8rem;
  letter-spacing: 0.4px;
  text-transform: uppercase;
  color: #979797;
}

.level {
  display: flex;
  flex-direction: column;
  align-items: center;

  cursor: pointer;

  //&::before {
  //  content: "";
  //  height: 1px;
  //  width: 100%;
  //  display: block;
  //  background-color: #C8CDCC;
  //  transform: translateX(100%) translateY(.5rem);
  //}
  //
  //&:last-child {
  //  &::before {
  //    width: 0;
  //  }
  //}

  &__dot {
    width: 1rem;
    height: 1rem;
    background: #FFFFFF;
    border: 1.5px solid #C8CDCC;
    border-radius: 1rem;
    margin-bottom: 1rem;
  }
}
</style>
