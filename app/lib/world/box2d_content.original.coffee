# This file is a hack to work around some places that depend on window.box2d and
#   window.BOX2D_ENABLED to be set in a certain order.
# Especially: Adding a Thang in the Editor needs BOX2D_ENABLED to be false to
#   prevent trying (and failing) to set up the Collision system for that thang.


# This file is included in the world.js bundle, and executed by world_worker.
window.Box2D = require('exports-loader?Box2D!vendor/scripts/Box2dWeb-2.1.a.3')
