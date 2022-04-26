/**
 * This system stores additional command state that must be run when undoing commands.
 * We use this system to store additional information required to undo various commands.
 *
 * It is also a singleton because it was easier to sneak it into commands.
 */
class UndoSystem {
  constructor () {
    this.reset()
  }

  reset () {
    // These commands are side effects required to undo forward commands.
    this.additionalCommandStateStack = []

    // We populate this stack from the cinematicCommandRunner, and these are
    // the commands that run the cinematic forward.
    this.undoCommandStack = []

    // The undo commands for a current shot.
    this.currentNodeUndoCommands = []

    this._ignoreUndoCommands = false
    this.markFirstStopPoint = null
  }

  set ignoreUndoCommands (v) {
    this._ignoreUndoCommands = v
  }

  get ignoreUndoCommands () {
    return this._ignoreUndoCommands
  }

  get canUndo () {
    if (this.markFirstStopPoint === null) {
      return this.undoCommandStack.length > 0
    } else {
      return this.undoCommandStack.length > this.markFirstStopPoint
    }
  }

  // We need to store commands that we can play forward separate from commands we
  // use to undo state. This allows us to navigate backwards and reconstruct the
  // command state.
  pushUsedForwardCommands (playedCommands) {
    if (!Array.isArray(playedCommands)) {
      throw new Error(`Undo system has exploded. Expected array of commands and got: ${typeof playedCommands} - ${playedCommands}`, )
    }
    this.undoCommandStack.push(playedCommands)
  }

  // Pop commands required to undo effects as well as forward commands to shift
  // on the command list.
  popUndoCommands () {
    if (this.additionalCommandStateStack.length === 0) {
      throw new Error('There are no undo commands to undo.')
    }
    const undoCommands = this.additionalCommandStateStack.pop()
    undoCommands.reverse()
    return {
      forwardCommands: this.undoCommandStack.pop(),
      undoCommands
    }
  }

  /**
   * Pushes a single undo effect command. Used to undo effect operations.
   * @param {AbstractCommand} command that causes an effect.
   */
  pushUndoCommand (command) {
    if (!this._ignoreUndoCommands) {
      this.currentNodeUndoCommands.push(command)
    }
  }

  // The first array of commands is not always the start of the cinematic.
  // This can be called from the cinematic controller in order to communicate
  // when the setup and first dialog node has concluded.
  // Thus the undo system can preventing navigating before this point and creating
  // a strange user experience where the shot is partially set up.
  tryMarkFirstStoppingPoint () {
    if (this.markFirstStopPoint === null) {
      this.markFirstStopPoint = this.additionalCommandStateStack.length
    }
  }

  /**
   * Called when a node stops playing.
   */
  endPlayingShot () {
    if (this._ignoreUndoCommands) {
      return
    }
    this.additionalCommandStateStack.push(this.currentNodeUndoCommands)
    this.currentNodeUndoCommands = []
  }
}

const UndoSystemSingleton = new UndoSystem()

export default UndoSystemSingleton
