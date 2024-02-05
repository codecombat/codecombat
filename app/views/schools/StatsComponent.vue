<template>
  <content-box>
    <template #text>
      <div class="content">
        <p class="title">
          Our program is a proven success for both middle <br>
          school and high school use cases.
        </p>
        <div class="data-text">
          <div class="data">
            <img
              class="vector"
              alt="Vector"
              src="/images/pages/schools/stats/stats_1.svg"
            >
            <div class="div">
              <p class="text">
                Between the pre-assessment and the final assessment, students made an average gain score of +47%
              </p>
              <learn-more-button
                link="https://www.ozaria.com/efficacy"
                target="_blank"
              >
                Ozaria Efficacy Report Summary McIntosh Middle School
              </learn-more-button>
            </div>
          </div>
          <div class="data">
            <img
              class="vector"
              alt="Vector"
              src="/images/pages/schools/stats/stats_2.svg"
            >
            <div class="div">
              <testimonial-component
                :quote="`“When I taught classes of 15, the most I ever had was maybe two or three [students] get a three or
                higher
                [on the AP CSP exam]. So when I had 13 out of my 17 [students] get a three or higher a lot of them
                said
                what definitely helped them was learning CodeCombat and Python.”`"
                name="Andrew Forsman"
                title="Engineering Teacher"
                image="/images/pages/schools/avatar/avatar_andrew.png"
              />
              <learn-more-button
                link="https://codecombat.com/impact"
                target="_blank"
              >
                River Ridge High School Case Study
              </learn-more-button>
            </div>
          </div>
        </div>
      </div>
    </template>
  </content-box>
</template>

<script>
import ContentBox from 'app/components/common/elements/ContentBox.vue'
import LearnMoreButton from 'app/components/common/buttons/LearnMoreButton.vue'
import TestimonialComponent from '../../components/common/elements/TestimonialComponent.vue'
export default {
  name: 'StatsComponent',
  components: {
    ContentBox,
    LearnMoreButton,
    TestimonialComponent
  }
}
</script>

<style scoped lang="scss">
@import "app/styles/component_variables.scss";
::v-deep.box {
  background: #f9f9ff;
}
.content {
  align-items: center;
  display: flex;
  flex-direction: column;
  gap: 80px;
  justify-content: center;
  position: relative;

  .title {
    @extend %font-36;
    color: $purple;
    position: relative;
    text-align: center;
  }

  .data-text {
    align-items: center;
    align-self: stretch;
    display: flex;
    flex: 0 0 auto;
    flex-direction: column;
    gap: 40px;
    justify-content: center;
    position: relative;
    width: 100%;
  }

  .data {
    align-items: center;
    align-self: stretch;
    display: flex;
    flex: 0 0 auto;
    gap: 30px;
    position: relative;
    width: 100%;
    @media (max-width: $screen-sm-max) {
      flex-direction: column;
      gap: 20px;
    }
  }

  .vector {
    position: relative;
    width: 170px;
  }

  .div {
    align-items: flex-start;
    display: flex;
    flex: 1;
    flex-direction: column;
    flex-grow: 1;
    gap: 12px;
    position: relative;
  }

  .text {
    @extend %font-24-34;
    align-self: stretch;
    color: $dark-grey;
    font-style: italic;
  }
}
</style>
