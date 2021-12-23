export function hasSharedWriteAccessPermission(classroom) {
  return (classroom.permissions || []).find((p) => p.target === me.get('_id') && p.access === 'write')
}
