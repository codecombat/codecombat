<template>
  <div class="client-calendar">
    <div id="calendar" />
    <div class="split split-column" />
    <div id="event-details">
      <div class="date title">
        {{ date }}
      </div>
      <div class="split split-row" />
      <div class="content">
        <div class="levels-completed">
          <div class="title">
            {{ $t('events.levels_completed') }} :
          </div>
          <div class="value">
            {{ sessionsOfCampaign }}
          </div>
        </div>
        <div class="notes">
          <div class="title">
            {{ $t('events.teacher_notes') }} :
          </div>
          <div class="value">
            {{ teacherNotes || $t('events.no_teacher_notes') }}
          </div>
          <div
            v-if="teacherNotes"
            class="reply my-btn-light"
            @click="replyNotes"
          >
            {{ $t('events.reply') }}
          </div>
        </div>

        <div class="recording">
          <div
            class="video-recording"
            :class="{clickable: videoRecord}"
            @click="watchRecording"
          >
            <div class="icon-video">
              <div class="second">
                <div class="triangle play" />
              </div>
            </div>
            {{ videoRecord? $t('events.video_recording') : $t('events.no_video_recording') }}
          </div>
        </div>

        <div class="support">
          <div class="reschedule my-btn-dark" />
          <div
            class="contact-us my-btn-light"
            @click="emailTeacher"
          >
            {{ $t('general.contact_us') }}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import Calendar from '@event-calendar/core'
import DayGrid from '@event-calendar/day-grid'
import Interaction from '@event-calendar/interaction'
import _ from 'lodash'
import moment from 'moment'
import { mapGetters, mapMutations, mapActions } from 'vuex'

export default {
  name: 'ClientCalendar',
  props: {
    events: {
      type: Array,
      default: () => []
    }
  },
  data () {
    return {
      ec: null,
      sessions: []
    }
  },
  computed: {
    ...mapGetters({
      propsInstance: 'events/eventPanelInstance',
      completdSessions: 'levelSessions/getSessionsCountForDate'
    }),
    date () {
      return moment(this.propsInstance?.startDate).format('ddd, MMM D')
    },
    teacherNotes () {
      return _.find(this.propsInstance?.members, m => m.userId === me.id)?.description
    },
    sessionsOfCampaign () {
      let str = ''
      for (const [campaign, sessions] of Object.entries(this.sessions)) {
        str += `${sessions.length} levels in ${campaign}\n`
      }
      return str || this.$t('events.no_levels_completed')
    },
    videoRecord () {
      return this.propsInstance?.video
    }
  },
  methods: {
    ...mapMutations({
      selectEvent: 'events/selectEvent'
    }),
    ...mapActions({
      fetchSession: 'levelSessions/fetchSessionsCountForDate'
    }),
    emailTeacher () {
      window.location.href = 'malto:' + this.propsInstance.ownerDetails.email
    },
    replyNotes () {
      this.emailTeacher()
    },
    watchRecording () {
      if (this.videoRecord) {
        window.open(this.videoRecord, '_blank', 'noopener,noreferrer')
      }
    },
    selectDate (info) {
      document.querySelectorAll('.date-selected').forEach(el => el.classList.remove('date-selected'))
      info.el.classList.add('date-selected')
      this.fetchSession({ date: info.event.start?.toISOString() }).then(res => {
        this.sessions = res
      })
      this.selectEvent({ instance: info.event })
    },
    mapEventToCalendar (event, index) {
      return event.instances.map(instance => {
        return {
          id: instance._id?.toString(),
          start: instance.startDate,
          end: instance.endDate,
          title: event.name,
          extendedProps: event
        }
      })
    },
    calendarOptions () {
      const that = this
      return {
        view: 'dayGridMonth',
        eventSources: [{ events: that.createEvents }],
        headerToolbar: { start: 'prev', center: 'title', end: 'next' },
        eventClick (info) {
          console.log('info', info)
          if (info.event.display !== 'pointer') {
            that.selectDate(info)
          }
        }
      }
    },
    createEvents () {
      const today = new Date()

      const events = [
        ...(this.events.map((e, index) => this.mapEventToCalendar(e, index))).flat()
      ]
      return events
    },
    selectRecent () {
      const events = Array.from(document.querySelectorAll('.ec-day'))
      const today = _.findIndex(events, e => e.classList.contains('ec-today'))
      let ev
      for (let i = today; i >= 0; i--) {
        if ((ev = events[i].querySelector('.ec-event'))) {
          ev.click()
          break
        }
      }
    }
  },
  watch: {
    events () {
      this.ec?.refetchEvents()
      setTimeout(() => this.selectRecent(), 500)
    }
  },
  mounted () {
    this.ec = new Calendar({
      target: document.querySelector('#calendar'),
      props: {
        plugins: [DayGrid, Interaction],
        options: this.calendarOptions()
      }
    })
  }
}
</script>

<style lang="scss" scoped>
.client-calendar{
  box-shadow: 3px 0px 8px rgba(0, 0, 0, 0.15), -1px 0px 1px rgba(0, 0, 0, 0.06);
  border-radius: 14px;
  padding-left: 20px;
  display: flex;
  align-items: flex-start;
  .split {
    margin: unset;
    border: 1px solid #D8D8D8;
    box-shadow: 0px 4px 4px rgba(0, 0, 0, 0.06);
  }
  .split-column {
    align-self: center;
    height: 570px;
    width: 0px;
    margin-left: 20px;
    margin-right: 20px;
  }
  .split-row {
    border-top: unset;
    border-bottom: 1px solid #d8d8d8;
    margin-bottom: 26px;
  }

  #calendar {
    flex-grow: 52;
    flex-basis: 0;

    font-family: 'Work Sans';
    font-weight: 600;

    ::v-deep .ec-toolbar {
      padding-bottom: 20px;
      margin-top: 50px;
      @extend .split-row;

      .ec-title {
        font-size: 24px;
        line-height: 28px;
        letter-spacing: 0.56px;
        margin-bottom: 10px;
      }

      .ec-button {
        &.ec-prev, &.ec-next{
          width: 3.8em;
          height: 3.8em;
          border: unset;
          display: flex;
          align-items: center;
          justify-content: center;
          border-radius: 50%;
          background: #476FB1;
          box-shadow: 3px 4px 6px rgba(0, 0, 0, 0.54);
        }

        .ec-icon {
          position: relative;
          width: 0;

          &.ec-prev::before {
            content: '';
            position: absolute;
            top: -1em;
            left: -1em;
            width: 1em;
            height: 2em;
            transform: unset;
            border-right: #f6d157 1em solid;
            border-top: 1em solid transparent;
            border-bottom: 1em solid transparent;
          }
          &.ec-next::before {
            content: '';
            position: absolute;
            top: -1em;
            width: 1em;
            height: 2em;
            transform: unset;
            border-left: #f6d157 1em solid;
            border-top: 1em solid transparent;
            border-bottom: 1em solid transparent;
          }

          &::after {
            transform: unset;
            border: unset;
            content: '';
            position: absolute;
            top: -0.25em;
            width: 1.2em;
            height:0.5em;
            background: #f6d157;
          }

          &.ec-next::after {
            left: -1.2em;
          }
        }
      }
    }
    ::v-deep .ec-header {
      border: none;

      .ec-day {
        border: none;
        font-size: 18px;
        line-height: 30px;
      }
    }

    ::v-deep .ec-body{
      border: none;

      .ec-other-month {
        opacity: 0;
        pointer-events: none;
      }

      .ec-today {
        background-color: unset;

        .ec-day-foot {
          width: 7px;
          height: 7px;
          background-color: #379B8D;
          border-radius: 50%;
          bottom: 20px;
        }
      }
      .ec-days {
        border: none;
      }

      .ec-day {
        flex-direction: column;
        color: #adadad;
        width: 4em;
        height: 4em;
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        border: none;

        &:has(.ec-event) {
          .ec-day-head {
            color: #379B8D;
          }

          &:has(.date-selected) {
            .ec-day-head {
              color: #fff;
              z-index: 2;
            }
          }
        }
      }
      .ec-events {
        position: absolute;

        &:has(.ec-event) {
          width: 70px;
          height: 70px;
          border-radius: 50%;
          margin: 0;
          background: rgba(93, 185, 172, 0.4);

          &:has(.date-selected) {
            background: #379B8D;
          }

          .ec-event {
            position: absolute;
            top: 0;
            left: 0;
            opacity: 0;
            width: 70px;
            height: 70px;
            border-radius: 50%;
          }
        }
      }
    }
  }
  #event-details {
    flex-grow: 40;
    flex-basis: 0;
    align-self: stretch;
    display: flex;
    flex-direction: column;

    .content {
      position: relative;
      padding-bottom: 80px;
      flex-grow: 1;
    }

    .my-btn-light {
      cursor: pointer;
      display: inline-block;
      border: 2px solid #379B8D;
      border-radius: 1px;
      color: #379B8D;
    }
    .my-btn-dark {
      display: inline-block;
      background: #5DB9AC;
      border-radius: 1px;
    }
    .date {
      margin-top: 50px;
      text-align: center;
      font-size: 24px;
      line-height: 28px;
      letter-spacing: 0.56px;
      margin-bottom: 25px;
    }
    .split-row{
      width: 90%;
      height: 0;
    }

    .levels-completed {
      .value {
        min-height: 4em;
      }
    }

    .notes {
      .reply {
        font-size: 14px;
        padding: 5px 45px;
        line-height: 16px;
        font-weight: 600;
      }
    }

    .support {
      position: absolute;
      bottom: 30px;
      right: 22px;
      font-size: 16px;

      .contact-us {
        font-weight: 600;
        padding: 5px 50px;
      }
    }
    .recording {
      margin-top: 40px;

      .video-recording {
        display: flex;
        align-items: center;

        .icon-video {
          filter: grayscale(1);
          width: 43px;
          height: 30px;
          border-radius: 6px;
          background: #5DB9AC;
          margin-right: 10px;

          display: flex;
          align-items: center;
          justify-content: center;

          .second {
            display: flex;
            align-items: center;
            justify-content: center;
            width: 26.5px;
            height: 17px;
            border-radius: 4px;
            background: #4CAAC7;

            .triangle {
              position: relative;
              background-color: #74C6DF;
              text-align: left;
            }
            .triangle:before,
            .triangle:after {
              content: '';
              position: absolute;
              background-color: inherit;
            }
            .triangle,
            .triangle:before,
            .triangle:after {
              width:  4px;
              height: 4px;
              border-top-right-radius: 30%;
            }

            .triangle {
              transform: rotate(30deg) skewX(-30deg) scale(1,.866);
            }
            .triangle:before {
              transform: rotate(-135deg) skewX(-45deg) scale(1.414,.707) translate(0,-50%);
            }
            .triangle:after {
              transform: rotate(135deg) skewY(-45deg) scale(.707,1.414) translate(50%);
            }
          }
        }

        &.clickable {
          cursor: pointer;
          color: #379B8D;

          .icon-video {
            filter: unset;
          }
        }
      }
    }
  }
}
</style>
