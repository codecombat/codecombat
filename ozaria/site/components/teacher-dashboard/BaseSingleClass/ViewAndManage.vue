<script>
  import Dropdown from '../common/Dropdown'
  import PrimaryButton from '../common/buttons/PrimaryButton'
  import IconButtonWithText from '../common/buttons/IconButtonWithText'

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
  <div class="guidelines-nav">
    <div class="title-card">
      <span>View Options</span>
    </div>
    <div class="spacer">
      <dropdown
        label-text="Sort By"
        class="dropdowns"
        :options="['Name', 'Progress', 'Progress (reversed)']"

        @change="changeSortBy"
      />
      <!-- TODO - enable and use jQuery to scroll. -->
      <!-- <dropdown label-text="Go To" class="dropdowns" /> -->
    </div>
    <div class="title-card">
      <span style="width: 59px">Manage Class</span>
    </div>
    <div class="spacer">
      <primary-button
        class="primary-btn"
        @click="$emit('assignContent')"
      >
        Assign Content
      </primary-button>
      <icon-button-with-text
        icon-name="IconAddStudents"
        text="Add Students"
        @click="$emit('addStudents')"
      />
      <icon-button-with-text
        icon-name="IconRemoveStudents"
        text="Remove Students"
        @click="$emit('removeStudents')"
      />
      <icon-button-with-text
        icon-name="IconRemoveStudents"
        text="Apply Licenses"
        @click="$emit('applyLicenses')"
      />
      <icon-button-with-text
        icon-name="IconRemoveStudents"
        text="Revoke Licenses"
        @click="$emit('revokeLicenses')"
      />
    </div>
    <div :class="[arrowVisible ? 'arrow-toggle' : 'arrow-disabled']" @click="clickArrow">
      <transition name="arrow-fade">
        <div v-show="arrowVisible" class="arrow-icon"></div>
      </transition>
    </div>
  </div>
</template>

<style lang="scss" scoped>
  @import "app/styles/bootstrap/variables";
  @import "ozaria/site/styles/common/variables.scss";
  @import "app/styles/ozaria/_ozaria-style-params.scss";

  .guidelines-nav {
    height: 50px;
    max-height: 50px;

    display: flex;
    flex-direction: row;
    align-items: center;
    justify-content: space-between;

    /* Drop shadow bottom ref: https://css-tricks.com/snippets/css/css-box-shadow/ */
    -webkit-box-shadow: 0 7px 6px -6px #D2D2D2;
      -moz-box-shadow: 0 7px 6px -6px #D2D2D2;
          box-shadow: 0 7px 6px -6px #D2D2D2;
  }

  .spacer {
    flex: 1 1 0px; // ensure spacers are equal size

    display: flex;
    flex-direction: row;
    justify-content: space-around;
    align-items: center;
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
    &:hover {
      background: #eeeced;
      box-shadow: -1px 0px 1px rgba(0, 0, 0, 0.06), 0px 4px 4px rgba(0, 0, 0, 0.25), inset 0px 5px 10px rgba(0, 0, 0, 0.15);
    }
  }

  .title-card {
    width: 100px;
    height: 100%;

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
    margin: 0 8px;
  }

  .primary-btn {
    padding: 6px 12px;
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
