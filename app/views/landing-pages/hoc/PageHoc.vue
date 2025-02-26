<template>
  <div id="page-hoc">
    <div class="container header-container">
      <h1>
        <mixed-color-label
          :text="$t('hoc_page.learn_and_engage_with_these_csedweek_activities')"
          :inherit-default-color="true"
        />
      </h1>
    </div>

    <div class="container">
      <box-panel
        :title="$t('hoc_page.latest_activities')"
        :items="latestActivities"
      />
    </div>

    <div class="container">
      <div class="row">
        <div class="col-md-12">
          <h2
            class="text-h2"
          >
            {{ $t('hoc_page.turn_csedweek_into_a_cs_year') }}
          </h2>
        </div>
      </div>
      <div
        v-if="me.isAnonymous()"
        class="row contact-row"
      >
        <div class="col-md-12">
          <CTAButton
            class="signup-button"
            data-start-on-path="teacher"
            :description="$t('hoc_page.start_teaching_today_with_free_trial_access_to_all_games_and_teaching_resources')"
          >
            {{ $t('schools_page.free_teacher_account') }}
          </CTAButton>
        </div>
      </div>
    </div>

    <div class="container more-activities">
      <box-panel
        :title="$t('hoc_page.more_of_our_csedweek_activities')"
        :items="moreActivities"
      />
    </div>
  </div>
</template>

<script>
import PageParentsLanding from 'app/views/landing-pages/parents/PageParents'
import CTAButton from 'app/components/common/buttons/CTAButton.vue'
import MixedColorLabel from 'app/components/common/labels/MixedColorLabel.vue'
import BoxPanel from 'app/components/common/elements/BoxPanel.vue'
import { getJuniorUrl } from 'core/utils'

export default {
  name: 'PageHoc',
  components: {
    CTAButton,
    MixedColorLabel,
    BoxPanel,
  },
  extends: PageParentsLanding,

  data () {
    return {

      latestActivities: [
        {
          title: $.i18n.t('hoc_page.latest_activities_1_title'),
          text: $.i18n.t('hoc_page.latest_activities_1_text'),
          labels: [$.i18n.t('hoc_page.latest_activities_1_label_1'), $.i18n.t('hoc_page.latest_activities_1_label_2')],
          image: '/images/pages/hoc/01.webp',
          links: [
            {
              linkText: $.i18n.t('hoc_page.try_activity'),
              link: '/ai',
            },
            {
              linkText: $.i18n.t('hoc_page.view_lesson'),
              link: 'https://drive.google.com/drive/folders/141_lxrw0S1IgLS89dERCMG6JJp96i6d6?usp=sharing',
            },
          ],

        },
        {
          title: $.i18n.t('hoc_page.latest_activities_2_title'),
          text: $.i18n.t('hoc_page.latest_activities_2_text'),
          labels: [$.i18n.t('hoc_page.latest_activities_2_label_1'), $.i18n.t('hoc_page.latest_activities_2_label_2'), $.i18n.t('hoc_page.latest_activities_2_label_3')],
          image: '/images/pages/hoc/02.webp',
          links: [
            {
              linkText: $.i18n.t('hoc_page.try_activity'),
              link: getJuniorUrl(),
            },
            {
              linkText: $.i18n.t('hoc_page.view_lesson'),
              link: 'https://docs.google.com/presentation/d/1G4GdqCEiFXjGuvP1KLzuYsCfkWteUDwdkWEpMZ1_rs4/edit?usp=sharing',
            },
          ],
        },
      ],

      moreActivities: [
        {
          title: $.i18n.t('hoc_page.codecombat_worlds_title'),
          text: $.i18n.t('hoc_page.codecombat_worlds_text'),
          labels: [
            $.i18n.t('hoc_page.codecombat_worlds_label_1'),
            $.i18n.t('hoc_page.codecombat_worlds_label_2'),
            $.i18n.t('hoc_page.codecombat_worlds_label_3'),
            $.i18n.t('hoc_page.codecombat_worlds_label_4'),
          ],
          image: '/images/pages/hoc/03.webp',
          links: [
            {
              linkText: $.i18n.t('hoc_page.try_activity'),
              link: 'https://www.roblox.com/games/11704713454/CodeCombat-Worlds-Lua-Coding-RPG',
            },
            {
              linkText: $.i18n.t('hoc_page.view_lesson'),
              link: 'https://drive.google.com/drive/folders/1jZsCvi86jI5XXxwUpXAv4U3N_ZtR4uzv?usp=sharing',
            },
          ],
        },
        {
          title: $.i18n.t('hoc_page.goblins_glory_title'),
          text: $.i18n.t('hoc_page.goblins_glory_text'),
          labels: [
            $.i18n.t('hoc_page.goblins_glory_label_1'),
            $.i18n.t('hoc_page.goblins_glory_label_2'),
          ],
          image: '/images/pages/hoc/04.webp',
          links: [
            {
              linkText: $.i18n.t('hoc_page.try_activity'),
              link: 'https://codecombat.com/play/goblins-hoc?hour_of_code=true',
            },
            {
              linkText: $.i18n.t('hoc_page.view_lesson'),
              link: 'https://codecombat.com/teachers/resources/hoc-goblins#top',
            },
          ],
        },
        {
          title: $.i18n.t('hoc_page.ai_league_title'),
          text: $.i18n.t('hoc_page.ai_league_text'),
          labels: [
            $.i18n.t('hoc_page.ai_league_label_1'),
            $.i18n.t('hoc_page.ai_league_label_2'),
          ],
          image: '/images/pages/hoc/05.webp',
          links: [
            {
              linkText: $.i18n.t('hoc_page.try_activity'),
              link: 'https://codecombat.com/play/ai-league-hoc?hour_of_code=true',
            },
            {
              linkText: $.i18n.t('hoc_page.view_lesson'),
              link: 'https://codecombat.com/teachers/resources/hoc-ai-league',
            },
          ],
        },
        {
          title: $.i18n.t('hoc_page.ozaria_title'),
          text: $.i18n.t('hoc_page.ozaria_text'),
          labels: [
            $.i18n.t('hoc_page.ozaria_label_1'),
            $.i18n.t('hoc_page.ozaria_label_2'),
          ],
          image: '/images/pages/hoc/06.webp',
          links: [
            {
              linkText: $.i18n.t('hoc_page.try_activity'),
              link: 'https://www.ozaria.com/play/chapter-1-sky-mountain?hour_of_code=true',
            },
            {
              linkText: $.i18n.t('hoc_page.view_lesson'),
              link: 'https://docs.google.com/presentation/d/1KgFOg2tqbKEH8qNwIBdmK2QbHvTsxnW_Xo7LvjPsxwE/edit?usp=sharing',
            },
          ],
        },
        {
          title: $.i18n.t('hoc_page.escape_dungeon_title'),
          text: $.i18n.t('hoc_page.escape_dungeon_text'),
          labels: [
            $.i18n.t('hoc_page.escape_dungeon_label_1'),
            $.i18n.t('hoc_page.escape_dungeon_label_2'),
          ],
          image: '/images/pages/hoc/07.webp',
          links: [
            {
              linkText: $.i18n.t('hoc_page.try_activity'),
              link: 'https://codecombat.com/play/dungeon?hour_of_code=true',
            },
            {
              linkText: $.i18n.t('hoc_page.view_lesson'),
              link: 'https://codecombat.com/teachers/resources/hoc',
            },
          ],
        },
        {
          title: $.i18n.t('hoc_page.beginner_game_dev_title'),
          text: $.i18n.t('hoc_page.beginner_game_dev_text'),
          labels: [
            $.i18n.t('hoc_page.beginner_game_dev_label_1'),
            $.i18n.t('hoc_page.beginner_game_dev_label_2'),
          ],
          image: '/images/pages/hoc/08.webp',
          links: [
            {
              linkText: $.i18n.t('hoc_page.try_activity'),
              link: 'https://codecombat.com/play/game-dev-hoc?hour_of_code=true',
            },
          ],
        },
        {
          title: $.i18n.t('hoc_page.intermediate_game_dev_title'),
          text: $.i18n.t('hoc_page.intermediate_game_dev_text'),
          labels: [
            $.i18n.t('hoc_page.intermediate_game_dev_label_1'),
            $.i18n.t('hoc_page.intermediate_game_dev_label_2'),
          ],
          image: '/images/pages/hoc/09.webp',
          links: [
            {
              linkText: $.i18n.t('hoc_page.try_activity'),
              link: 'https://codecombat.com/play/hoc-2018',
            },
            {
              linkText: $.i18n.t('hoc_page.view_lesson'),
              link: 'http://files.codecombat.com/docs/resources/hourofcode/HourofCodeCodeCombatLessonPlan2018.pdf',
            },
          ],
        },
        {
          title: $.i18n.t('hoc_page.advanced_game_dev_title'),
          text: $.i18n.t('hoc_page.advanced_game_dev_text'),
          labels: [
            $.i18n.t('hoc_page.advanced_game_dev_label_1'),
            $.i18n.t('hoc_page.advanced_game_dev_label_2'),
          ],
          image: '/images/pages/hoc/10.webp',
          links: [
            {
              linkText: $.i18n.t('hoc_page.try_activity'),
              link: 'https://codecombat.com/play/game-dev-hoc-2?hour_of_code=true',
            },
          ],
        },
      ],
    }
  },

  computed: {
    me () {
      return me
    },
  },

  metaInfo: function () {
    return {
      title: this.$t('teacher.hoc_title'),
      meta: [
        { vmid: 'meta-description', name: 'description', content: this.$t('teacher.hoc_meta_description') },
      ],
    }
  },
}
</script>

<style scoped lang="scss">
@import 'app/styles/component_variables.scss';

#page-hoc {
  overflow: hidden;

  ::v-deep {
    @extend %frontend-page;

    .box__div .info {
      > * {
        order: 10;
      }

      > .title {
        order: 0;
      }
      > p {
        order: 1;
        margin-top: 0;
        .info__label {
          color: $dark-grey;
        }
      }

      .learn-more-buttons-container {
        margin-top: auto;
      }

      button {
        svg {
          display: none;
        }
      }
    }
  }

  .header-container {
    padding-top: 40px;
  }

  .more-activities {
    padding-bottom: 20px;
  }

}
</style>
