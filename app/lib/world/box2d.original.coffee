# Box2D is defined in global namespace by box2d_content

# Used to have Box2DJS, but got rid of it.
if Box2D?  # box2dweb, compiled from Flash port: https://code.google.com/p/box2dweb/
  module.exports = window.box2d =
    b2Vec2: Box2D.Common.Math.b2Vec2
    b2BodyDef: Box2D.Dynamics.b2BodyDef
    b2Body: Box2D.Dynamics.b2Body
    b2FixtureDef: Box2D.Dynamics.b2FixtureDef
    b2Fixture: Box2D.Dynamics.b2Fixture
    b2FilterData: Box2D.Dynamics.b2FilterData
    b2World: Box2D.Dynamics.b2World
    b2ContactListener: Box2D.Dynamics.b2ContactListener
    b2MassData: Box2D.Collision.Shapes.b2MassData
    b2PolygonShape: Box2D.Collision.Shapes.b2PolygonShape
    b2CircleShape: Box2D.Collision.Shapes.b2CircleShape
  window.BOX2D_ENABLED = true
else  # no Box2D
  module.exports = null
