<template>
  <div v-if="convertedDayTime" class="day-time-component">
    <div class="label-text">{{label}}</div>
    <div class="form-row">
      <div class="form-group col-md-5 day-selector">
        <select
          class="form-control"
          @change="updateSelectedDay"
        >
          <option selected disabled>Select Preferred Day</option>
          <option
            v-for="(times, day) in convertedDayTime.dayWise"
            :key="day"
            :value="day"
            v-if="times.length > 0"
          >
            {{day}}
          </option>
        </select>
      </div>
      <div class="form-group col-md-5">
        <select
          class="form-control"
          @change="updateSelectedTime"
        >
          <option selected disabled>Select Preferred Time</option>
          <option
              v-for="timeObj in getTimeBasedOnDay"
              :key="timeObj.time"
              :value="`${timeObj.time}-${timeObj.id}`"
          >
            {{getDisplayTime(timeObj.time)}}
          </option>
        </select>
      </div>
      <div class="form-group col-md-2 timezone-info">
        <div class="timezone">{{this.convertedDayTime.timezone.name}}</div>
        <div>({{this.convertedDayTime.timezone.offsetString}})</div>
      </div>
    </div>
  </div>
</template>

<script>
import moment from 'moment';
let id = 1;
export default {
  name: "DayTimeInputComponent",
  props: {
    label: {
      type: String,
      required: true,
    },
  },
  data () {
    return {
      utcDayTime: this.getUtcDefaultData(),
      convertedDayTime: null,
      selectedDay: null,
      selectedTime: null,
    }
  },
  created() {
    this.convertedDayTime = this.convertUtcToUserTimezoneData();
  },
  computed: {
    getTimeBasedOnDay() {
      return this.convertedDayTime.dayWise[this.selectedDay];
    },
  },
  methods: {
    getUtcDefaultData() {
      return {
        dayWise: {
          Sunday: this.getUtcDefaultDayTimes(),
          Monday: this.getUtcDefaultDayTimes(),
          Tuesday: this.getUtcDefaultDayTimes(),
          Wednesday: this.getUtcDefaultDayTimes(),
          Thursday: this.getUtcDefaultDayTimes(),
          Friday: this.getUtcDefaultDayTimes(),
          Saturday: this.getUtcDefaultDayTimes()
        },
        timezone: {
          name: 'UTC',
          offsetString: '00:00',
          offset: 0,
        },
      };
    },
    getUtcDefaultDayTimes() {
      const startTimeInMin = 12 * 60;
      const endTimeInMin = 24 * 60;
      const diff = 60;
      const timeInMin = [];
      for (let val = startTimeInMin; val <= endTimeInMin; val += diff) {
        timeInMin.push({ time: val, id: id++ });
      }
      return timeInMin;
    },
    getOffsetBasedOfUserTimezone() {
      return moment().parseZone().utcOffset();
    },
    convertUtcToUserTimezoneData() {
      const clonedData = JSON.parse(JSON.stringify(this.utcDayTime));
      const finalData = JSON.parse(JSON.stringify(this.utcDayTime))
      const dayWise = finalData.dayWise;
      let resp;
      resp = this.moveTimesBetweenDay(clonedData.dayWise.Monday);
      dayWise.Monday = resp.currDay;
      dayWise.Sunday = resp.prevDay;
      dayWise.Tuesday = resp.nextDay;

      resp = this.moveTimesBetweenDay(clonedData.dayWise.Tuesday);
      dayWise.Tuesday = dayWise.Tuesday.concat(resp.currDay);
      dayWise.Monday = dayWise.Monday.concat(resp.prevDay);
      dayWise.Wednesday = resp.nextDay

      resp = this.moveTimesBetweenDay(clonedData.dayWise.Wednesday);
      dayWise.Wednesday = dayWise.Wednesday.concat(resp.currDay);
      dayWise.Tuesday = dayWise.Tuesday.concat(resp.prevDay);
      dayWise.Thursday = resp.nextDay

      resp = this.moveTimesBetweenDay(clonedData.dayWise.Thursday);
      dayWise.Thursday = dayWise.Thursday.concat(resp.currDay);
      dayWise.Wednesday = dayWise.Wednesday.concat(resp.prevDay);
      dayWise.Friday = resp.nextDay

      resp = this.moveTimesBetweenDay(clonedData.dayWise.Friday);
      dayWise.Friday = dayWise.Friday.concat(resp.currDay);
      dayWise.Thursday = dayWise.Thursday.concat(resp.prevDay);
      dayWise.Saturday = resp.nextDay

      resp = this.moveTimesBetweenDay(clonedData.dayWise.Saturday);
      dayWise.Saturday = dayWise.Saturday.concat(resp.currDay);
      dayWise.Friday = dayWise.Friday.concat(resp.prevDay);
      dayWise.Sunday = dayWise.Sunday.concat(resp.nextDay)

      resp = this.moveTimesBetweenDay(clonedData.dayWise.Sunday);
      dayWise.Sunday = dayWise.Sunday.concat(resp.currDay);
      dayWise.Saturday = dayWise.Saturday.concat(resp.prevDay);
      dayWise.Monday = dayWise.Monday.concat(resp.nextDay)

      finalData.timezone = {
        name: moment.tz.guess(),
        offsetString: moment().parseZone().format('Z'),
        offset: this.getOffsetBasedOfUserTimezone(),
      };
      return finalData;
    },
    moveTimesBetweenDay(currDay) {
      const offset = this.getOffsetBasedOfUserTimezone();
      const newCurrDay = [];
      const newPrevDay = [];
      const newNextDay = [];
      currDay.forEach((timeObj) => {
        const timeVal = timeObj.time;
        const id = timeObj.id;
        const computedVal = timeVal + offset;
        const minInDay = 24 * 60;
        let final;
        if (computedVal < 0) {
          final = minInDay - Math.abs(computedVal);
          newPrevDay.push({ id, time: final });
        } else if (computedVal >= 24 * 60) {
          final = computedVal - minInDay
          newNextDay.push({ id, time: final });
        } else {
          newCurrDay.push({ id, time: computedVal });
        }
      })
      newCurrDay.sort((a, b) => a.time - b.time);
      newPrevDay.sort((a, b) => a.time - b.time);
      newNextDay.sort((a, b) => a.time - b.time);
      return { currDay: newCurrDay, prevDay: newPrevDay, nextDay: newNextDay };
    },
    getDisplayTime(minutes) {
      let h = Math.floor(minutes / 60);
      let m = minutes % 60;
      h = h < 10 ? '0' + h : h;
      m = m < 10 ? '0' + m : m;
      return `${h}:${m}`;
    },
    updateSelectedDay(e) {
      this.selectedDay = e.target.value;
      this.emitDayTimeEvent();
    },
    updateSelectedTime(e) {
      this.selectedTime = e.target.value;
      this.emitDayTimeEvent();
    },
    emitDayTimeEvent() {
      if (this.selectedDay && this.selectedTime) {
        const timezone = this.convertedDayTime.timezone;
        const splitSelectedTime = this.selectedTime.split('-');
        const selectedTimeValue = parseInt(splitSelectedTime[0]);
        const selectedTimeId = parseInt(splitSelectedTime[1]);
        const event = { day: this.selectedDay, time: `${this.getDisplayTime(selectedTimeValue)} ${timezone.name} (${timezone.offsetString})` }
        let utcData;
        for (let [day, times] of Object.entries(this.utcDayTime.dayWise)) {
          const timezone = this.utcDayTime.timezone;
          for (let option of times) {
            if (option.id === selectedTimeId) {
              utcData = `Day: ${day}, Time: ${this.getDisplayTime(option.time)} ${timezone.name} (${timezone.offsetString})`
              break;
            }
          }
        }
        event.extraInfo = utcData;
        this.$emit('updateDayTime', event)
      }
    }
  }
}
</script>

<style lang="scss" scoped>
.timezone-info {
  font-size: small;
  line-height: 22px;
}
.col-md-3, .col-md-4, .col-md-5 {
  padding-left: 5px;
  padding-right: 5px;
}
.label-text {
  font-weight: bold;
  padding-bottom: 5px;
}
.day-selector {
  padding-left: 0;
}
</style>
