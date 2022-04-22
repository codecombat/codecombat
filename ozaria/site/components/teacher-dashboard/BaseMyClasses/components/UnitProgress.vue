<script>
  export default {
    props: {
      name: {
        type: String,
        required: true
      },

      isAssigned: {
        type: Boolean,
        default: false
      },

      completionPercentage: {
        type: Number,
        default: 0
      }
    },
    computed: {
      progressWidth () {
        return this.completionPercentage * 185
      },

      barColor () {
        if (this.completionPercentage === 1) {
          return '#2dcd38'
        } else {
          return '#1ad0ff'
        }
      }
    }
  }
</script>
<template>
  <div class="unit-progress">
    <div class="flex-row titles">
      <p class="chapter-header">{{ name }}</p>
      <p v-if="isAssigned" class="assigned">✅ Assigned</p>
    </div>
    <div class="outer-loading-bar">
      <div class="inner-loading-bar" :style="{ width: `${progressWidth}px`, backgroundColor: barColor }" />
    </div>
  </div>
</template>

<style lang="scss" scoped>
  @import "app/styles/bootstrap/variables";
  @import "ozaria/site/styles/common/variables.scss";
  @import "app/styles/ozaria/_ozaria-style-params.scss";
  .flex-row {
    display: flex;
    flex-direction: row;
    align-items: center;
  }

  .unit-progress {
    display: flex;
    flex-direction: column;
    margin: 6px 8px;
  }

  .outer-loading-bar {
    width: 185px;
    height: 16px;

    border: 1px solid #adadad;
    background-color: white;
  }

  .inner-loading-bar {
    height: 100%;
    width: 75px;

    background-color: #1ad0ff;
  }

  .titles {
    align-items: center;
  }

  .chapter-header, .assigned {
    @include font-p-4-paragraph-smallest-gray;
    color: #545b64;
    letter-spacing: 0.3333px;
    font-weight: 600;
  }

  .assigned {
    margin-left: 12px;
    font-size: 12px;
    line-height: 16px;
    font-weight: 400;
    color: #379b8d;
    letter-spacing: 0.266667px;
  }
</style>
