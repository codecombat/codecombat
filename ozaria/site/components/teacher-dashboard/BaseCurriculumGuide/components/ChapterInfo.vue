<script>
  import IconHelp from '../../common/icons/IconHelp'
  import BaseVideo from 'app/components/common/BaseVideo'
  import Modal from 'app/components/common/Modal'


  import ButtonPlayChapter from './ButtonPlayChapter'
  import ButtonSolutionGuide from './ButtonSolutionGuide'
  import { getOzariaAssetUrl } from 'ozaria/site/common/ozariaUtils'

  const Campaigns = require('collections/Campaigns');


import { mapGetters } from 'vuex'
import utils from 'app/core/utils'

  export default {
    components: {
      IconHelp,
      ButtonPlayChapter,
      ButtonSolutionGuide,
      BaseVideo,
      Modal,
    },

    data(){
      return {
        levelsNameMap: {}
      }
    },

    created () {
      const campaigns = new Campaigns([], { forceCourseNumbering: true });
      campaigns.fetchByType('course', { data: { project: 'levels,levelsUpdated' } });
      campaigns.on('sync', () => {
        const campaign = campaigns.get(this.getCurrentCourse.campaignID);
        this.levelsNameMap = campaign.getLevelNameMap();
      }); 
    },

    computed: {
      ...mapGetters({
        getCurrentCourse: 'baseCurriculumGuide/getCurrentCourse',
        getCapstoneInfo: 'baseCurriculumGuide/getCapstoneInfo',
        getCourseUnitMapUrl: 'baseCurriculumGuide/getCourseUnitMapUrl',
        getSelectedLanguage: 'baseCurriculumGuide/getSelectedLanguage',
        isOnLockedCampaign: 'baseCurriculumGuide/isOnLockedCampaign',
        getTrackCategory: 'teacherDashboard/getTrackCategory'
      }),

      videoLevels () {
        return utils.videoLevels
      },

      courseId () {
        return utils.i18n(this.getCurrentCourse, '_id') || ''
      },

      courseIDs () {
        return utils.courseIDs
      },

    courseName () {
      return utils.i18n(this.getCurrentCourse, 'name') || ''
    },

    courseShortName () {
      return utils.i18n(this.getCurrentCourse, 'shortName') || this.courseName
    },

    courseDescription () {
      return utils.i18n(this.getCurrentCourse, 'description') || ''
    },

    capstoneName () {
      return utils.i18n(this.getCapstoneInfo, 'displayName') || utils.i18n(this.getCapstoneInfo, 'name')
    },

    totalCourseDuration () {
      return this.getCurrentCourse?.duration?.total || 0
    },

      getCourseThumbnail () {
        if (this.getCurrentCourse?.screenshot) {
          if(utils.isCodeCombat){
            return this.getCurrentCourse.screenshot
          } else {
            return getOzariaAssetUrl(this.getCurrentCourse.screenshot)
          }
        }
        const images = [
          '/images/pages/courses/banners/arena-ace-of-coders.png',
          '/images/pages/courses/banners/arena-cavern-survival.png',
          '/images/pages/courses/banners/arena-dueling-grounds.png',
          '/images/pages/courses/banners/arena-gold-rush.png',
          '/images/pages/courses/banners/arena-greed.png',
          '/images/pages/courses/banners/arena-harrowlands.png',
          '/images/pages/courses/banners/arena-sky-span.png',
          '/images/pages/courses/banners/arena-summation-summit.png',
          '/images/pages/courses/banners/arena-treasure-grove.png',
          '/images/pages/courses/banners/arena-wakka-maul-dynamic.png',
          '/images/pages/courses/banners/arena-wakka-maul.png',
          '/images/pages/courses/banners/battle-anya.png',
          '/images/pages/courses/banners/battle-tharin-ogre.png',
          '/images/pages/courses/banners/battle-tharin.png',
          '/images/pages/courses/banners/desert-omarn.png',
          '/images/pages/courses/banners/dungeon-heroes.png',
          '/images/pages/courses/banners/forest-alejandro.png',
          '/images/pages/courses/banners/forest-anya.png',
          '/images/pages/courses/banners/forest-heroes.png',
          '/images/pages/courses/banners/forest-hunting.png',
          '/images/pages/courses/banners/forest-pets.png',
          '/images/pages/courses/banners/game-dev.png',
          '/images/pages/courses/banners/heroes-vs-ogres.png',
          '/images/pages/courses/banners/mountain-heroes.png',
          '/images/pages/courses/banners/wizard-heroes.png'
        ]
        const randomImage = images[Math.floor(Math.random() * images.length)]
        return randomImage
      },

    solutionGuideUrl () {
      if (!this.getCurrentCourse || this.isOnLockedCampaign) {
        return ''
      }

      return `/teachers/course-solution/${this.getCurrentCourse._id}/${this.getSelectedLanguage}?from-new-dashboard=true`
    },

    playChapterUrl () {
      if (this.isOnLockedCampaign) {
        return ''
      }
      return this.getCourseUnitMapUrl || ''
    },

    clickedLink () {
      return !this.isOnLockedCampaign
    }
  },

    methods: {

      getLevelNameMap () {
        const campaign = this.getCurrentCourse;
        const levelNameMap = campaign.getLevelNameMap()
        debugger
        return levelNameMap
      },

      tooltipTimeContent () {
        const time = []

      if (this.getCurrentCourse?.duration?.totalTimeRange) {
        time.push(`<p><b>${Vue.t('teacher_dashboard.class_time_range')}</b> ${utils.i18n(this.getCurrentCourse?.duration, 'totalTimeRange')}</p>`)
      }

      if (this.getCurrentCourse?.duration?.inGame) {
        time.push(`<p><b>${Vue.t('teacher_dashboard.in_game_play_time')}</b> ${utils.i18n(this.getCurrentCourse?.duration, 'inGame')}</p>`)
      }

      return time.join('')
    },

      trackEvent (eventName) {
        if (eventName) {
          window.tracker?.trackEvent(eventName, { category: this.getTrackCategory, label: this.courseName })
        }
      }, 

      onClickVideoThumbnail(e) {
        let video_url;
        $('#video-modal').modal('show');
        const image_src = e.target.src.slice(e.target.src.search('/images'));
        const video = (Object.values(this.videoLevels || {}).find(l => l.thumbnail_unlocked === image_src) || {});
        if (me.showChinaVideo()) {
          video_url = video.cn_url;
        } else {
          video_url = video.url;
          const preferred = me.get('preferredLanguage') || 'en';
          const video_language_code = (video.captions_available || [])
            .find(language_code => (language_code === preferred) || (language_code === preferred.split('-')[0]));
          video_url = video_url.replace(/defaultTextTrack=[\w\d-]+/, 'defaultTextTrack=' + (video_language_code || 'en'));
        }
        $('.video-player')[0].src = video_url;

        return $('#video-modal').on(('hide.bs.modal'), e => {
          return $('.video-player').attr('src', '');
        });
      }
    }
  }
</script>
<template>
  <div>
    <div id="chapter-info">
      <div class="img-container" :style="{'--chapterImage': `url(${getCourseThumbnail})`}">
      </div>
      <div class="info-container">
        <h3>{{ courseShortName }}</h3>
        <p class="chapter-summary">
          {{ courseDescription }}
        </p>
        <div class="stats-and-btns">
          <div>
            <p><b>{{ $t('play_level.level_type_capstone_project') }}</b>: {{ capstoneName }}</p>
            <div
              v-if="totalCourseDuration"
              class="time-row"
            >
              <p>
                <b>{{ $t('teacher_dashboard.class_time') }}</b>: {{ totalCourseDuration }}
              </p>
              <icon-help
                v-if="tooltipTimeContent()"
                v-tooltip.top="{
                  content: tooltipTimeContent,
                  classes: 'teacher-dashboard-tooltip'
                }"
              />
            </div>
          </div>
          <div v-if="!isOnLockedCampaign" class="btns">
            <a :href="playChapterUrl" target="_blank" rel="noreferrer">
              <button-play-chapter
                @click.native="trackEvent('Curriculum Guide: Play Chapter Clicked')"
                v-tooltip.top="{
                  content: $t('teacher_dashboard.want_to_save_tooltip'),
                  classes: 'teacher-dashboard-tooltip lighter-p'
                }"
              />
            </a>
            <a :href="solutionGuideUrl" target="_blank" rel="noreferrer"> <button-solution-guide @click.native="trackEvent('Curriculum Guide: Solution Guide Clicked')" /> </a>
          </div>
          <div v-else class="btns">
            <span
              v-tooltip.top="{
                content: $t('teacher_dashboard.need_licenses_tooltip'),
                classes: 'teacher-dashboard-tooltip',
                autoHide: false
              }"
            >
              <button-play-chapter
                :locked="isOnLockedCampaign"
              />
            </span>
            <span
              v-tooltip.top="{
                content: $t('teacher_dashboard.need_licenses_tooltip'),
                classes: 'teacher-dashboard-tooltip',
                autoHide: false
              }"
            >
              <button-solution-guide
                :locked="isOnLockedCampaign"
              />
            </span>
          </div>
        </div>
      </div>
    </div>
    <div class="video-container" v-if="courseId === courseIDs.INTRODUCTION_TO_COMPUTER_SCIENCE && Object.keys(videoLevels || {}).length > 0">
      <div class="video-item" v-for="(videoLevel, originalId) in videoLevels" :key="originalId" @click="onClickVideoThumbnail">
        <div class="">
          <span class="video-title semibold small">{{ videoLevel.i18name }}</span>
          <img class="video-thumbnail" :src="videoLevel.thumbnail_unlocked" />
          <p class="video-text small">
            <span>(</span>
            <span>{{ levelsNameMap[originalId] }}</span>
            <span>)</span>
          </p>
        </div>
      </div>
    </div>    
    <div id="video-modal" class="modal" :data-show="false">
      <div class="modal-dialog">
        <div class="modal-content video-wrapper">
          <iframe class="video-player" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>
          <button class="video-close-btn btn well well-sm well-parchment" data-dismiss="modal">
            <span class="glyphicon glyphicon-remove"></span>
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
  @import "app/styles/bootstrap/variables";
  @import "ozaria/site/styles/common/variables.scss";
  @import "app/styles/ozaria/_ozaria-style-params.scss";

  #chapter-info {
    display: flex;
    flex-direction: row;

    background-color: #f2f2f2;

    .img-container {
      max-width: 256px;
      width: 100%;

      margin-right: 30px;

      display: flex;
      align-items: center;

      background-image: var(--chapterImage);

      background-position: center;
      background-size: auto 100%;
      background-repeat: no-repeat;
    }

    .time-row {
      display: flex;
      flex-direction: row;

      & > img {
        margin-left: 9px;
      }
    }

    h3 {
      @include font-h-4-nav-uppercase-black;
      color: $pitch;
      text-align: left;

      margin: 18px 0 5px;
    }

    p {
      @include font-p-4-paragraph-smallest-gray;
      color: $pitch;
      font-size: 16px;
      line-height: 20px;
      font-style: normal;
      font-weight: normal;
    }

    .chapter-summary {
      margin-right: 60px;
    }
  }

  .info-container {
    display: flex;
    flex-direction: column;
  }

  .stats-and-btns {
    display: flex;
    flex-direction: row;
    align-items: center;
    justify-content: space-between;

    margin-bottom: 18px;
    margin-right: 60px;

    & > div {
      /* Ensure containers are evenly distributed */
      flex: 1 1 auto;
    }

    .btns {
      display: flex;
      justify-content: space-around;

      &.locked a {
        cursor: default;
      }

      a {
        text-decoration: none;
      }
    }

    p {
      margin-bottom: 5px;
    }
  }

  .video-container {
    display: flex;
    flex-direction: row;
    justify-content: space-between;
    align-items: center;

    margin: 30px 30px 30px;
    gap: 30px;

    .video-item {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;

      cursor: pointer;

      .video-title {
        @include font-h-4-nav-uppercase-black;
        color: $pitch;
        text-align: center;

        margin: 18px 0 5px;
      }

      .video-thumbnail {
        width: 100%;
        height: 100%;
        object-fit: cover;
      }

      .video-text {
        @include font-p-4-paragraph-smallest-gray;
        color: $pitch;
        font-size: 16px;
        line-height: 20px;
        font-style: normal;
        font-weight: normal;
      }
    }
  }


  #video-modal{
    .modal-dialog {
      width: 90vw;
      margin: auto 5vw;
      padding: 0;
    }
    
    .video-wrapper {
      position: relative;
      margin-top: 10%;
      width: 100%;
      height: 100%;

      .video-player {
        position: absolute;
        width: 100%;
        height: 580px;
        background-color: #000000;
      }

      .video-close-btn {
        position: absolute;
        right: -5px;
        color: white;
        top: -5px;
        background: #ba1d00;
        padding: 6px 6px 3px;
        border: 2px solid #14110e;
        border-radius: 0px;
      }
    }
  }


</style>
