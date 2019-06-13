/* eslint-disable react/react-in-jsx-scope, react/no-this-in-sfc */
import { storiesOf } from '@storybook/vue'
import { action } from '@storybook/addon-actions'
import { linkTo } from '@storybook/addon-links'

import BaseVideo from '../ozaria/site/components/cutscene/common/BaseVideo.vue'

storiesOf('BaseVideo', module).add('vimeo at 1080p size', () => ({
  components: { BaseVideo },
  template: '<base-video :vimeoId="341904732" :width="1920" :height="1080" />'
}))

storiesOf('BaseVideo', module).add('vimeo at ~480p size', () => ({
  components: { BaseVideo },
  template: '<base-video :vimeoId="341904732" :width="640" :height="360" />'
}))

storiesOf('BaseVideo', module).add('video file at 480p size', () => ({
  components: { BaseVideo },
  template: `<base-video
    videoSrc="https://assets.koudashijie.com/CoCo%E7%AE%80%E4%BB%8B.mp4"
    :captions="[{
      label:'English captions',
      src:'/captions/example.vtt',
      srclang:'en'
    }]"
    :width="640"
    :height="480"
  />`
}))

storiesOf('BaseVideo', module).add('video file at 1080p size', () => ({
  components: { BaseVideo },
  template: `<base-video
    videoSrc="https://assets.koudashijie.com/CoCo%E7%AE%80%E4%BB%8B.mp4"
    :captions="[{
      label:'English captions',
      src:'/captions/example.vtt',
      srclang:'en'
    },{
      label:'Example 2 captions',
      src:'/captions/example.vtt',
      srclang:'cn'
    }]"
    :width="1920"
    :height="1080"
  />`
}))
