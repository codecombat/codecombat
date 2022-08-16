export function getDisplayPermission (permission) {
  const display = permission?.toLowerCase()
  return $.i18n.t(`teacher_dashboard.${display}`)
}

export function hasPermission (permission, { ownerId, permissions }) {
  if (me.id === ownerId) return true
  if (me.isAdmin()) return true
  if (permission !== 'read' && permission !== 'write') return false
  return !!(permissions || []).find(p => p.target === me.id && p.access === permission)
}

export function hasSharedWriteAccessPermission (classroom) {
  return (classroom.permissions || []).find((p) => p.target === me.get('_id') && p.access === 'write')
}
