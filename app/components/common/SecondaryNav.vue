<script>
export default Vue.extend({
  name: 'SecondaryNav',
  props: {
    titleI18n: {
      type: String,
      default: ''
    },
    urls: {
      type: Array,
      default () {
        return []
      }
    }
  },
  methods: {
    path () {
      return document.location.pathname
    }
  }
})
</script>

<template>
  <div id="secondary-nav">
    <nav class="navbar">
      <div class="container-fluid container">
        <div class="navbar-header">
          <button
            class="navbar-toggle collapsed"
            type="button"
            data-toggle="collapse"
            data-target="#secondary-nav-collapse"
          >
            <span class="sr-only"> {{ $t('nav.toggle_nav') }}</span>
            <span class="icon-bar" />
            <span class="icon-bar" />
            <span class="icon-bar" />
          </button>
          <span class="navbar-brand text-h4"> {{ $t(titleI18n) }}</span>
        </div>
        <div
          id="secondary-nav-collapse"
          class="collapse navbar-collapse"
        >
          <ul class="nav navbar-nav">
            <li
              v-for="u in urls"
              :key="u.url"
              :class="{active: path() === u.url}"
            >
              <a
                class="track-clik-event"
                :href="u.url"
                :data-event-action="u.action"
              >
                <small class="label">{{ $t(u.i18n) }}</small>
              </a>
            </li>
          </ul>
        </div>
      </div>
    </nav>
  </div>
</template>

<style lang="scss">
@import "app/styles/bootstrap/variables";
@import "app/styles/mixins";
@import "app/styles/style-flat-variables";

#secondary-nav {
  vertical-align: middle;
  text-transform: uppercase;

  .navbar {
    border-radius: 0;
    background: $navy;

    .navbar-toggle {
      border-color: white;
    }

    .icon-bar {
      background-color: white;
    }

    .navbar-brand {
      color: white;
      padding-top: 11px;
      padding-bottom: 11px;
    }

    li {
      &.active,
      &.label {
        padding-left: 0;
        padding-right: 0;
        padding-bottom: 0;
        margin-left: 0.6em;
        margin-right: 0.6em;
        border-bottom: 4px solid white;
        border-radius: 0;
      }

      a {
        font-family: $body-font;
        padding: 13px 12px 21px 12px;

        &:hover  {
          background-color: white;

          small {
            color: $navy;
          }
        }
      }
    }
  }
}
</style>
