import anime from 'animejs/lib/anime.es.js'

/**
 * Registers the thangs and ThangTypes onto Lanks.
 * Then animates these Lanks to create a cinematic.
 *
 */
export default class CinematicLankBoss {
  registerLank (side, lank) {
    assertSide(side)
    this[side] = lank
  }

  /**
   * Moves either the left or right lank to a given co-ordinates.
   * @param {'left'|'right'} side - the lank being moved.
   * @param {{x, y}} pos - the position in meters to move towards.
   * @param {Number} ms - the time it will take to move.
   */
  moveLank (side, pos = {}, ms = 0) {
    assertSide(side)
    // normalize parameters
    pos.x = pos.x || this[side].thang.pos.x
    pos.y = pos.y || this[side].thang.pos.y
    if (this[side].thang.pos.x === pos.x && this[side].thang.pos.y === pos.y) {
      return
    }
    // Slides a lank to a given position, returning a promise
    // that completes when the tween is complete.
    return new Promise((resolve, reject) => {
      anime({
        targets: this[side].thang.pos,
        x: pos.x,
        y: pos.y,
        duration: ms,
        update: () => { this[side].thang.stateChanged = true },
        complete: resolve
      })
    })
  }

  queueAction (side, action) {
    assertSide(side)
    this[side].queueAction(action)
    return Promise.resolve(null)
  }

  /**
   * Updates the left and right lank if they exist.
   * @param {bool} frameChanged - Needs to be true for Lank updates to occur.
   */
  update (frameChanged) {
    this.left && this.left.update(frameChanged)
    this.right && this.right.update(frameChanged)
  }
}

function assertSide (side) {
  if (!['left', 'right'].includes(side)) {
    throw new Error(`Expected one of 'left' or 'right', got ${side}`)
  }
}
