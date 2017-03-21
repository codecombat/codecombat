# TODO: rework this spec for the InventoryModal

#InventoryView = require 'views/game-menu/InventoryView'
#
#thangTypes = [
#  {"_id":"boots-id","name":"Boots","original":"boots","components":[{"original":"524b85837fc0f6d519000020","majorVersion":0},{"original":"524b7b857fc0f6d519000012","majorVersion":0},{"original":"524b4150ff92f1f4f8000024","majorVersion":0},{"original":"53e12043b82921000051cdf9","majorVersion":0,"config":{"slots":["feet"],"programmableProperties":["move","targetPos"],"moreProgrammableProperties":[],"extraHUDProperties":["maxSpeed"],"stats":{"maxSpeed":{"factor":1}}}},{"original":"524b7b8c7fc0f6d519000013","majorVersion":0,"config":{"locomotionType":"running","maxSpeed":5,"maxAcceleration":100}},{"original":"524b75ad7fc0f6d519000001","majorVersion":0,"config":{"pos":{"x":39.08,"y":20.72,"z":0.5},"width":1,"height":1,"depth":1,"shape":"ellipsoid"}},{"original":"524b7b7c7fc0f6d519000011","majorVersion":0}]},
#  {"_id":"boots-of-leaping-id","name":"Boots of Leaping","original":"boots-of-leaping","components":[{"original":"524b85837fc0f6d519000020","majorVersion":0},{"original":"524b7b857fc0f6d519000012","majorVersion":0},{"original":"524b4150ff92f1f4f8000024","majorVersion":0},{"original":"53e12043b82921000051cdf9","majorVersion":0,"config":{"ownerID":"Tharin","slots":["feet"],"programmableProperties":["move","targetPos","jumpTo"],"moreProgrammableProperties":["jump"],"extraHUDProperties":["maxSpeed"],"stats":{"maxSpeed":{"factor":1.2}}}},{"original":"524b7b8c7fc0f6d519000013","majorVersion":0,"config":{"locomotionType":"running","maxSpeed":6,"maxAcceleration":100}},{"original":"524b1f54d768d916b5000001","majorVersion":0,"config":{"jumpHeight":3}},{"original":"5275392d69abdcb12401441e","majorVersion":0,"config":{"jumpSpeedFactor":1.5}},{"original":"524b75ad7fc0f6d519000001","majorVersion":0,"config":{"pos":{"x":39.08,"y":20.72,"z":0.5},"width":1,"height":1,"depth":1,"shape":"ellipsoid"}},{"original":"524b7b7c7fc0f6d519000011","majorVersion":0}]},
#  {"_id":"crossbow-id","name":"Crossbow","original":"crossbow","components":[{"original":"524b85837fc0f6d519000020","majorVersion":0},{"original":"524b517fff92f1f4f8000046","majorVersion":0},{"original":"524b7b747fc0f6d519000010","majorVersion":0,"config":{"team":"humans"}},{"original":"524b7bc67fc0f6d51900001a","majorVersion":0,"config":{"missileThangID":"Arrow"}},{"original":"524b7ba57fc0f6d519000016","majorVersion":0,"config":{"attackDamage":5,"attackRange":20,"cooldown":0.6,"chasesWhenAttackingOutOfRange":true}},{"original":"524b3e3fff92f1f4f800000d","majorVersion":0},{"original":"524cbdc03ea855e0ab0000bb","majorVersion":0},{"original":"524b4150ff92f1f4f8000024","majorVersion":0},{"original":"53e12043b82921000051cdf9","majorVersion":0,"config":{"slots":["right-hand"],"programmableProperties":["attack","target","attackRange"],"moreProgrammableProperties":["attackXY","targetPos"],"extraHUDProperties":["attackDamage","attackRange"]}},{"original":"524b75ad7fc0f6d519000001","majorVersion":0,"config":{"pos":{"x":41.105000000000004,"y":31.6,"z":0.125},"width":1.5,"height":0.75,"depth":0.25,"shape":"box"}},{"original":"524b7b7c7fc0f6d519000011","majorVersion":0},{"original":"524b457bff92f1f4f8000031","majorVersion":0}]},
#  {"_id":"crude-glasses-id","name":"Crude Glasses","original":"crude-glasses","components":[{"original":"524b7b747fc0f6d519000010","majorVersion":0,"config":{"team":"humans"}},{"original":"524b4150ff92f1f4f8000024","majorVersion":0},{"original":"53e12043b82921000051cdf9","majorVersion":0,"config":{"slots":["eyes"],"programmableProperties":["pos","getEnemies"],"moreProgrammableProperties":["getItems","getFriends"]}},{"original":"524b75ad7fc0f6d519000001","majorVersion":0,"config":{"pos":{"x":33.230000000000004,"y":20.75,"z":2},"width":1,"height":2,"depth":1,"shape":"ellipsoid"}},{"original":"524b457bff92f1f4f8000031","majorVersion":0,"config":{"visualRange":50}}]}
#]
#
#describe 'InventoryView', ->
#  inventoryView = null
#
#  beforeEach (done) ->
#    equipment = { 'feet':'boots', 'eyes': 'crude-glasses' }
#    inventoryView = new InventoryView({ equipment: equipment })
#    responses =
#      '/db/thang.type?view=items': thangTypes
#    jasmine.Ajax.requests.sendResponses(responses)
#    _.defer ->
#      inventoryView.render()
#      done()
#
#  it 'selects a slot when you click it', ->
#    inventoryView.getSlot('eyes').click()
#    expect(inventoryView.getSelectedSlot().data('slot')).toBe('eyes')
#
#  it 'unselects a selected slot when you click it', ->
#    inventoryView.getSlot('eyes').click().click()
#    expect(inventoryView.getSelectedSlot().data('slot')).toBeUndefined()
#
#  it 'selects an available item when you click it', ->
#    inventoryView.getAvailableItemContainer('boots-of-leaping').click()
#    expect(inventoryView.getSelectedAvailableItemContainer().data('item-id')).toBe('boots-of-leaping')
#
#  it 'equips an available item when you double click it', ->
#    inventoryView.getAvailableItemContainer('crossbow').click().dblclick()
#    expect(inventoryView.getCurrentEquipmentConfig()['right-hand']).toBeTruthy()
#
#  it 'unequips an item when you double click it', ->
#    inventoryView.getSlot('eyes').find('.item-view').click().dblclick()
#    expect(inventoryView.getCurrentEquipmentConfig().eyes).toBeUndefined()
