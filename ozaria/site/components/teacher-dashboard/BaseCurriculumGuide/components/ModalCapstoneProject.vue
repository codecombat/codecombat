<script>
import { mapGetters, mapMutations } from 'vuex'
import Modal from 'ozaria/site/components/common/BaseModalContainer.vue'

export default Vue.extend({
  components: {
    Modal,
  },
  data () {
    return {
      goal: {
        'introduction-to-computer-science': 'Write a program that draws a dragon.',
        'computer-science-2': 'Create a text-based adventure game.',
        'computer-science-3': 'Create a simulation.',
        'computer-science-4': 'Recreate an arcade game, card game, or board game.',
      },
      requirements: {
        'introduction-to-computer-science': ['Your dragon must be at least half the width and height of your viewing window.', 'You must meaningfully use two variables in your program.'],
        'computer-science-2': ['Your game includes at least 3 questions that a user can answer.', 'Different output is generated depending on the input provided by the user.', 'You meaningfully define and call a function that uses at least one paramater.'],
        'computer-science-3': ['At least one input must be randomly generated.', 'Output must change depending on the input randomly generated.', 'Define and call a function that uses at least one parameter and one return statement.'],
        'computer-science-4': ['Users should be able to provide input in order to play the game, and this input should influence game play in some way.', 'Use at least one list in your program.', 'Define and call a function that uses at least one parameter and one return statement.'],
      }
    }
  },
  computed: {
    ...mapGetters({
      visible: 'baseCurriculumGuide/isCapstoneModalVisible',
      getCurrentCourse: 'baseCurriculumGuide/getCurrentCourse'
    }),

    courseSlug () {
      return this.getCurrentCourse.slug
    },

    courseGoal () {
      const slugName = this.courseSlug
      if (Object.hasOwn(this.goal, slugName)) {
        return this.goal[slugName]
      }
      return `no capstone project for ${slugName}`
    },

    courseRequirements () {
      const slugName = this.courseSlug
      if (Object.hasOwn(this.goal, slugName)) {
        return this.requirements[slugName]
      }
      return []
    },
  },
  methods: {
    ...mapMutations({
      closeCapstoneModal: 'baseCurriculumGuide/closeCapstoneModal',
    }),

    closeModal () {
      this.closeCapstoneModal()
    },
  },
})
</script>

<template>
  <modal
    v-if="visible"
    :transparent-background="true"
  >
    <div class="capstone-project-modal">
      <button
        class="btn btn-danger pull-right"
        type="button"
        @click="closeModal"
      >
        <span class="glyphicon glyphicon-remove" />
      </button>
      <div class="header">
        Capstone Project:
      </div>
      <div class="program-spec-container">
        <div class="program-spec-title">
          Program Specification
        </div>
        <div class="goal">
          <div class="goal-title">
            Goal:
          </div>
          <span class="goal-text">{{ courseGoal }}</span>
        </div>
        <div class="requirements-title">
          Requirements:
        </div>
        <ul class="requirements-list">
          <li
            v-for="requirement in courseRequirements"
            :key="requirement"
          >
            {{ requirement }}
          </li>
        </ul>
      </div>
    </div>
  </modal>
</template>

<style lang="scss">
.capstone-project-modal {
  border: 1px solid transparent;
  border-width: 115px 63px 64px 40px;
  border-image: url(/images/level/code_editor_background_border.png) 124 63 64 40 fill stretch;
  width: 820px;
  padding: 10px;
}

.program-spec-container {
  background-color: #2b536a;
  border-color: #ffffff;
  border-width: 3px;
  border-radius: 4px;
  border-style: solid;
  color: white;
  padding: 30px;
  display: flex;
  flex-direction: column;
  gap: 7px;
  margin-left: auto;
  margin-right: auto;
  width: 600px;
}

.program-spec-title {
  font-family: "Arvo", sans-serif;
  font-weight: 700;
  font-size: 2.8rem;
  line-height: 2.4rem;
  margin-bottom: 10px;
}

.header {
  font-family: "Arvo", sans-serif;
  font-weight: 700;
  font-size: 4.3rem;
  line-height: 4rem;
  margin-bottom: 25px;
}

.goal {
    display: flex;
    flex-direction: row;
    gap: 5px;
}

.goal-title {
  font-size: 20px;
  font-weight: bold;
  text-decoration: underline;
  display: inline;
}

.goal-text {
  font-size: 20px;
}

.requirements-title {
  font-size: 20px;
  font-weight: bold;
  text-decoration: underline;
}

.requirements-list {
  padding-left: 27px;
}
</style>
