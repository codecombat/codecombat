// *** Notes
// RootComponent setup for non-game scenes with #site-content-area
// What goes in RootComponent vs. child VueComponent? RootComponent not a Vue component.
// Why are vue components loaded via default property? default is what is exported from .vue file

// TODO: update asana-linked doc

// *** TODOS
// pass data to child components directly, without specificying in UI/jade layer
// ugh, why is world init also in level loader?
// Read the internal architecture docs some more
// simulate a level (host the surface in a component maybe?)
// Read the internal architecture docs some more
// play a shareable
// Vue.js-style test (see Shubhangi recent videos example)
// why do MockPlayView properties have to be static?
// Read the internal architecture docs some more
// what should the file structure be? need to research. can we remove duplicate area structure
// more lightweight root component
// RootComponent name misleading.  VueContainer?

import 'new-vue-world/game/mock-play-component.sass';
import RootComponent from 'views/core/RootComponent';
import {default as LoadLevelComponent} from 'new-vue-world/game/LoadLevelComponent.vue';
import {default as UserCodeComponent} from 'new-vue-world/game/UserCodeComponent.vue';
import {default as GameSimulationComponent} from 'new-vue-world/game/GameSimulationComponent.vue';

const MockPlayComponent = Vue.extend({
  name: 'mock-play-component',
  props: ['levelId', 'supermodel'],
  template: require('new-vue-world/game/mock-play-component.jade')(),
  components: {
    'load-level': LoadLevelComponent,
    'user-code': UserCodeComponent,
    'game-simulation': GameSimulationComponent
  }
});

class MockPlayView extends RootComponent {
  constructor(options, levelId) {
    super();
    this.propsData = {levelId, supermodel: this.supermodel};
  }
};
Object.assign(MockPlayView.prototype, {
  id:'mock-play-view',
  template: require('new-vue-world/game/base-game.jade'),
  VueComponent: MockPlayComponent,
});
module.exports = MockPlayView
