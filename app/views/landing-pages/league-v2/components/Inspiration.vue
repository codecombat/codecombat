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
                {{ $t(block.title) }}
              </div>
              <div class="description">
                {{ $t(block.description) }}
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
  name: 'LeagueInspiration',
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
          title: 'league_v2.academic_rigor',
          description: 'league_v2.academic_rigor_desc',
        }, {
          reverse: true,
          image: {
            src: '/images/pages/league/v2/Asynchronous-Competition.jpg',
            alt: 'Asynchronous Competition',
          },
          title: 'league_v2.asynchronous_competition',
          description: 'league_v2.asynchronous_competition_desc',
        }, {
          reverse: false,
          image: {
            src: '/images/pages/league/v2/Greater-Accessibility.webp',
            alt: 'Greater Accessibility',
          },
          title: 'league_v2.greater_accessibility',
          description: 'league_v2.greater_accessibility_desc',
        },
      ],
    }
  },
}

</script>

<style lang="scss" scoped>
@import "app/styles/bootstrap/variables";
@import "app/styles/component_variables.scss";

$primary-color: #4DECF0;
.section {
  background: #021E27;
}
.col-one {
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
      @extend %font-36;
      font-weight: bold;
      margin-bottom: 24px;
      color: $primary-color;
    }

    .description {
      @extend %font-20;
      color: white;
    }
  }
}

.block {
  margin: 30px 0 !important;
  min-width: 1000px;
}

@media (max-width: $screen-md-min) {
  .block {
    min-width: unset;
    width: 100%;
  }
}
</style>