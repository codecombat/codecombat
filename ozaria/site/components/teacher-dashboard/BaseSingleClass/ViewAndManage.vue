<script>
  import Dropdown from '../common/Dropdown'
  import PrimaryButton from '../common/buttons/PrimaryButton'
  import IconButtonWithText from '../common/buttons/IconButtonWithText'

  import { mapActions } from 'vuex'

  export default {
    components: {
      'dropdown': Dropdown,
      'primary-button': PrimaryButton,
      'icon-button-with-text': IconButtonWithText
    },
    props: {
      arrowVisible: {
        type: Boolean,
        default: false
      }
    },
    methods: {
      ...mapActions({
        applyLicenses: 'baseSingleClass/applyLicenses',
        revokeLicenses: 'baseSingleClass/revokeLicenses'
      }),

      clickArrow () {
        if (this.arrowVisible) {
          this.$emit('click-arrow')
        }
      },

      changeSortBy (event) {
        // Will emit one of:
        // 'Name'
        // 'Progress'
        // 'Progress (reversed)'
        this.$emit('change-sort-by', event.target.value)
      }
    }
  }
</script>

<template>
  <div class="view-and-manage">
    <div class="title-card">
      <span>View Options</span>
    </div>
    <div class="spacer align-section-left">
      <dropdown
        label-text="Sort By"
        class="dropdowns"
        :options="['Name', 'Progress', 'Progress (reversed)']"

        @change="changeSortBy"
      />
      <!-- TODO - enable and use jQuery to scroll. -->
      <!-- TODO - use the store to send the signal. -->
      <!-- <dropdown label-text="Go To" class="dropdowns" /> -->
    </div>
    <div class="title-card">
      <span style="width: 59px">Manage Class</span>
    </div>
    <div class="spacer">
      <div class="manage-container">
        <primary-button
          class="primary-btn"
          @click="$emit('assignContent')"
        >
          Assign Content
        </primary-button>
        <icon-button-with-text
          class="icon-with-text"
          icon-name="IconAddStudents"
          text="Add Students"
          @click="$emit('addStudents')"
        />
        <icon-button-with-text
          class="icon-with-text"
          icon-name="IconRemoveStudents"
          text="Remove Students"
          @click="$emit('removeStudents')"
        />
        <icon-button-with-text
          class="icon-with-text larger-icon"
          icon-name="IconLicenseApply"
          text="Apply Licenses"
          @click="applyLicenses"
        />
        <icon-button-with-text
          class="icon-with-text larger-icon"
          icon-name="IconLicenseRevoke"
          text="Revoke Licenses"
          @click="revokeLicenses"
        />
      </div>
    </div>
    <div :class="[arrowVisible ? 'arrow-toggle' : 'arrow-disabled']" @click="clickArrow">
      <transition name="arrow-fade">
        <div v-show="arrowVisible" class="arrow-icon"></div>
      </transition>
    </div>
  </div>
</template>

<style lang="scss">
  /* Change icon size in license buttons */
  .btn-icon-text.larger-icon > img {
    width: 30px;
  }
</style>

<style lang="scss" scoped>
  @import "app/styles/bootstrap/variables";
  @import "ozaria/site/styles/common/variables.scss";
  @import "app/styles/ozaria/_ozaria-style-params.scss";

  .view-and-manage {
    height: 50px;
    max-height: 50px;
    min-width: 1260px;

    display: flex;
    flex-direction: row;
    align-items: center;
    justify-content: space-between;

    position: relative;
    z-index: 11;

    /* Drop shadow bottom ref: https://css-tricks.com/snippets/css/css-box-shadow/ */
    -webkit-box-shadow: 0 7px 6px -6px #D2D2D2;
      -moz-box-shadow: 0 7px 6px -6px #D2D2D2;
          box-shadow: 0 7px 6px -6px #D2D2D2;
  }

  .spacer {
    flex: 1 1 0px;

    display: flex;
    flex-direction: row;
    justify-content: space-around;
    align-items: center;
  }

  .manage-container {
    display: flex;
    min-width: 600px;
    width: 100%;
    max-width: 700px;
    align-items: center;
    justify-content: space-between;
  }

  .align-section-left {
    /* Ensure the first section is half the size. */
    flex: 0.5 0.5 0px;
    justify-content: flex-start;
    justify-content: start;
    min-width: 396px;
  }

  .arrow-icon {
    border: 3px solid #476FB1;
    box-sizing: border-box;
    border-top: unset;
    border-left: unset;
    transform: rotate(45deg);
    width: 9px;
    height: 9px;
  }

  .arrow-toggle, .arrow-disabled {
    width: 62px;
    height: 100%;
    display: flex;
    flex-direction: column;
    justify-content: center;
    align-items: center;

    box-shadow: -1px 0px 1px rgba(0, 0, 0, 0.06), 3px 0px 8px rgba(0, 0, 0, 0.15);
  }

  .arrow-toggle {
    cursor: pointer;
    &:hover {
      background: #eeeced;
      box-shadow: -1px 0px 1px rgba(0, 0, 0, 0.06), 0px 4px 4px rgba(0, 0, 0, 0.25), inset 0px 5px 10px rgba(0, 0, 0, 0.15);
    }
  }

  .title-card {
    width: 100px;
    height: 100%;

    width: 100px;

    display: flex;
    flex-direction: column;

    justify-content: center;
    align-items: center;

    @include font-p-4-paragraph-smallest-gray;
    font-weight: 600;
    color: black;

    box-shadow: -1px 0px 1px rgba(0, 0, 0, 0.06), 3px 0px 8px rgba(0, 0, 0, 0.15);
  }

  .dropdowns {
    margin: 0 8px 0 30px;
  }

  .primary-btn {
    padding: 6px 12px;
  }

  .icon-with-text {
    width: 96px;
    margin: 9px;
  }

  .arrow-fade-enter-active {
    transition: opacity .3s;
    transition-delay: .2s;
  }

  .arrow-fade-leave-active {
    transition: opacity .3s;
  }

  .arrow-fade-leave-to, .arrow-fade-enter  {
    opacity: 0;
  }

  .arrow-fade-enter-to {
    opacity: 1;
  }
</style>
