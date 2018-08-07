describe "China flag marker", ->
    it "China flag is on. Shouldn't be on", ->
        expect(me.onChinaInfra()).toBe false