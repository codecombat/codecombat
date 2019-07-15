import { storiesOf } from '@storybook/vue'
import { action } from '@storybook/addon-actions'
import { linkTo } from '@storybook/addon-links'

import LayoutChrome from '../ozaria/site/components/common/LayoutChrome.vue'

storiesOf('LayoutChrome', module).add('Default off state', () => ({
  components: { LayoutChrome },
  template: '<layout-chrome />'
}))

storiesOf('LayoutChrome', module).add('On state', () => ({
  components: { LayoutChrome },
  template: '<layout-chrome :chromeOn="true" />'
}))
