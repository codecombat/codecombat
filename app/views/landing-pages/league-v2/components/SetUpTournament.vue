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
            <div class="info">
              <p class="step">
                {{ step.step }}
              </p>
              <p class="link">
                <a
                  href="javascript:void(0)"
                  @click="step.event"
                >{{ step.title }}</a>
              </p>
            </div>
          </div>
        </template>
      </ProgressBar>
    </template>
    <template #tail>
      <!-- eslint-disable vue/no-v-html vue/html-self-closing -->
      <div
        class="tail-content"
        v-html="$t('league_v2.refer_guide')"
      />
      <div
        class="tail-content"
        v-html="$t('league_v2.having_question')"
      />
      <!-- eslint-enable vue/no-v-html vue/html-self-closing -->
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
          step: $.i18n.t('league_v2.step_1'),
          event: () => {
            window.open('https://docs.google.com/presentation/d/1ouDOu2k-pOxkWswUKuik7CbrUCkYXF7N_jNjGO0II6o/edit#slide=id.gc02108344f_0_69', '_blank', 'noopener,noreferrer')
          },
          img: '/images/pages/league/v2/create_team.png',
        }, {
          title: $.i18n.t('league_v2.invite_players'),
          step: $.i18n.t('league_v2.step_2'),
          event: () => {
            window.open('https://docs.google.com/presentation/d/1ouDOu2k-pOxkWswUKuik7CbrUCkYXF7N_jNjGO0II6o/edit?slide=id.gc2bf37ee3f_0_14#slide=id.gc2bf37ee3f_0_14', '_blank', 'noopener,noreferrer')
          },
          img: '/images/pages/league/v2/invite_players.png',
        }, {
          title: $.i18n.t('league_v2.select_arena'),
          step: $.i18n.t('league_v2.step_3'),
          event: () => {
            window.open('/league/ladders', '_blank', 'noopener,noreferrer')
          },
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
  background-color: #122f39;
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
      @extend %font-20;
      text-align: center;
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
.info {
  .step {
    color: white;
    font-weight: bold;
  }
  .link {
    width: 340px;
  }
}
.tail-content {
  margin-bottom: 20px;
  font-size: 22px !important;
}
@media (max-width: $screen-md-min) {
  .tail-content {
    font-size: 16px !important;
  }
}
</style>