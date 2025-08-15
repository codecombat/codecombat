<template>
  <page-section class="section">
    <template #heading>
      <div class="title">
        {{ $t('league_v2.set_up_tournament') }}
      </div>
      <div class="content">
        {{ $t('league_v2.set_up_desc') }}
      </div>
    </template>
    <template #body>
      <ProgressBar
        :progress="1"
        :dots="3"
        class="league-progress-bar"
      >
        <template
          v-for="(step, index) in steps"
          #[`dot-label-${index}`]
        >
          <div
            :key="`step-${index}`"
            class="progress-steps"
          >
            <img
              :src="step.img"
              class="icon"
            >
            <p>
              {{ step.title }}
            </p>
          </div>
        </template>
      </ProgressBar>
    </template>
    <template #tail>
      <!-- eslint-disable-next-line vue/no-v-html vue/html-self-closing -->
      <div v-html="$t('league_v2.refer_guide')" />
      <div>{{ $t('league_v2.having_question') }}</div>
    </template>
  </page-section>
</template>
<script>
import PageSection from '../../../../components/common/elements/PageSection.vue'
import ProgressBar from '../../../../components/common/elements/ProgressBar.vue'
export default {
  components: {
    PageSection,
    ProgressBar,
  },
  data () {
    return {
      steps: [
        {
          title: $.i18n.t('league_v2.create_team'),
          titleLink: '',
          img: '/images/pages/league/v2/create_team.png',
        }, {
          title: $.i18n.t('league_v2.invite_players'),
          titleLink: 'https://docs.google.com/presentation/d/1ouDOu2k-pOxkWswUKuik7CbrUCkYXF7N_jNjGO0II6o/edit?slide=id.gc2bf37ee3f_0_14#slide=id.gc2bf37ee3f_0_14',
          img: '/images/pages/league/v2/invite_players.png',
        }, {
          title: $.i18n.t('league_v2.select_arena'),
          titleLink: '/league/ladders',
          img: '/images/pages/league/v2/select_arena.png',
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
  background-color: rgb(25, 54, 64);
}
.content {
  @extend %font-20;
  margin-bottom: 20px;
  color:  #B4B4B4;
  text-align: center;
}

.league-progress-bar {
  max-width: 640px;
  margin-top: 10em;
  margin-bottom: 8em;

  .progress-steps {
    position: relative;
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;
    margin-top: 2em;

    .icon {
      position: absolute;
      top: -10em;
      height: 100px;
    }

    p {
      @extend %font-18-24;
      text-align: center;
      width: 10em;
    }
  }

  ::v-deep #true-progress {
    top: -2px;
    height: 3px;
  }
  ::v-deep .progress-dots {
    top: -14px !important;

    .dot {
      width: 26px !important;
      height: 26px !important;
      &:first-child {
        margin-left: -13px !important;
      }
      &:last-child {
        margin-right: -13px !important;
      }
    }
  }
}
</style>