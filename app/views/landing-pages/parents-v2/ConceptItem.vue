<template>
  <div class="concept-item">
    <img
      :src="goblet"
      alt="Goblet"
    >
    <div class="level">
      <span class="level-item">{{ level }}</span>
    </div>
    <div class="title">
      {{ title }}
    </div>
    <div class="concept-list">
      <div
        v-for="concept in concepts"
        :key="concept"
        class="concept-list-item"
      >
        {{ concept }}
      </div>
    </div>
  </div>
</template>

<script>
export default {
  components: {
  },
  props: {
    goblet: {
      type: String,
      required: true,
    },
    level: {
      type: String,
      required: true,
    },
    title: {
      type: String,
      required: true,
    },
    concepts: {
      type: Array,
      required: true,
    },
  },
}
</script>

<style scoped lang="scss">
@import 'app/styles/component_variables.scss';

.concept-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  align-self: stretch;
  gap: 30px;
  flex: 1;

  .level {
    .level-item {
      border-radius: 24px;
      background: #BAF5F7;
      display: inline-flex;
      padding: 4px 16px;
      justify-content: center;
      align-items: flex-start;
    }
  }

  .title {
    @extend %font-18-24;
    font-weight: bold;
    color: var(--color-primary);
    text-align: center;
    padding: 4px 20px;
  }

  .concept-list {
    margin: auto 40px 0 40px;
    width: calc(100% - 80px);
    border-radius: 24px;
    border: 2px dashed var(--color-primary-2);
    padding: 30px 0;
    text-align: center;

    .concept-list-item {
      @extend %font-18-24;
      white-space: nowrap;
    }
  }
}
</style>
