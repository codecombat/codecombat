<template>
  <div
    class="yearly-component"
    :class="`${borderDir} ${borderColor}`"
  >
    <div class="year-label">
      {{ year }}
    </div>
    <div
      class="seasons"
    >
      <SeasonComponent
        v-for="season in seasons"
        :key="`${$vnode.key || _uid}-${year}-season-${season.number}`"
        :season="season"
      />
    </div>
  </div>
</template>
<script>
import SeasonComponent from './SeasonComponent.vue'
export default {
  components: {
    SeasonComponent,
  },
  props: {
    year: {
      type: Number,
      default: 0,
    },
    seasons: {
      type: Array,
      default: () => ([]),
    },
  },
  data () {
    return {

    }
  },
  computed: {
    borderDir () {
      return this.year % 2 ? 'border-right' : 'border-left'
    },
    borderColor () {
      return this.year % 2 ? 'border-cyan' : 'border-white'
    },
  },
}

</script>

<style lang="scss" scoped>
@import "app/styles/component_variables.scss";
$custom-cyan:  rgb(77, 236, 240);
.yearly-component {
  $border-style: 2px solid;
  border-bottom: $border-style;
  margin-top: 40px;
  padding-left: 20px;
  padding-right: 20px;

  position: relative;
  &::before {
    content: '';
    position: absolute;
    top: 0;
    width: 75%;
    height: 2px;
  }

  .year-label {
    font-size: 32px;
    line-hight: 32px;
    font-weight: bold;
    position: absolute;
    top: -24px;
  }

  &.border-left {
    border-left:  $border-style;
    &::before {
      left: 0;
    }
    .year-label {
      right: calc(25% - 3em);
    }
  }
  &.border-right {
    border-right:  $border-style;
    &::before {
      right: 0;
    }
    .year-label {
      left: calc(25% - 3em);
    }
  }

  &.border-cyan {
    border-color: $custom-cyan;
    &::before {
      background-color: $custom-cyan;
    }
    .year-label {
      color: $custom-cyan;
    }
  }
  &.border-white {
    border-color: white;
    &::before {
      background-color: white;
    }
    .year-label {
      color: white;
    }
  }

  .seasons {
    display: flex;
  }
}

@media (max-width: $screen-md-min) {
  .seasons {
    flex-direction: column;
  }
}
</style>
