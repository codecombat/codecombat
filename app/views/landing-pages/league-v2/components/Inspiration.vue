<template>
  <page-section class="section">
    <template #heading>
      <div>{{ $t('league_v2.inspiration_title') }}</div>
      <div class="content">
        {{ $t('league_v2.inspiration_desc') }}
      </div>
    </template>
    <template #body>
      <two-column-block
        v-for="block in blocks"
        :key="block.title"
        :reverse="block.reverse"
        class="block"
      >
        <template #column-two>
          <content-box :main-image-bg="true">
            <template #image>
              <img
                v-if="block.image"
                :src="block.image.src"
                :alt="block.image.alt || `Image to illustrate ${block.title}`"
              >
            </template>
          </content-box>
        </template>
        <template #column-one>
          <div
            class="col-one"
          >
            <div class="body">
              <!--eslint-enable-->
              <div class="title">
                {{ block.title }}
              </div>
              <div class="description">
                {{ block.description }}
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
import TwoColumnBlock from 'app/components/common/elements/TwoColumnBlock.vue'
import ContentBox from '../../../../components/common/elements/ContentBox'
export default {
  name: 'InspirationComponent',
  components: {
    PageSection,
    TwoColumnBlock,
    ContentBox,
  },
  data () {
    return {
      blocks: [
        {
          reverse: false,
          image: {
            src: '/images/pages/league/v2/Academic-Rigor.png',
            alt: 'Academic Rigor',
          },
          title: 'Academic Rigor',
          description: 'The open-ended objective encourages creativity, experimentation and iteration as students showcase their understanding of coding concepts and practice what they\'ve learned from the core curriculum. ',
        }, {
          reverse: true,
          image: {
            src: '/images/pages/league/v2/Asynchronous-Competition.jpg',
            alt: 'Asynchronous Competition',
          },
          title: 'Asynchronous Competition',
          description: 'Unlike other esports, our platform allows players to compete anytime/anywhere with no need to coordinate schedules. ',
        }, {
          reverse: false,
          image: {
            src: '/images/pages/league/v2/Greater-Accessibility.jpg',
            alt: 'Greater Accessibility',
          },
          title: 'Greater Accessibility',
          description: 'Since we’re an academic esport built on knowledge and strategy, fast reaction techniques or hand-eye coordination don’t impact play. Therefore, anyone can compete using basic computers (Chromebooks) with internet access.',
        },
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
        },
      ],
    }
  },
}

</script>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "app/styles/component_variables.scss";

.section {
  background: #021E27;
}
.col-one {
  background: white;
  background: linear-gradient(to right, #f5ffff, #fff);
  height: 100%;
  display: flex;
  justify-content: center;
  align-items: center;
  border-radius: 24px;
  .body {
    color: black;
    text-align: left;
    padding: 20px;

    .title {
      @extend %font-24-30;
      font-weight: bold;
    }
  }
}

.block {
  gap: unset;
  margin: 10px auto !important;

  ::v-deep .column-one div{
    border-top-right-radius: unset;
    border-bottom-right-radius: unset;
  }
  ::v-deep .column-two div, &.reverse .column-one div{
    border-top-left-radius: unset;
    border-bottom-left-radius: unset;
  }

  &.reverse {
    ::v-deep {
      .column-one {
        div {
          border-radius: 24px;
          border-top-left-radius: unset;
          border-bottom-left-radius: unset;
        }
      }
      .column-two{
        div {
          border-radius: 24px;
          border-top-right-radius: unset;
          border-bottom-right-radius: unset;
        }
      }
    }
  }
}
</style>