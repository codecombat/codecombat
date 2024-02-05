<template>
  <div class="row-content">
    <div class="features__column">
      <div class="text-wrapper">
        YEAR {{ year }}
      </div>
    </div>
    <div
      v-for="(percent, index) in percents"
      :key="index"
      class="features__column"
    >
      <div
        v-if="percent!==null"
        class="group"
      >
        <div class="overlap-group">
          <img :src="`/images/pages/schools/percent-${percent}.svg`">
        </div>
        <div class="text-wrapper">
          {{ percent }}% of Time
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'TableRowYear',
  props: {
    year: {
      type: Number,
      required: true
    },
    percents: {
      type: Array,
      required: true
    }
  }
}
</script>

<style scoped lang="scss">
@import "app/styles/component_variables.scss";

.row-content {
    align-items: flex-start;
    border-color: transparent;
    border-radius: 24px;
    display: flex;
    overflow: hidden;
    position: relative;
    width: 100%;

    .features {
        align-items: flex-start;
        align-self: stretch;
        background-color: $purple;
        display: flex;
        flex: 1;
        flex-grow: 1;
        padding: 0px 30px;
        position: relative;
    }

    .features {
        &__column {
            align-items: center;
            align-self: stretch;
            background: $light-purple;
            display: flex;
            flex: 1;
            flex-grow: 1;
            gap: 16px;
            justify-content: center;
            padding: 0px 30px;
            position: relative;
            min-height: 70px;

            &:first-child {
                background: $purple;

                .text-wrapper {
                    color: white;
                }
            }

            &:nth-child(2) {
                background: $middle-purple;
            }

        }
    }

    .group {
        position: relative;
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 16px;

        .overlap-group {
            border-radius: 15px;
            height: 30px;
            position: relative;
            width: 30px;
        }
    }

    .text-wrapper {
        @extend %font-18-24;
        color: $purple;
        position: relative;
        text-align: center;
        width: fit-content;
    }
}
</style>
