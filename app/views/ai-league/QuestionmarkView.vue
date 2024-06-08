<template>
  <div class="label">
    <v-popover
      popover-class="teacher-dashboard-tooltip lighter-p large-width"
      trigger="hover"
      placement="right"
    >
      <span class="text-wrapper">
        ?
      </span>
      <template slot="popover">
        <div class="content">
          <div class="title">
            {{ $t('teacher_dashboard.global_stats_vs_team_stats') }}
          </div>
          <ul>
            <li>
              <strong>{{ $t('teacher_dashboard.global_stats') }}</strong> {{
                $t('teacher_dashboard.show_stats_for_all_players_and_teams') }}
            </li>
            <li>
              <strong>{{ $t('teacher_dashboard.team_stats') }}</strong> {{
                $t('teacher_dashboard.show_stats_for_individuals_playing_on_the_same_team') }}
            </li>
          </ul>
          <div class="description">
            {{
              $t('teacher_dashboard.for_each_class_you_add_a_team_will_be_automatically_created_for_the_students_in_that_class')
            }}
          </div>
        </div>
      </template>
    </v-popover>
  </div>
</template>

<script>
export default {
  name: 'QuestionmarkView',
}
</script>

<style lang="scss">
.label {
    height: 20px;
    width: 20px;
    background-color: #476FB1;
    border-radius: 20px;
    text-align: center;
    display: flex;
    justify-content: center;
    align-items: center;

    .text-wrapper {
        color: #f7d047;
        font-family: "Work Sans-Bold", Helvetica;
        font-size: 12px;
        font-weight: 700;
        left: 0;
        letter-spacing: 0.33px;
        line-height: 14px;
        text-align: center;
        white-space: nowrap;
    }
}

.content {
    color: #131B25;
    font-feature-settings: 'clig' off, 'liga' off;
    font-family: "Work Sans";
    font-size: 14px;
    line-height: 18px;
    .title {
        font-weight: bold;
        text-transform: uppercase;
        margin-bottom: 20px;
    }
}
</style>
