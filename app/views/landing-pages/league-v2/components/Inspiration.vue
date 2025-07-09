<template>
  <page-section class="section">
    <template #heading>
      Are you an educator or esports coach?
      This game-based competitive coding competition delivers high engagement with a turn-key approach. 
    </template>
    <template #body>
      <two-column-block
        :reverse="block.reverse"
        class="block"
      >
        <template #column-two>
          <content-box :main-image-bg="true">
            <template #image>
              <img
                v-if="block.image"
                :src="block.image.src"
                :alt="block.image.alt || `Image to illustrate ${block.colTwo?.title}`"
              >
            </template>
          </content-box>
        </template>
        <template #column-one>
          <div
            class="col-two"
            :class="{reverse: !block.reverse}"
          >
            <div class="img-group">
              <img
                v-for="img in block.colTwo.images"
                :key="img.src"
                :src="img.src"
                :style="img.style"
                class="character-image"
              >
            </div>
            <div class="content">
              <!-- eslint-disable vue/no-v-html -->
              <div
                class="svg"
                v-html="block.colTwo.vector"
              />
              <!--eslint-enable-->
              <div class="title">
                {{ block.colTwo.title }}
              </div>
              <div class="description">
                {{ block.colTwo.description }}
              </div>
            </div>
          </div>
        </template>
      </two-column-block>
    </template>
  </page-section>
  
</template>
<script>
import PageSection from '../../../../components/common/elements/PageSection.vue'
export default {
  components: {
    PageSection
  },
  data () {
    return {
      blocks: [
        {
          reverse: false,
          image: {
            src: '',
            alt: 'Academic Rigor',
          },
          title: 'Academic Rigor',
          description: 'The open-ended objective encourages creativity, experimentation and iteration as students showcase their understanding of coding concepts and practice what they\'ve learned from the core curriculum. ',
        }, {
           reverse: false,
          image: {
            src: '',
            alt: 'Asynchronous Competition',
          },
          title: 'Asynchronous Competition',
          description: 'Unlike other esports, our platform allows players to compete anytime/anywhere with no need to coordinate schedules. ',
        }, {
            reverse: false,
          image: {
            src: '',
            alt: 'Greater Accessibility',
          },
          title: 'Greater Accessibility',
          description: 'Since we’re an academic esport built on knowledge and strategy, fast reaction techniques or hand-eye coordination don’t impact play. Therefore, anyone can compete using basic computers (Chromebooks) with internet access.',
        }
      ],
      steps: [
        {
          title: 'Create a Team/Classroom',
          titleLink: '',
          description: 'Teams are the same as classrooms and you can use existing classrooms to run tournaments or set up a new team if you want to invite players from different classrooms.',
        }, {
          title: 'Invite Players',
          titleLink: '',
          description: 'Inviting players follows the same steps as when you add them to a classroom. Players will show up on the leaderboard after submitting code the first time.',
        }, {
          title: 'Create Custom Tournament',
          titleLink: '',
          description: 'Now you will have the opportunity to pick your arena and set the timing for your custom tournament.',
        }
      ]
    }
  }
}

</script>