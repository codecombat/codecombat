<template>
  <div class="solutions">
    <div class="heading">
      <MixedColorLabel :text="title" />
    </div>
    <div class="menu-content">
      <div
        v-for="(item, index) in items"
        :key="index"
        class="list-item"
      >
        <img
          class="vector"
          :src="item.src"
          :alt="`Vector image to illustrate ${item.text}`"
        >
        <div
          class="text-wrapper"
        >
          <div
            v-for="(line, lineIndex) in item.text.split('[NEWLINE]')"
            :key="`line-${lineIndex}`"
          >
            {{ line }}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import MixedColorLabel from '../../components/common/labels/MixedColorLabel.vue'

export default {
  name: 'TurnkeySolutions',
  components: {
    MixedColorLabel
  },
  props: {
    title: {
      type: String,
      required: true
    }
  },
  data () {
    return {
      items: [
        { src: '/images/pages/schools/solutions/solution_1.svg', text: 'Core\nCurriculum' },
        { src: '/images/pages/schools/solutions/solution_2.svg', text: 'Tools &\nResources' },
        { src: '/images/pages/schools/solutions/solution_3.svg', text: 'Data &\nInsights' },
        { src: '/images/pages/schools/solutions/solution_4.svg', text: 'Professional\nDevelopment' },
        { src: '/images/pages/schools/solutions/solution_5.svg', text: 'AI Support &\nAcceleration' },
        { src: '/images/pages/schools/solutions/solution_6.svg', text: 'Accessibility &\nRepresentation' },
        { src: '/images/pages/schools/solutions/solution_7.svg', text: 'Privacy &\nSecurity' }
      ]
    }
  }
}
</script>

  <!-- Styles remain the same -->

<style lang="scss" scoped>
@import "app/styles/component_variables.scss";
.solutions {
    align-items: center;
    display: flex;
    flex-direction: column;
    gap: 80px;
    position: relative;

    .heading {
        align-self: stretch;
        color: #000000;
        @extend %font-36;
        position: relative;
        text-align: center;
    }

    .menu-content {
        align-items: flex-start;
        align-self: stretch;
        display: flex;
        flex: 0 0 auto;
        gap: 30px;
        justify-content: center;
        position: relative;
        width: 100%;
        flex-wrap: wrap;
    }

    .list-item {
        align-items: center;
        display: flex;
        flex: 1;
        flex-direction: column;
        flex-grow: 1;
        gap: 40px;
        position: relative;
    }

    .vector {
        position: relative;
        width: 70px;
        height: 70px;
    }

    .text-wrapper {
        align-self: stretch;
        color: #000000;
        @extend %font-20;
        position: relative;
        text-align: center;
    }
}
</style>
