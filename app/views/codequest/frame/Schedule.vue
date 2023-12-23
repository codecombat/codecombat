<template>
  <div class="schedule">
    <DayCard
      day-title="Monday"
      date="07/22/2024"
      event-title="Travel Day"
      event-subtitle="Arrival"
      image-src="/images/pages/codequest/schedule/arrival.svg"
      title-class="title-2"
    />
    <DayCard
      day-title="Tuesday"
      date="07/23/2024"
      event-title="San Francisco"
      event-subtitle="Tour"
      image-src="/images/pages/codequest/schedule/tour.svg"
      title-class="title-3"
    />
    <DayCard
      day-title="Wednesday"
      date="07/24/2024"
      event-title="UC Berkeley"
      event-subtitle="Hackathon"
      image-src="/images/pages/codequest/schedule/hackathon.svg"
      title-class="title-2"
      :for-all="true"
    />
    <DayCard
      day-title="Thursday"
      date="07/25/2024"
      event-title="Silicon Valley"
      event-subtitle="Tours &amp; Speakers"
      image-src="/images/pages/codequest/schedule/speakers.svg"
      title-class="title-4"
      :for-all="true"
    />
    <DayCard
      day-title="Friday"
      date="07/26/2024"
      event-title="Stanford"
      event-subtitle="Hackathon"
      image-src="/images/pages/codequest/schedule/hackathon.svg"
      title-class="title-2"
      :for-all="true"
    />
    <DayCard
      day-title="Saturday"
      date="07/27/2024"
      event-title="Travel Day"
      event-subtitle="Departure"
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
  }
}
</script>

<style scoped>
.schedule {
  align-items: flex-start;
  display: flex;
  gap: 30px;
  position: relative;
  flex-wrap: wrap;
  justify-content: space-between;
  width: 100%;
}
@media (min-width: 1200px) {
  .schedule > * {
    flex: 0 0 calc(16.6667% - 25px);
    max-width: calc(16.6667% - 25px);

  }
}

@media (min-width: 768px) and (max-width: 1199px) {
  .schedule > * {
    flex: 0 0 calc(33.3333% - 20px);
    max-width: calc(33.3333% - 20px);

  }
}

@media (max-width: 767px) {
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
