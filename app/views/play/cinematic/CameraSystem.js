import { getCamera } from '../../../schemas/selectors/cinematic'
import { SyncFunction } from './Command/commands'

// Seems to be a reasonable default camera.
// TODO: Is this still reasonable with much larger art assets.
export const CAMERA_DEFAULT = {
  pos: {
    x: 0,
    y: 0
  },
  zoom: 6
}

/**
 * Thin wrapper on the camera to provide additional command methods.
 */
export class CameraSystem {
  constructor (camera) {
    this.camera = camera

    camera.zoomTo({ x: CAMERA_DEFAULT.pos.x, y: CAMERA_DEFAULT.pos.y }, CAMERA_DEFAULT.zoom, 0)
  }

  /**
   * May return command to reposition camera.
   * @param {Shot} shot - the cinematic shot data.
   * @returns {AbstractCommand[]} An array of commands to setup the shot.
   */
  parseSetupShot (shot) {
    const commands = []
    const cameraMove = getCamera(shot)
    if (cameraMove) {
      const { pos: { x, y }, zoom } = cameraMove
      commands.push(new SyncFunction(() => this.camera.zoomTo({ x, y }, zoom, 0)))
    }
    return commands
  }
}
