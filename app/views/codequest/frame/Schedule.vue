<template>
  <div class="schedule">
    <DayCard
      :day-title="$t('codequest_page.schedule_day_title_1')"
      date="07/22/2024"
      :event-title="$t('codequest_page.schedule_event_title_1')"
      :event-subtitle="$t('codequest_page.schedule_event_sub_title_1')"
      image-src="/images/pages/codequest/schedule/arrival.svg"
      title-class="title-2"
    />
    <DayCard
      :day-title="$t('codequest_page.schedule_day_title_2')"
      date="07/23/2024"
      :event-title="$t('codequest_page.schedule_event_title_2')"
      :event-subtitle="$t('codequest_page.schedule_event_sub_title_2')"
      image-src="/images/pages/codequest/schedule/tour.svg"
      title-class="title-3"
    />
    <DayCard
      :day-title="$t('codequest_page.schedule_day_title_3')"
      date="07/24/2024"
      :event-title="$t('codequest_page.schedule_event_title_3')"
      :event-subtitle="$t('codequest_page.schedule_event_sub_title_3')"
      image-src="/images/pages/codequest/schedule/hackathon.svg"
      title-class="title-2"
      :for-all="true"
    />
    <DayCard
      :day-title="$t('codequest_page.schedule_day_title_4')"
      date="07/25/2024"
      :event-title="$t('codequest_page.schedule_event_title_4')"
      :event-subtitle="$t('codequest_page.schedule_event_sub_title_4')"
      image-src="/images/pages/codequest/schedule/speakers.svg"
      title-class="title-4"
      :for-all="true"
    />
    <DayCard
      :day-title="$t('codequest_page.schedule_day_title_5')"
      date="07/26/2024"
      :event-title="$t('codequest_page.schedule_event_title_5')"
      :event-subtitle="$t('codequest_page.schedule_event_sub_title_3')"
      image-src="/images/pages/codequest/schedule/hackathon.svg"
      title-class="title-2"
      :for-all="true"
    />
    <DayCard
      :day-title="$t('codequest_page.schedule_day_title_6')"
      :date="china ? '07/28/2024' : '07/27/2024'"
      :event-title="$t('codequest_page.schedule_event_title_1')"
      :event-subtitle="$t('codequest_page.schedule_event_sub_title_6')"
      image-src="/images/pages/codequest/schedule/arrival.svg"
      title-class="title-2"
    />
  </div>
</template>

<script>
import DayCard from './DayCard'

export default {
  name: 'ScheduleComponent',
  components: {
    DayCard
  },
  computed: {
    china () {
      return features?.china
    }
  }
}
</script>

<style scoped lang="scss">
@import "app/styles/bootstrap/variables";
.schedule {
  align-items: flex-start;
  display: flex;
  gap: 30px;
  position: relative;
  flex-wrap: wrap;
  justify-content: space-between;
  width: 100%;
}
@media (min-width: $screen-lg) {
  .schedule > * {
    flex: 0 0 calc(16.6667% - 25px);
    max-width: calc(16.6667% - 25px);

  }
}

@media (min-width: $screen-sm) and (max-width: $screen-lg) {
  .schedule > * {
    flex: 0 0 calc(33.3333% - 20px);
    max-width: calc(33.3333% - 20px);

  }
}

@media (max-width: $screen-sm-max) {
  .schedule > * {
    flex: 0 0 calc(50% - 20px);
    max-width: calc(50% - 20px);
  }
}

@media (max-width: 479px) {
  .schedule > * {
    flex: 0 0 calc(100% - 20px);
    max-width: calc(100% - 20px);
  }
}

</style>
