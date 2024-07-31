<template>
  <div class="pd-box">
    <div class="box-header">
      <h2 class="text-h2">
        {{ formattedTitle }}
        <span class="badge-container">
          <img
            v-if="logoBadge"
            :src="logoBadge"
            class="logo-badge"
          >
        </span>
      </h2>
    </div>
    <div class="row">
      <div class="col col-lg-7 col-md-12">
        <p class="text-p">
          {{ blurb }}
        </p>
        <ul class="golden-bullets">
          <li
            v-for="item, key in list"
            :key="key"
          >
            {{ item }}
          </li>
        </ul>
      </div>
      <div class="col col-lg-5 col-md-12">
        <div
          class="bordered-image"
          :style="image ? `background-image:url(${image})` : ''"
          alt="placeholder"
        />
      </div>
    </div>
    <div class="row">
      <div class="col col-lg-7 col-md-12 buttons-container">
        <ModalGetLicenses
          :show-modal-initially="false"
          :subtitle="modal.subtitle"
          :email-message="modal.emailMessage"
        >
          <template #opener="{ openModal }">
            <button
              class="btn btn-md btn-moon"
              @click="openModal"
            >
              {{ $t('pd_page.get_full_course') }}
            </button>
          </template>
        </ModalGetLicenses>
        <a
          v-for="button, key in buttons"
          :key="key"
          class="btn btn-md btn-moon"
          :href="button.href"
          :target="button.target || '_blank'"
        >
          {{ button.text }}
        </a>
      </div>
      <div class="col col-lg-5 col-md-12 buttons-container right">
        <IframeModal :src="sampleLessonSrc">
          <template #opener="{ openModal }">
            <button
              class="btn btn-md btn-teal"
              @click="openModal"
            >
              {{ $t('pd_page.try_sample_lesson') }}
            </button>
          </template>
        </IframeModal>
      </div>
    </div>
  </div>
</template>

<script>
import ModalGetLicenses from 'app/components/common/ModalGetLicenses'
import IframeModal from './IframeModal.vue'

export default {
  name: 'PDBox',
  components: {
    ModalGetLicenses,
    IframeModal
  },
  props: {
    title: {
      type: String,
      required: true
    },
    blurb: {
      type: String,
      required: true
    },
    list: {
      type: Array,
      required: true
    },
    buttons: {
      type: Array,
      default: () => []
    },
    modal: {
      type: Object,
      default: () => ({})
    },
    image: {
      type: String,
      default: null
    },
    sampleLessonSrc: {
      type: String,
      default: null
    },
    logoBadge: {
      type: String,
      default: null
    }
  },
  computed: {
    formattedTitle () {
      return this.title.replace('[NEWLINE]', ' ')
    }
  }
}
</script>

<style lang="scss" scoped>
@import 'ozaria/site/styles/common/variables.scss';
@import 'app/styles/common/_button.scss';
@import 'app/styles/component_variables.scss';

.pd-box {
  font-family: "Work Sans";

  .btn {
    color: #131B25;
    font-size: 18px;
    font-style: normal;
    text-transform: none;
    font-weight: 600;
    border-radius: 0;
    padding: 1rem;
  }

  .row {
    margin: 10px auto;
  }

  .box-header {
    .text-h2 {
      color: $goldenlight;
      border-bottom: 2px solid $goldenlight;

      font-size: 18px;
      font-weight: 600;
      line-height: 166%;
      text-transform: uppercase;
      text-align: left;
      margin: 10px auto 30px;
    }
  }

  border-radius: 14px;
  box-shadow: 3px 0px 8px 0px rgba(0, 0, 0, 0.15),
  -1px 0px 1px 0px rgba(0, 0, 0, 0.06);
  padding: 20px;

  .text-p {
    color: $grey-6-dark;
    font-size: 20px;
    font-weight: 600;
    line-height: 150%;
    padding: 30px auto;
  }

  .bordered-image {
    border-radius: 30px;
    border: 5px solid $goldenlight;
    width: 100%;
    aspect-ratio: 16 / 9;
    background: linear-gradient(180deg, rgba(0, 0, 0, 0.20) 36%, rgba(0, 0, 0, 0.07) 100%);
    background-size: cover;
    background-position: center;
    align-content: center;
  }
}

.golden-bullets {
  list-style: none;
  padding-left: 0;

  li {
    display: flex;
    align-items: flex-start;
    margin: 10px auto;
  }

  li::before {
    content: "";
    display: inline-block;
    width: 10px;
    height: 10px;
    margin-right: 10px;
    border-radius: 50%;
    background-color: $moon;
    min-width: 10px;
    margin-top: 9px;
  }
}

.buttons-container {
  display: flex;
  justify-content: flex-start;
  flex-direction: row;
  gap: 20px;
  margin-top: 20px;
  margin-bottom: 20px;

  &.right {
    justify-content: flex-end;
  }
}

.badge-container {
  height: 1em;
  display: inline-flex;
  justify-content: center;
  align-items: center;
  position: relative;
  width: 70px;
  margin: auto 10px;
}

.logo-badge {
  width: 70px;
  height: 70px;
  position: absolute;
}
</style>
