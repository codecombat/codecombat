<template>
  <content-box class="pd-box">
    <template #text>
      <div class="box-header">
        <h2 class="text-h2">
          {{ formattedTitle }}
          <span
            v-for="logoBadge in logoBadges"
            :key="logoBadge"
            class="badge-container"
          >
            <img

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
              <CTAButton
                @clickedCTA="openModal"
              >
                {{ $t('pd_page.get_full_course') }}
              </CTAButton>
            </template>
          </ModalGetLicenses>
          <CTAButton
            v-for="button, key in buttons"
            :key="key"
            :href="button.href"
            :target="button.target || '_blank'"
          >
            {{ button.text }}
          </CTAButton>
        </div>
        <div class="col col-lg-5 col-md-12 buttons-container right">
          <IframeModal :src="sampleLessonSrc">
            <template #opener="{ openModal }">
              <button
                class="btn btn-md btn-teal btn-rounded"
                @click="openModal"
              >
                {{ $t('pd_page.try_sample_lesson') }}
              </button>
            </template>
          </IframeModal>
        </div>
      </div>
    </template>
  </content-box>
</template>

<script>
import ModalGetLicenses from 'app/components/common/ModalGetLicenses'
import IframeModal from './IframeModal.vue'
import CTAButton from 'app/components/common/buttons/CTAButton'
import ContentBox from 'app/components/common/elements/ContentBox'

export default {
  name: 'PDBox',
  components: {
    ModalGetLicenses,
    IframeModal,
    CTAButton,
    ContentBox
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
    logoBadges: {
      type: Array,
      default: () => []
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
    &.btn-rounded {
      border-radius: 8px;
    }
  }

  .row {
    margin: 10px auto;
    width: 100%;
  }

  .box-header {
    width: 100%;
    .text-h2 {
      display: flex;
      color: black;
      border-bottom: 2px solid black;
      font-size: 18px;
      font-weight: 600;
      line-height: 166%;
      text-transform: uppercase;
      text-align: left;
      margin: 10px auto 30px;
    }
  }

  .text-p {
    color: $grey-6-dark;
    font-size: 20px;
    font-weight: 600;
    line-height: 150%;
    padding: 30px auto;
  }

  .bordered-image {
    border-radius: 30px;
    border: 5px solid var(--color-primary);
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
    background-color: var(--color-primary);
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
  width: max-content;
  margin: auto 10px;
  filter: drop-shadow(0px 5px 5px #fff) drop-shadow(0px 5px 5px #fff) drop-shadow(0px 5px 5px #fff) drop-shadow(0px 5px 5px #fff)
}

.logo-badge {
  height: 70px;
  max-width: 140px;
  object-fit: contain;
}

::v-deep {
  .CTA__button {
    font-weight: bold;
  }
}
</style>
