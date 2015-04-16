(function (lib, img, cjs) {

  var p; // shortcut to reference prototypes
  var rect; // used to reference frame bounds

// stage content:
  (lib.Librarian_SideWalk_JSCC = function(mode,startPosition,loop) {
    this.initialize(mode,startPosition,loop,{Down:0,Up:3,"Down":5,up:8,"Down/":9});

    // R_Heand
    this.instance = new lib.R_Heand_TrW();
    this.instance.setTransform(44.5,72.7,0.818,0.834,0,-3.2,-1.3,35.3,10.3);

    this.timeline.addTween(cjs.Tween.get(this.instance).to({regX:35.1,regY:10.4,scaleX:0.84,scaleY:0.84,rotation:-38,skewX:0,skewY:0,x:42.3,y:69.3},3).to({regX:35.3,scaleX:0.82,scaleY:0.84,rotation:0,skewX:-61,skewY:-59.3,x:44.4,y:77.5},2).to({regX:35.2,scaleX:0.84,scaleY:0.84,rotation:-28.2,skewX:0,skewY:0,x:44.3,y:69.8},3).to({regX:35.3,scaleX:0.82,scaleY:0.83,rotation:0,skewX:-1.9,x:45.4,y:71},1).wait(1));

    // R_Sholder
    this.instance_1 = new lib.L_Sholder_TrW();
    this.instance_1.setTransform(46.7,76,0.833,0.819,0,-33.1,148.8,12.2,18.7);

    this.timeline.addTween(cjs.Tween.get(this.instance_1).to({regX:12.1,regY:18.6,scaleX:0.84,scaleY:0.84,skewX:-32,skewY:147.8,x:47,y:70.7},3).to({scaleX:0.84,scaleY:0.82,skewX:-54.6,skewY:127,x:49.3,y:77.3},2).to({scaleX:0.84,scaleY:0.84,skewX:-32,skewY:147.8,x:48,y:71.3},3).to({regX:12.2,regY:18.7,scaleX:0.83,scaleY:0.82,skewX:-31.6,skewY:150.3,x:47.8,y:72.8},1).wait(1));

    // Head
    this.instance_2 = new lib.Head_01_TrW();
    this.instance_2.setTransform(65.3,53.3,0.842,0.809,0,0,0,35.3,38.9);

    this.timeline.addTween(cjs.Tween.get(this.instance_2).to({regY:39,scaleY:0.84,y:47.4},3).to({scaleY:0.81,y:53.1},2).to({scaleY:0.84,y:47.4},3).to({regY:38.9,y:48.1},1).wait(1));

    // R_Leg
    this.instance_3 = new lib.l_Leg_TrW();
    this.instance_3.setTransform(45.8,109.1,0.837,0.806,0,29.3,23.1,19.4,7.9);

    this.timeline.addTween(cjs.Tween.get(this.instance_3).to({regY:7.8,scaleX:0.84,scaleY:0.67,skewX:-6.9,skewY:-3.3,x:52.8,y:107.3},3).to({regX:19.6,scaleY:0.84,skewX:-24.3,skewY:-3.2,x:55.6,y:110.9},2).to({scaleX:0.83,scaleY:0.85,skewX:15.5,skewY:0.8,x:53.6,y:108.8},3).to({regX:19.3,regY:7.7,scaleX:0.78,scaleY:0.75,skewX:24.5,skewY:9.1,x:50.1,y:109.5},1).wait(1));

    // L_Leg
    this.instance_4 = new lib.R_Leg_TrW();
    this.instance_4.setTransform(74.3,110.8,0.842,0.768,0,-15,180,19.5,8.1);

    this.timeline.addTween(cjs.Tween.get(this.instance_4).to({regX:19.4,regY:8.2,scaleY:0.87,skewX:6,x:71.9,y:109},3).to({regX:19.5,regY:8.3,scaleY:0.76,skewX:21.8,x:63.1,y:111},2).to({regX:19.6,scaleY:0.72,skewX:6.2,skewY:188.5,x:71.3,y:106.1},3).to({regX:19.4,regY:8.2,scaleY:0.87,skewX:-24.1,skewY:180,x:72,y:108.1},1).wait(1));

    // Body
    this.instance_5 = new lib.Body_01_TrW();
    this.instance_5.setTransform(74.5,99.8,0.842,0.768,0,0,0,41.6,48.5);

    this.timeline.addTween(cjs.Tween.get(this.instance_5).to({regY:48.6,scaleY:0.84,y:96.9},3).to({regY:48.5,scaleY:0.77,y:99.7},2).to({regY:48.6,scaleY:0.84,y:96.9},3).to({regY:48.4,scaleY:0.82,y:97.8},1).wait(1));

    // Isolation Mode
    this.instance_6 = new lib.Sword();
    this.instance_6.setTransform(64.5,66.6,1.396,1.396,0,-16.1,163.8,11.8,30.6);

    this.timeline.addTween(cjs.Tween.get(this.instance_6).to({x:64.4,y:60.7},3).to({x:58.3,y:66.3},2).to({x:66.9,y:61.3},3).to({x:66.1,y:63.9},1).wait(1));

    // Plate
    this.instance_7 = new lib.ArmorPart_01_TrW();
    this.instance_7.setTransform(72.6,103.3,0.841,0.813,0,-15.8,-11.4,7.2,8.3);

    this.timeline.addTween(cjs.Tween.get(this.instance_7).to({scaleX:0.84,scaleY:0.84,skewX:-2.5,skewY:0,x:72.1,y:101.3},3).to({regY:8.2,scaleX:0.84,scaleY:0.82,skewX:12.9,skewY:12.1,x:68.2,y:103.8},2).to({scaleX:0.84,scaleY:0.75,rotation:-9.3,skewX:0,skewY:0,x:72.2,y:99.4},3).wait(1).to({scaleY:0.84,rotation:-7,x:71.9,y:102},0).wait(1));

    // Layer 3
    this.instance_8 = new lib.ArmorPart_TrW();
    this.instance_8.setTransform(52.2,102.4,0.912,0.821,0,15.6,4.7,15.1,8.6);

    this.timeline.addTween(cjs.Tween.get(this.instance_8).to({regX:15,regY:8.7,scaleX:0.98,scaleY:0.84,skewX:0,skewY:4.1,x:53.7,y:100.5},3).to({regX:15.1,regY:8.8,scaleX:0.83,scaleY:0.84,skewX:-9.3,skewY:3.9,x:54.1,y:103.4},2).to({regY:8.7,scaleX:0.92,scaleY:0.84,skewX:0,skewY:0.1,x:54.7,y:100.7},3).wait(1).to({regY:8.6,scaleX:0.89,skewY:4.1,x:53.9,y:101.6},0).wait(1));

    // l_Sholder
    this.instance_9 = new lib.L_Sholder_TrW();
    this.instance_9.setTransform(75.2,73.8,0.842,0.81,0,35.5,35,11.4,16.1);

    this.timeline.addTween(cjs.Tween.get(this.instance_9).to({regX:11.3,regY:16,scaleY:0.84,rotation:40.5,skewX:0,skewY:0,y:67.9},3).to({regX:11.4,regY:16.2,scaleY:0.82,rotation:0,skewX:57.4,skewY:56.9,x:72.2,y:72.9},2).to({regY:16,scaleY:0.84,rotation:37,skewX:0,skewY:0,x:75.2,y:67.8},3).to({regY:16.1,scaleY:0.81,rotation:0,skewX:35.5,skewY:35,y:70.9},1).wait(1));

    // L_Heand
    this.instance_10 = new lib.L_Heand_TrW();
    this.instance_10.setTransform(71.2,89,0.842,0.815,0,-1.3,-0.6,7.6,51.4);

    this.timeline.addTween(cjs.Tween.get(this.instance_10).to({x:70.7,y:85.4},3).to({x:66.2,y:89},2).to({x:70.7,y:85.4},3).to({x:72,y:87.3},1).wait(1));

    // Layer 11
    this.shape = new cjs.Shape();
    this.shape.graphics.f("rgba(0,0,0,0.451)").s().p("Ah7BLIgXgJQg8gbgBgnQAAglA9gcQA+gbBUAAQBWAAA9AbQA9AcAAAlQAAAYgWATQgPAMgYALIgXAJQg2AShGAAQhFAAg2gSg");
    this.shape.setTransform(61.5,113);

    this.timeline.addTween(cjs.Tween.get({}).to({state:[{t:this.shape}]}).wait(10));

  }).prototype = p = new cjs.MovieClip();
  p.nominalBounds = rect = new cjs.Rectangle(33.6,20,63.2,102.4);
  p.frameBounds = [rect, new cjs.Rectangle(33.9,17.5,62.9,104.9), new cjs.Rectangle(34.1,15,62.6,107.3), new cjs.Rectangle(34,12.5,62.7,109.8), new cjs.Rectangle(32.8,17.9,60.9,104.5), new cjs.Rectangle(35.3,19.5,55.3,102.9), new cjs.Rectangle(34,17.2,59.5,105.2), new cjs.Rectangle(32.8,14.9,63.6,107.5), new cjs.Rectangle(34.9,12.5,64.3,109.8), new cjs.Rectangle(34.9,13.4,63.5,109)];


// symbols:
  (lib.Sword = function() {
    this.initialize();

    // Isolation Mode
    this.shape = new cjs.Shape();
    this.shape.graphics.f("#FFD15F").s().p("AgTAJQgFgJABgDIADgCIAFADQAGACAGAAQAWAAAFgMQgCAQgGAFQgJAEgHAAQgJAAgKgEg");
    this.shape.setTransform(10,45.8,0.749,0.749,-97.4);

    this.shape_1 = new cjs.Shape();
    this.shape_1.graphics.f("#FFD15F").s().p("AgSAIQgLgHAEgFQAEgGAMgDIAJgBQAQAAAKAJQAEAFgLAGQgKAJgJAAQgIAAgKgHg");
    this.shape_1.setTransform(6.6,46.6,0.749,0.749,-97.4);

    this.shape_2 = new cjs.Shape();
    this.shape_2.graphics.f("#FFD15F").s().p("AgQASQAAgCAFgEQAHgGADgGIAGgOQAEgIACgBQADgBACADQACAEgCACIgLAYQgEAJgEAEQgDACgDAAQgEAAgDgGg");
    this.shape_2.setTransform(8.7,44.1,0.749,0.749,-97.4);

    this.shape_3 = new cjs.Shape();
    this.shape_3.graphics.f("#FFD15F").s().p("AAEAVQgEgDgCgMIgFgOQgCgEgEgDIgDgBIAAgCQAAgEAHgBQADAAACAEIAEAHIAQAcQADAHgFABIgCAAQgEAAgEgDg");
    this.shape_3.setTransform(9.4,48.3,0.749,0.749,-97.4);

    this.shape_4 = new cjs.Shape();
    this.shape_4.graphics.f("#A37605").s().p("AgWACIgHgKIAAgCQAFAAAHAGIAKAGIAHADQAFABAFgFQAOgNAGABQgBAFgGAGQgFAJgFACQgDACgLAAQgNAAgIgLg");
    this.shape_4.setTransform(8.5,46.1,0.749,0.749,-97.4);

    this.shape_5 = new cjs.Shape();
    this.shape_5.graphics.f("#1D2226").s().p("AgrAqQgUgSABgYQgBgYAVgSQASgQAYAAQAZAAASARQAUAQAAAZIAAAAQAAAZgTARQgTARgZAAQgZgBgSgQgAglgjQgQAOAAAVQAAAUARAPQAQAOAUAAQAWAAAPgOQARgPAAgUQABgUgRgQQgPgNgXgBQgVABgQAOg");
    this.shape_5.setTransform(9,46.1,0.749,0.749,-97.4);

    this.shape_6 = new cjs.Shape();
    this.shape_6.graphics.f("#A37605").s().p("AgEAiQgNgCgSgLQgTgLgBgJQgBgFABgMIACgLIAFgCQAFgBACAJIAGAVQAEAIAJAEQAPAGANgCQAUgDAFgSQAFgUAGgGQAEgEAGACQAEABAAARQgBAPgDAFQgEAIgUALQgSALgKAAIgEgBg");
    this.shape_6.setTransform(10.3,45.8,0.749,0.749,-97.4);

    this.shape_7 = new cjs.Shape();
    this.shape_7.graphics.f("#F1B50F").s().p("AgoAmQgSgQAAgWQAAgVASgQQARgQAXAAQAYAAARAQQASAQAAAVQAAAWgSAQQgRAQgYAAQgXAAgRgQg");
    this.shape_7.setTransform(9,46.2,0.749,0.749,-97.4);

    this.shape_8 = new cjs.Shape();
    this.shape_8.graphics.f("#1D2226").s().p("AhQAKIgEAAQgJgBgGgEQgFgDgCgCQgDgEABgGIALACQAAADAEADIALACIADAAIACAAIC6AAIAAAKIi7ABg");
    this.shape_8.setTransform(1,48.2,0.749,0.749,-97.4);

    this.shape_9 = new cjs.Shape();
    this.shape_9.graphics.f("#1D2226").s().p("AgGCVIhEgCIgZgDQgGgDgDgDIgEgKIgBgGIgDhKIgChZIAAguIAEgtIADgGIABgBIAKgEIAWgDIBUgCIA5ABQAUABAKACIAFABIADACIAFAFIAAAAIABADIABAHIACAJIADAEIABABIABACIABAGIADBRIgBBZQAAAXgBAXIgBARIgCAIIgBABIgBACIAAABIgDACIgDABIgEABIgSADQgaABgkAAIgcAAgAgwiEIgwAGIgCAAIAAABIgBAFIgBAhIAAAtIACBZIAEBOIABABIAAAAQAEACAQABIBDACQA7AAAegCIAOgCIAAAAIAAgFIADiRIgEhOIAAgBIgGgCIgBgUIAAgCIABAAIgCgCIABABIAAABIgBAAQgHgCgTgCQgYgDgggBQgeAAgYACg");
    this.shape_9.setTransform(7.1,46.8,0.749,0.749,-97.4);

    this.shape_10 = new cjs.Shape();
    this.shape_10.graphics.f("#1D2226").s().p("AgvASQgggDgQgHIgBAAIgBgCQgDgFABgCQABgFAEgDQAFgDAIgCQALgDANgBQAggBAQABQAwADAtgDIAEAAIAMAhIg2ADIguABIgLAAIgkgBgAg4gKQgQACgHACQgGACgDADIgBABIABAAQAOAGAcAEQATADAbAAIAtgCIAogGIgGgNQgrgEgtAAIgOgBQgUAAgNADg");
    this.shape_10.setTransform(-0.9,47.8,0.749,0.749,-97.4);

    this.shape_11 = new cjs.Shape();
    this.shape_11.graphics.f("#EAD1AE").s().p("AhbADQgJgLAngFQAUgDAVABIBpACIAJAXQgjAEgpACIgXAAQg+AAgYgNg");
    this.shape_11.setTransform(-0.9,47.8,0.749,0.749,-97.4);

    this.shape_12 = new cjs.Shape();
    this.shape_12.graphics.f("#AD3AAD").s().p("AheAbQgKgFgCgLQgCgPABgGQAAgKAGgDQAFgDBcgBQBWgCAGABQAFACADAEQAEAFAAAGQAAAFAEAGIAEAKQAAAFgJAOIi4AAQgEAAgFgCg");
    this.shape_12.setTransform(-0.9,48,0.749,0.749,-97.4);

    this.shape_13 = new cjs.Shape();
    this.shape_13.graphics.f("#70266C").s().p("AhjByQgHgFAAhrQgBhpAIgHQAIgIBeAAQBfgBAFAJQAFAIAABpQgBBpgEAGQgDAGhiAAQhfgBgGgFg");
    this.shape_13.setTransform(8.6,46.5,0.749,0.749,-97.4);

    this.shape_14 = new cjs.Shape();
    this.shape_14.graphics.f("#85632A").s().p("AhGCMQgUgBgFgDQgCgCgCgKQgMjzALgLQAIgJBdAAQBgAAAFAJQAEAJABB5QAAB1gEAHQgDAEhAAGQg3AGgnAAIgMAAg");
    this.shape_14.setTransform(7,47.2,0.749,0.749,-97.4);

    this.addChild(this.shape_14,this.shape_13,this.shape_12,this.shape_11,this.shape_10,this.shape_9,this.shape_8,this.shape_7,this.shape_6,this.shape_5,this.shape_4,this.shape_3,this.shape_2,this.shape_1,this.shape);
  }).prototype = p = new cjs.Container();
  p.nominalBounds = rect = new cjs.Rectangle(-4.6,36.9,23.5,19.9);
  p.frameBounds = [rect];


  (lib.R_Leg_TrW = function() {
    this.initialize();

    // Isolation Mode
    this.shape = new cjs.Shape();
    this.shape.graphics.f("#1D2226").s().p("AABAqIgIgCQgQgDgKgHQgNgJgFgPQgEgKABgOIABgNIACgFQADgEAIgBQAGADACAEIABAEIACALQABAKAEAGQAEAFAEAEQAGAEAJABIAEABIACAAIAEgBQAGgEAFgGQAFgFAFgIIAEgIIACgHIADgBIAHgBIAGACQABAAAAAAQABAAAAAAQAAABABAAQAAAAAAABIABACIAAAHIgCAMQgDAMgIAKQgKAOgLAFQgJAFgJAAg");
    this.shape.setTransform(20.3,14.7,1,1,0,9,-170.9);

    this.shape_1 = new cjs.Shape();
    this.shape_1.graphics.f("#1D2226").s().p("AAGAuIgQgDQgSgDgPgHQgOgHgHgJQgFgHgCgHQgCgIACgIQACgLAFgJIAAgBIABAAQACgFAFgDIAHgDIAOgCQALAAAVACQATACATAEIAAgBIAFABQAGABAFADQAIAEAFAGQAFAGACAGQADAJgDAJIgEAQQgCAIgEAFQgDAFgGADQgGAEgKABIgJABIgVgCgAglgQIgCAAIgDAIIABAGQABACADACIAJAFQAHAEARADIAOACQAMACAIgBIAHgBIAAAAIAFgQIAAgEIgBgCQAAAAAAgBQgBAAAAAAQAAgBgBAAQAAAAgBAAIgFgCIgCAAIgBAAIgPgDQgRgDgPAAIgLgBIgJABg");
    this.shape_1.setTransform(20.9,8.8,1,1,0,9,-170.9);

    this.shape_2 = new cjs.Shape();
    this.shape_2.graphics.f("#654127").s().p("AghAMQAJgCAKgFQATgIAEgSQASgBAFALQADAFgBAGQgCAJgJAHQgIAGgMAAQgOAAgWgKg");
    this.shape_2.setTransform(19.5,14.9,1,1,0,9,-170.9);

    this.shape_3 = new cjs.Shape();
    this.shape_3.graphics.f("#654127").s().p("AgOAfQgagFgIgFQgEgDgCgJQAaAGASgVQAJgMACgNIA1ALQACAQgIANQgNAXggAAQgHAAgKgBg");
    this.shape_3.setTransform(19.7,9.2,1,1,0,9,-170.9);

    this.shape_4 = new cjs.Shape();
    this.shape_4.graphics.f("#965D36").s().p("AAAAhQghgFgJgcQgHgWAJgLQAFAJAOAGQAZAMAqgNQgEAZgHAMQgKAQgSAAIgHgBg");
    this.shape_4.setTransform(20.3,14.4,1,1,0,9,-170.9);

    this.shape_5 = new cjs.Shape();
    this.shape_5.graphics.f("#965D36").s().p("AgDAnQgogIgHgeQgHgWAKgMQAagIAYAAQA0ABgBAoQgDAYgHAIQgIAKgTAAQgJAAgLgDg");
    this.shape_5.setTransform(20.6,10,1,1,0,9,-170.9);

    this.addChild(this.shape_5,this.shape_4,this.shape_3,this.shape_2,this.shape_1,this.shape);
  }).prototype = p = new cjs.Container();
  p.nominalBounds = rect = new cjs.Rectangle(13.7,4.2,14.6,14.7);
  p.frameBounds = [rect];


  (lib.R_Heand_TrW = function() {
    this.initialize();

    // Isolation Mode
    this.shape = new cjs.Shape();
    this.shape.graphics.f("#BF7643").s().p("AgPgPQAAgEAPAEQARAEABAFQAAAGgiASQgDAAAEghg");
    this.shape.setTransform(32.1,15.9);

    this.shape_1 = new cjs.Shape();
    this.shape_1.graphics.f("#BF7643").s().p("AgVAMIAEgZIAnABQAAAMgWAIQgMAGgGAAQgBAAAAAAQgBAAAAAAQgBgBAAAAQAAgBAAAAg");
    this.shape_1.setTransform(31,28.1);

    this.shape_2 = new cjs.Shape();
    this.shape_2.graphics.f("#BF7643").s().p("AgTgHQAAgFARgCQAQgDAHAJQAKALgzANQgEAAAFgXg");
    this.shape_2.setTransform(31.6,21.7);

    this.shape_3 = new cjs.Shape();
    this.shape_3.graphics.f("#1D2226").s().p("AAEAGQgdAAgdAHIgGgRQAegIAiAAQAgAAAZAJIgHAQQgWgHgcAAg");
    this.shape_3.setTransform(34,19.3);

    this.shape_4 = new cjs.Shape();
    this.shape_4.graphics.f("#1D2226").s().p("AggACQgVAAgGABIgBAAIgCgSQAMgBASAAQA1AAAqAQIgIARQglgPgyAAg");
    this.shape_4.setTransform(34.3,25.9);

    this.shape_5 = new cjs.Shape();
    this.shape_5.graphics.f("#1D2226").s().p("AhHgIQAjgKAxAAQAfAAAcAEIgEAcQgagEgdAAQgsAAggAJg");
    this.shape_5.setTransform(34.1,32.3);

    this.shape_6 = new cjs.Shape();
    this.shape_6.graphics.f("#FFB685").s().p("AgdABIgDgRQAlgDAUACQAPACgOAPQgOARgSACIgCAAQgOAAgHgSg");
    this.shape_6.setTransform(31.3,37.9);

    this.shape_7 = new cjs.Shape();
    this.shape_7.graphics.f("#1D2226").s().p("AguCfQgSgIgNgSIgDgEQgMgRgCgWQgBgMACgLQACgMADgKIAOhiQAOhlAFgHQAEgHAJAEIAKAFIgaDRIAAADIgBACQgDAFgBALQgCAJABAIQABANAIALIABACQAKANAMAGQAMAGAKgDQAGgCAGgFIANgJIANgHIAQgHIAGAVIABAAIACgBQAEgDADgGQAFgKABgLQADgfgTgpIAAAAIAAhQQgBhTgBgFIAIADQAFACAEADIADADIAAAEQAFApAJBcQALAgACAnQABAmgJARQgHAOgKAHQgMAIgLgCQgLgBgHgJIgLAIIAAAAQgKAGgKAEQgHACgIAAQgOAAgPgIg");
    this.shape_7.setTransform(33.7,28.9);

    this.shape_8 = new cjs.Shape();
    this.shape_8.graphics.f("#654127").s().p("AgDgiIgWgBIgVgCIAqgZIACgYIAsAPIAFCdIg6ABg");
    this.shape_8.setTransform(35.5,23);

    this.shape_9 = new cjs.Shape();
    this.shape_9.graphics.f("#965D36").s().p("AgohlQBXAbAGAHQABACACAbQABA2AIBUQgLgCg7ACIg7ACg");
    this.shape_9.setTransform(33.7,22.7);

    this.shape_10 = new cjs.Shape();
    this.shape_10.graphics.f("#FFE1CC").s().p("AgTARIAChgIAGgJQAHgCAKAMIANAPQADACgQBIQgNBHgDAHIAAABQgDAAgGhJg");
    this.shape_10.setTransform(29.6,23);

    this.shape_11 = new cjs.Shape();
    this.shape_11.graphics.f("#C1733E").s().p("AgcCPQgsgDgBgrQAVALAXABQArACAMg1QAJgugTghQABgegDhbIAJAAQAKAAAFAEQAIAGAEAsIAFBYQABARgBAMIAGACIAMAxQAGAxgeAEQgJABgIgJQgHgJgDgCQgHAdglAAIgGAAg");
    this.shape_11.setTransform(34.6,29.9);

    this.shape_12 = new cjs.Shape();
    this.shape_12.graphics.f("#1D2226").s().p("AgHASIgIgCQAXgYAIgOIgDAeQgBAKACAFQgMgCgJgDg");
    this.shape_12.setTransform(37.2,39.6);

    this.shape_13 = new cjs.Shape();
    this.shape_13.graphics.f("#EF995E").s().p("AgGBhQgagDgTgdQgSgcADgWQABgNAJgWQAJgbAFgZQACgMATgIQAUgIATAFQA4ANgIBXQgDAagWAgQgXAjgUAAIgEgBg");
    this.shape_13.setTransform(31.1,34.6);

    this.addChild(this.shape_13,this.shape_12,this.shape_11,this.shape_10,this.shape_9,this.shape_8,this.shape_7,this.shape_6,this.shape_5,this.shape_4,this.shape_3,this.shape_2,this.shape_1,this.shape);
  }).prototype = p = new cjs.Container();
  p.nominalBounds = rect = new cjs.Rectangle(24.1,12.2,19.1,33.5);
  p.frameBounds = [rect];


  (lib.L_Sholder_TrW = function() {
    this.initialize();

    // Isolation Mode
    this.shape = new cjs.Shape();
    this.shape.graphics.f("#BF7643").s().p("AgHgMQAFgBAJADQALAEgBAEQgBAEghALg");
    this.shape.setTransform(15.6,17.1,1,1,0,-25.1,154.8);

    this.shape_1 = new cjs.Shape();
    this.shape_1.graphics.f("#1D2226").s().p("Ag4gHIAAgEIAHgLIBqAbIgFASQgHgDhlgbg");
    this.shape_1.setTransform(16.5,21.1,1,1,0,-25.1,154.8);

    this.shape_2 = new cjs.Shape();
    this.shape_2.graphics.f("#1D2226").s().p("Ag1gDIAOgPIAVAUIBGgKIACASQgbACgvAGIgDABg");
    this.shape_2.setTransform(4.8,10.3,1,1,0,-25.1,154.8);

    this.shape_3 = new cjs.Shape();
    this.shape_3.graphics.f("#1D2226").s().p("AAAAJIhBgMIAHgTQAMAIASAFQAOAFAPAEQAhAEAgAAIgBATIhBgOg");
    this.shape_3.setTransform(8.1,13.5,1,1,0,-25.1,154.8);

    this.shape_4 = new cjs.Shape();
    this.shape_4.graphics.f("#1D2226").s().p("AAHBIQgUgBgSgGQgZgHgOgPIgEgEIgBgGQgBgZALgUQAKgVAWgPQARgMAXgGQASgFAZgBIACAeQgVABgRAEQgRAFgNAJQgPAKgHANQgGAMgBANQAIAFAPAFQALADAVAEIAkAEIAJAAQAHgHAJgCIAFADQAAAKgEAKIgBADIgBABIgBACIgDACIgBAAIgEACIgBAAIgOACIgWABIgRgBg");
    this.shape_4.setTransform(8.5,11.4,1,1,0,-25.1,154.8);

    this.shape_5 = new cjs.Shape();
    this.shape_5.graphics.f("#A52F00").s().p("AgcAeQgYgHgTgHIACgOQAsAXAzgcQAbgPASgUQAFAcgMAXQgJAUgLAFIgPABQgYAAghgJg");
    this.shape_5.setTransform(8.2,13.7,1,1,0,-25.1,154.8);

    this.shape_6 = new cjs.Shape();
    this.shape_6.graphics.f("#DD3900").s().p("AhHAgQgCgcASgWQAbgkA7gDQAfAFAIAiQAJAjgeAoIgbABQhDAAgagag");
    this.shape_6.setTransform(7.4,11.9,1,1,0,-25.1,154.8);

    this.shape_7 = new cjs.Shape();
    this.shape_7.graphics.f("#FFE5D4").s().p("AgVAkQABgLARgeIAOgfQACgBAJAAIgaBLQgIgCgJAAg");
    this.shape_7.setTransform(12.1,11.9,1,1,0,-25.1,154.8);

    this.shape_8 = new cjs.Shape();
    this.shape_8.graphics.f("#1D2226").s().p("AASBXQANgWAJgXQAKgbgCgSQgBgXgNgNQgDgEgMgJIgJgEIgDgBIgCACIgIAQIgTAjIgjBKIgYgKQAOgsAOgiQALgaAHgNIALgUIAJgLIAHgGQAIgFAHAAIABAAIACABIAQAFIAOAHQAOAIAKAOQAVAbgEAjQgCAZgOAdQgIARgSAfg");
    this.shape_8.setTransform(12.1,14.7,1,1,0,-25.1,154.8);

    this.shape_9 = new cjs.Shape();
    this.shape_9.graphics.f("#654127").s().p("AglA8IAchAQATg1ADgTQAWgCADA9IgTAmQgTApgCAQg");
    this.shape_9.setTransform(9.4,17.8,1,1,0,-25.1,154.8);

    this.shape_10 = new cjs.Shape();
    this.shape_10.graphics.f("#965D36").s().p("AAHBKQgOgIgLgCIgagCQgSgCgIgDQAOguAVgrQAZg1ALAAIAlAJQAlASgFAzQgEAFgOAkIgSA0QgIgDgTgJg");
    this.shape_10.setTransform(12.2,15.3,1,1,0,-25.1,154.8);

    this.addChild(this.shape_10,this.shape_9,this.shape_8,this.shape_7,this.shape_6,this.shape_5,this.shape_4,this.shape_3,this.shape_2,this.shape_1,this.shape);
  }).prototype = p = new cjs.Container();
  p.nominalBounds = rect = new cjs.Rectangle(-0.3,5.4,22.5,20.2);
  p.frameBounds = [rect];


  (lib.l_Leg_TrW = function() {
    this.initialize();

    // Isolation Mode
    this.shape = new cjs.Shape();
    this.shape.graphics.f("#1D2226").s().p("AABAqIgIgCQgQgDgKgHQgNgJgFgPQgEgKABgOIABgNIACgFQADgEAIgBQAGADACAEIABAEIACALQABAKAEAGQAEAFAEAEQAGAEAJABIAEABIACAAIAEgBQAGgEAFgGQAFgFAFgIIAEgIIACgHIADgBIAHgBIAGACQABAAAAAAQABAAAAAAQAAABABAAQAAAAAAABIABACIAAAHIgCAMQgDAMgIAKQgKAOgLAFQgJAFgJAAg");
    this.shape.setTransform(21.3,14.9,1,1,-9.4);

    this.shape_1 = new cjs.Shape();
    this.shape_1.graphics.f("#1D2226").s().p("AAGAuIgQgDQgSgDgPgHQgOgHgHgJQgFgHgCgHQgCgIACgIQACgLAFgJIAAgBIABAAQACgFAFgDIAHgDIAOgCQALAAAVACQATACATAEIAAgBIAFABQAGABAFADQAIAEAFAGQAFAGACAGQADAJgDAJIgEAQQgCAIgEAFQgDAFgGADQgGAEgKABIgJABIgVgCgAglgQIgCAAIgDAIIABAGQABACADACIAJAFQAHAEARADIAOACQAMACAIgBIAHgBIAAAAIAFgQIAAgEIgBgCQAAAAAAgBQgBAAAAAAQAAgBgBAAQAAAAgBAAIgFgCIgCAAIgBAAIgPgDQgRgDgPAAIgLgBIgJABg");
    this.shape_1.setTransform(20.7,9.1,1,1,-9.4);

    this.shape_2 = new cjs.Shape();
    this.shape_2.graphics.f("#654127").s().p("AghAMQAJgCAKgFQATgIAEgSQASgBAFALQADAFgBAGQgCAJgJAHQgIAGgMAAQgOAAgWgKg");
    this.shape_2.setTransform(22.1,15.1,1,1,-9.4);

    this.shape_3 = new cjs.Shape();
    this.shape_3.graphics.f("#654127").s().p("AgOAfQgagFgIgFQgEgDgCgJQAaAGASgVQAJgMACgNIA1ALQACAQgIANQgNAXggAAQgHAAgKgBg");
    this.shape_3.setTransform(21.9,9.4,1,1,-9.4);

    this.shape_4 = new cjs.Shape();
    this.shape_4.graphics.f("#965D36").s().p("AAAAhQghgFgJgcQgHgWAJgLQAFAJAOAGQAZAMAqgNQgEAZgHAMQgKAQgSAAIgHgBg");
    this.shape_4.setTransform(21.3,14.6,1,1,-9.4);

    this.shape_5 = new cjs.Shape();
    this.shape_5.graphics.f("#965D36").s().p("AgDAnQgogIgHgeQgHgWAKgMQAagIAYAAQA0ABgBAoQgDAYgHAIQgIAKgTAAQgJAAgLgDg");
    this.shape_5.setTransform(21,10.3,1,1,-9.4);

    this.addChild(this.shape_5,this.shape_4,this.shape_3,this.shape_2,this.shape_1,this.shape);
  }).prototype = p = new cjs.Container();
  p.nominalBounds = rect = new cjs.Rectangle(13.4,4.4,14.6,14.7);
  p.frameBounds = [rect];


  (lib.L_Heand_TrW = function() {
    this.initialize();

    // Isolation Mode
    this.shape = new cjs.Shape();
    this.shape.graphics.f("#FFB685").s().p("AgCAIQgKgBgFgHIgEgHQADgBARADQAOACAGACQAHABgKAEQgIAEgIAAIgCAAg");
    this.shape.setTransform(16.3,58.8,0.934,0.934,3.7);

    this.shape_1 = new cjs.Shape();
    this.shape_1.graphics.f("#EF995E").s().p("AgGAQQgNgCgOgOIgLgQQgCgDAKAHQARALALABQAIAAARAAIAXABQAIACgEACIgMAGQgJAHgQAAIgNgCg");
    this.shape_1.setTransform(15.8,58,0.934,0.934,3.7);

    this.shape_2 = new cjs.Shape();
    this.shape_2.graphics.f("#FFB685").s().p("AgRAHQgFgFgBgCQgBgCAPgEIAMgEQALgDADACQADABAEAIQAGAMgeADIgDAAQgJAAgFgGg");
    this.shape_2.setTransform(19.2,53.5,0.934,0.934,3.7);

    this.shape_3 = new cjs.Shape();
    this.shape_3.graphics.f("#1D2226").s().p("AgYAZQgPgFgMgKIgBgBQgIgJgCgKQAAgIADgEQAEgFAFgBQgEAEAAAEQAAAEABAEQAEAIAIAEQAKAEALACQALABAMgCQALgBANgEQAPgDAJgEIAMAZQgOAGgPADQgQACgOAAQgNAAgPgEg");
    this.shape_3.setTransform(17.9,55.3,0.934,0.934,3.7);

    this.shape_4 = new cjs.Shape();
    this.shape_4.graphics.f("#1D2226").s().p("AgJBoQgfgEgUgPQgYgRgHgdQgIggAMgpIABgoIATgIQAEAXACAIIAFARIgBAEQgLAlAGAYQAFATAOALQAOAKATACQANADAKgBIACAAQAOgCAIgFQAGgEAIgJIAHgMQAHgNAAgOQgBgKgDgGQgCgJgEgGIgBgCIgVhSIAJgEQADgCAIAAIAdBNQAFAIADAMQADAIACANQABAZgMATIgJAPQgKAOgMAHQgNAJgVADIgLABg");
    this.shape_4.setTransform(16.3,52.9,0.934,0.934,3.7);

    this.shape_5 = new cjs.Shape();
    this.shape_5.graphics.f("#EF995E").s().p("AghAdQgigagGgUQgEgPAaABQArABAJgDQASgFAcgLQAVgGAFARQAGAWgOAbQgPAggZAHIgJABQgUAAgdgWg");
    this.shape_5.setTransform(17.7,56.2,0.934,0.934,3.7);

    this.shape_6 = new cjs.Shape();
    this.shape_6.graphics.f("#1D2226").s().p("AhEAyIgOhgQAAgDABgCIACgDIADgDIAHgEIAUgJQAbgKAYgEIAPgBQAJABAEACIAEADIABADIArB3IAFAMIgRACQgCAAgJgVIglhkIgCgBIgLABQgPACgVAHQgTAGgLAGQAEAmAJA1QACASAAANIgSAGg");
    this.shape_6.setTransform(15.4,40.7,0.934,0.934,3.7);

    this.shape_7 = new cjs.Shape();
    this.shape_7.graphics.f("#BF7643").s().p("AgRgBQgBgFASgGQAQgHACAFQACAGgeAZIAAAAQgCAAgFgSg");
    this.shape_7.setTransform(15.6,35.2,0.934,0.934,36.9);

    this.shape_8 = new cjs.Shape();
    this.shape_8.graphics.f("#BF7643").s().p("AgUgDQgBgFAQgGQAPgHAJAHQAMALgvAWIAAAAQgEAAAAgWg");
    this.shape_8.setTransform(16.7,40.2,0.934,0.934,3.7);

    this.shape_9 = new cjs.Shape();
    this.shape_9.graphics.f().s("#1D2226").ss(2).p("Ag3AMQAPgHAVgFQAqgOAiAE");
    this.shape_9.setTransform(14,38.3,0.934,0.934,3.7);

    this.shape_10 = new cjs.Shape();
    this.shape_10.graphics.f().s("#1D2226").ss(2).p("Ag8AHQAQgGAXgCQAtgIAlAH");
    this.shape_10.setTransform(14.9,44,0.934,0.934,3.7);

    this.shape_11 = new cjs.Shape();
    this.shape_11.graphics.f().s("#1D2226").ss(3).p("Ag7ARQAOgHAXgIQAugOAygE");
    this.shape_11.setTransform(15.2,50.1,0.934,0.934,3.7);

    this.shape_12 = new cjs.Shape();
    this.shape_12.graphics.f("#654127").s().p("AgagkIgLgKIAHgQIACgNIAngBIAbCQIg2AJg");
    this.shape_12.setTransform(12.3,42.8);

    this.shape_13 = new cjs.Shape();
    this.shape_13.graphics.f("#BF7643").s().p("AgRAQIgCgZIAngIQADANgUAMQgNAKgEAAQgBAAAAgBQgBAAAAAAQAAAAAAAAQgBgBAAAAg");
    this.shape_13.setTransform(17.9,45,0.934,0.934,-155.5);

    this.shape_14 = new cjs.Shape();
    this.shape_14.graphics.f("#C1733E").s().p("AgUAqQgDACgEgBIgOgBQgeABgEgtIABgwIAPgEQAQAAAHAaQAhATAqgKQAWgFAPgJQAGAqguAfQgYAPgNAAQgOAAgFgNg");
    this.shape_14.setTransform(16,56.6,0.934,0.934,3.7);

    this.shape_15 = new cjs.Shape();
    this.shape_15.graphics.f("#965D36").s().p("AhGhOQBXgVAHAFQACABAHAbQAOA2AYBOQgLAAg7APIg3APg");
    this.shape_15.setTransform(15.2,42.9,0.934,0.934,3.7);

    this.shape_16 = new cjs.Shape();
    this.shape_16.graphics.f("#DDA27A").s().p("AAJBDQgKAAgBgKIgThrIACgCQATgQAEADQACABAIA+QAIA6AAAGQgBAFgKAAIgCAAg");
    this.shape_16.setTransform(11.1,41.2,0.934,0.934,3.7);

    this.shape_17 = new cjs.Shape();
    this.shape_17.graphics.f("#C1733E").s().p("AhBAhIgDgEQACgEgCgFIgCgXQgCgSgFACQAMgGALACIARADQAEAUARABQAJACASgDQAggBAEgEQAIgGAAgkIAEAWIAGAUQAFAMAIAGQgSAVg2AKQgRAEgNAAQgeAAgLgPg");
    this.shape_17.setTransform(16.3,49.3,0.934,0.934,3.7);

    this.shape_18 = new cjs.Shape();
    this.shape_18.graphics.f("#FFE1CC").s().p("AgchHIAEgBQAGgBADACQAFAEAKAjIAdBoIgbABQgBgPgdiBg");
    this.shape_18.setTransform(18.3,41.7,0.934,0.934,3.7);

    this.shape_19 = new cjs.Shape();
    this.shape_19.graphics.f("#FFCDAB").s().p("AgNBPQgbgXgRgNIgNhtQgBgGAqgOQApgPANAHIAsB3IACAkQgHAjgvABQgLAAgTgSg");
    this.shape_19.setTransform(15.4,42.7,0.934,0.934,3.7);

    this.addChild(this.shape_19,this.shape_18,this.shape_17,this.shape_16,this.shape_15,this.shape_14,this.shape_13,this.shape_12,this.shape_11,this.shape_10,this.shape_9,this.shape_8,this.shape_7,this.shape_6,this.shape_5,this.shape_4,this.shape_3,this.shape_2,this.shape_1,this.shape);
  }).prototype = p = new cjs.Container();
  p.nominalBounds = rect = new cjs.Rectangle(7.4,32.8,17.8,30.1);
  p.frameBounds = [rect];


  (lib.Head_01_TrW = function() {
    this.initialize();

    // Isolation Mode
    this.shape = new cjs.Shape();
    this.shape.graphics.f("#081214").s().p("AgZAgQgKgNAAgTQAAgRAKgNQALgPAOAAQAQAAAKAPQAKANAAARQAAATgKANQgKAOgQAAQgOAAgLgOgAgNgVQgHAJAAAMQAAANAHAJQAGAJAHAAQAJAAAFgJQAIgJgBgNQABgMgIgJQgGgJgIAAQgGAAgHAJg");
    this.shape.setTransform(50.9,45.1);

    this.shape_1 = new cjs.Shape();
    this.shape_1.graphics.f("#F3FDFF").s().p("AgRAcIAZg+IAKAGQgHAVgSAqg");
    this.shape_1.setTransform(50.8,45.2);

    this.shape_2 = new cjs.Shape();
    this.shape_2.graphics.f("#7CDCFA").s().p("AgTAbQgJgLAAgQQAAgOAJgMQAIgLALAAQAMAAAIALQAJAMAAAOQAAAQgJALQgIALgMAAQgLAAgIgLg");
    this.shape_2.setTransform(50.9,45.1);

    this.shape_3 = new cjs.Shape();
    this.shape_3.graphics.f("#081214").s().p("AghAhQgPgNAAgUQAAgSAPgOQAOgOATAAQAUAAAOAOQAPAOAAASQAAAUgPANQgOAOgUAAQgTAAgOgOgAgXgVQgKAKAAALQAAANAKAJQAKAKANAAQAOAAAKgKQAKgJAAgNQAAgLgKgKQgKgJgOAAQgNAAgKAJg");
    this.shape_3.setTransform(38.6,45.7);

    this.shape_4 = new cjs.Shape();
    this.shape_4.graphics.f("#F3FDFF").s().p("AgUAgIgFgCIAkhBIAPAHQgKAVgaArIgKgEg");
    this.shape_4.setTransform(38.7,45.9);

    this.shape_5 = new cjs.Shape();
    this.shape_5.graphics.f("#7CDCFA").s().p("AgcAbQgMgLAAgQQAAgPAMgMQAMgLAQAAQARAAAMALQAMAMAAAPQAAAQgMALQgMAMgRAAQgQAAgMgMg");
    this.shape_5.setTransform(38.6,45.7);

    this.shape_6 = new cjs.Shape();
    this.shape_6.graphics.f("#131C20").s().p("AgiAHQAAgCAEgFQAIgHAHgEQAIgFAHAAQAPAAAIAIQAGAGAHAJIgSAJQgFgIgCgDQgFgDgGAAQgCAAgCACQgEACgDACIgGAJg");
    this.shape_6.setTransform(45.4,44.5);

    this.shape_7 = new cjs.Shape();
    this.shape_7.graphics.f("#1D2226").s().p("AgiBfQgZgsgDg1QgBgdAGgYQAJghAVgQIAHgFIAIAEQAKADAGAKQAIAJAEAGQAHALAKAVIANAfIAKAgIAIAZIgZgHIgkgIIgFAbQgIAbgJANIgIAPgAgfgvQgGATgBAZQgBAkAMAhIAEgQIAJgyIAiADIgPgkQgHgTgFgIQgFgJgFgEQgJAKgFAQg");
    this.shape_7.setTransform(38.6,31.7);

    this.shape_8 = new cjs.Shape();
    this.shape_8.graphics.f("#F1B50F").s().p("AgugKQACg6AfgXQASAJAXA2QAMAbAHAXQgigEgNABQgFAGgGAcQgGAfgFAIQgZgvABg3g");
    this.shape_8.setTransform(38.3,31.6);

    this.shape_9 = new cjs.Shape();
    this.shape_9.graphics.f("#FFD56E").s().p("AgYACIgfgzQgNgOAkAIQATADAUAHQADAAARAcQAUAdAMAaQgBABgXgWIgWgUIAXAqQgKAGgRAOQgFgFgcg0g");
    this.shape_9.setTransform(45.8,20.2);

    this.shape_10 = new cjs.Shape();
    this.shape_10.graphics.f("#FFD56E").s().p("AAAAAIg6g+QgLgQAXgDQALgBARACQAFgBAVAnQAeAyAZBKQgGgOg5hEg");
    this.shape_10.setTransform(39,22);

    this.shape_11 = new cjs.Shape();
    this.shape_11.graphics.f("#FFD56E").s().p("AAUAEIgxg4IAFBPIgtAFIgFgpQgEgsgBgCQgLgOAmgKQAlgKAMAIQAKAIAZAtQAcAxAWBBQgKgUg0g+g");
    this.shape_11.setTransform(33,22.5);

    this.shape_12 = new cjs.Shape();
    this.shape_12.graphics.f("#FFD56E").s().p("AgNAAIAKg4IABgJQACgIAMAVQAGAKAFALQgXAzgWAwQgBgMAKg4g");
    this.shape_12.setTransform(19.3,26);

    this.shape_13 = new cjs.Shape();
    this.shape_13.graphics.f("#FFD56E").s().p("AAehQQAEABAGAFQAEAGAAAIQAAAEgbAnQgjAxgaAxQAHhbBDhGg");
    this.shape_13.setTransform(17.9,25.9);

    this.shape_14 = new cjs.Shape();
    this.shape_14.graphics.f("#FFD56E").s().p("AgRAAQgEgVAAgvQABgqACgFQAFgPARgEQAKgBAIABIgKBwQgFApgGB1QgMhngGghg");
    this.shape_14.setTransform(22.6,30.4);

    this.shape_15 = new cjs.Shape();
    this.shape_15.graphics.f("#FFD56E").s().p("Ag3gSQAFgbAYgRQANgIALgDQAOgFAWAMQASALAFAKQADAGgXALIgjASQgOAKgYAmIAEgeQADgZgDAMIgUBRQgHg8AEgig");
    this.shape_15.setTransform(20,9);

    this.shape_16 = new cjs.Shape();
    this.shape_16.graphics.f("#C1733E").s().p("AAHAlQgJgJgKgdIgIgdQAGgXAQAcQAQAZABAMQAFAdgJAAQgDAAgFgEg");
    this.shape_16.setTransform(16,42.5);

    this.shape_17 = new cjs.Shape();
    this.shape_17.graphics.f("#1D2226").s().p("AASBKQgJgBgJgJQgKgJgMgSQgJgQgGgOQgHgSgBgPQgBgKAEgJQAEgLAIgHQAGgGAMgDIAKgCIAIABQALADAGAKQAEAIABAJIgEACQgOgOgHAAIgEABIgGABQgFACgEAEQgHAGABAOQABAMAHAPQAEAIAJAQQAIAQAHAHIAHAFIABAAIADgBQAEgFAHgUIAIAAQADAKgBAHQAAALgFAIQgDAGgGADQgFAEgGAAIgDgBg");
    this.shape_17.setTransform(15.6,42.4);

    this.shape_18 = new cjs.Shape();
    this.shape_18.graphics.f("#EF995E").s().p("AgVAUQgbgxATgWQAGgHAJgDQAFgCAEAAQAKgCAHAFQAKAKAKAmQANA2gSASQgEAFgFAAQgRAAgWgtg");
    this.shape_18.setTransform(16.1,42.3);

    this.shape_19 = new cjs.Shape();
    this.shape_19.graphics.f("#1D2226").s().p("AhiDXIgjgUQgJhNAAgPQAAgygeAKQgRAFgBA6QAAAdADAcIgVgOIgNghQgyidBIhjQAtg/BNgYQBFgWBEAPQAWAEAyATQAcAKAbAXQAbAYANAgQANAfADAnIgMDdIgOgCIgbgMIAEgIQAIgaAEgcQAEgegCgbQAAgfgLgWQgFgKgJgIQgHgHgIgDIgBAAIgBAAQgCABgEAFQgGAJgFAMIgNAaQgGALgIAJQgNANgKAAQgNAAgPgKIgYgTQgSgQgOgJQgQgLgOgDQgQgFgRACQgGADgEAHQgEAIgEAQQgEAVgDAkQgCAgABAbIACA8IACAVQgNAAgPgGgAimAaQAYABAMAOQAHAHABAGIALByIAJAGIgBghQAAgcABgjQADgmAFgZQAHgUAEgKQAGgLAFgFQAIgIAIgDIADgBQAXgDAWAHQATAHATANQAXAQANANIAPAPQAKAIAJgCQAFgCADgGIAFgLIAMgWQAGgOAJgNQAGgJAHgFQAFgDAGgBQAHAAAEACQAQAGAJAQQAHANADASQACAOABAfIAEhMQgCghgLgZQgLgbgWgTQgfgbg/gNQhVgRhaAfQhLAjgZBiQgNAuADAqQABgIAGgJQALgRAXAAIABAAg");
    this.shape_19.setTransform(33.8,31.2);

    this.shape_20 = new cjs.Shape();
    this.shape_20.graphics.f("#F1B50F").s().p("AiABDIgzgYIgnAtIgFhPQgDhcBKg7QA9gwBLgDIBPAEQA6AFAnAbQA6ApAGBVIgMDLIgSgBQAHgoACguQAEhagYgeQgPgGgcAmQggAtgJAFQgNADgLgKIhJgoQg2gigPAKQgRAPgGBlQgCA1AAAwIggABg");
    this.shape_20.setTransform(34.4,31.3);

    this.shape_21 = new cjs.Shape();
    this.shape_21.graphics.f("#FFB685").s().p("AgMAAQAAgJAEgOIAEgLIAEAMQAGAPAFANQAFARgFAGQgEAEgIABIgBABQgKAAAAgjg");
    this.shape_21.setTransform(45.7,46.1);

    this.shape_22 = new cjs.Shape();
    this.shape_22.graphics.f("#1D2226").s().p("AgWAAIAWgBIAXgDQgIAIgPABIgBAAQgMAAgJgFg");
    this.shape_22.setTransform(44,56.9);

    this.shape_23 = new cjs.Shape();
    this.shape_23.graphics.f("#1D2226").s().p("AguAEQAJgEAOgCIAXgEIAXgBQAOABAKADQgTAHgcADIgWABQgPgBgJgDg");
    this.shape_23.setTransform(43.7,54.8);

    this.shape_24 = new cjs.Shape();
    this.shape_24.graphics.f("#1D2226").s().p("AgRAKQgKgIgCgIIARAGQAJACAEgCQAIAAAGgDIAPgMQAAAMgHAHQgHAKgNABIgDABQgJAAgIgGg");
    this.shape_24.setTransform(44.5,50.9);

    this.shape_25 = new cjs.Shape();
    this.shape_25.graphics.f("#1D2226").s().p("AAQAGQgkgYgcgKQAiAGAYALQASAJAVANIgBASQgNgKgTgNg");
    this.shape_25.setTransform(35.8,37.2);

    this.shape_26 = new cjs.Shape();
    this.shape_26.graphics.f("#BC624D").s().p("AghAFIgMgIQAKgDApgDIAogDIgKAMQgNAJgWADIgHABQgPAAgMgIg");
    this.shape_26.setTransform(43.9,55.7);

    this.shape_27 = new cjs.Shape();
    this.shape_27.graphics.f("#1D2226").s().p("AgeAAQAegRAhACIABADQgVAGgYALIgWAMg");
    this.shape_27.setTransform(50.7,37.2);

    this.shape_28 = new cjs.Shape();
    this.shape_28.graphics.f("#1D2226").s().p("AgkATIgGgDIACgGQAAgDAGgIQAIgNANgHQANgGAMAAQANAAAMAEIAFABIABAQIAAABQgGANgJAKQgLAKgRAAQgOAAgWgJgAgRAAIgGAHQAOAGAJAAQALAAAHgGQAGgGAEgKIAAgBQgJgCgHAAQgSAAgLAMg");
    this.shape_28.setTransform(50.8,40.8);

    this.shape_29 = new cjs.Shape();
    this.shape_29.graphics.f("#FFFFFF").s().p("AgiAMQADgMALgHQAUgUAiALIABAJQgHATgPAGQgGADgHAAQgNAAgVgJg");
    this.shape_29.setTransform(50.9,40.8);

    this.shape_30 = new cjs.Shape();
    this.shape_30.graphics.f("#1D2226").s().p("AggAQQgJgJgHgRIgDgIIAIgCQAUgHARAAQAZAAASARQAJAJADAHIADAHIgGADQgbAMgTAAIAAAAQgTAAgNgMgAgfgIQAEAIAGAFQAJAIAMAAQANAAASgIIgEgFQgOgMgTAAQgMAAgNAEg");
    this.shape_30.setTransform(35.4,41.2);

    this.shape_31 = new cjs.Shape();
    this.shape_31.graphics.f("#FFFFFF").s().p("AgQARQgQgHgJgXQApgOAZARQANAJAEAKQgZALgRAAQgIAAgIgDg");
    this.shape_31.setTransform(35.4,41.2);

    this.shape_32 = new cjs.Shape();
    this.shape_32.graphics.f("#EF995E").s().p("AAdCPQhDgFgbgWQgogggMhcQAFgaAIgWIAHgQQATABBFglQBCgkAJABQATACAQAfQASAlgCAxQgCBEgVAvQgXA1gmAAIgEgBg");
    this.shape_32.setTransform(40.4,44.7);

    this.shape_33 = new cjs.Shape();
    this.shape_33.graphics.f("#1D2226").s().p("AA5D8Qg8gGhJgoQg9gjg0gxIgBgBIgBgCQgahBgJg2IAAgFIAHgIIAYg3IAfg/QAlhFAwgrIACgDIAEAAIAdgEIAdgCQAegBAaAEQAhAEAZAJQAdAKAZATIACABIABACQAXAmANAcIAaBAIADAFIAAADQADAZABAiIACA3IAAACQgGArgHAcQgLAmgSAeQgXAkggAPQgZANgfAAIgRgBgAgPjkIg0AEQgqAogkBAIgfA9IgaA3IgDAEQAIA1AXA4QAyAvA6AhQBBAlA8AFQAjADAagOQAbgNASgfQAbgwAHhQIgEg0QgDgggEgXIgBgDIgBgGIgUg6QgPgigRgcQgmgdg6gIQgXgDgXAAIgHAAg");
    this.shape_33.setTransform(33.2,38.2);

    this.shape_34 = new cjs.Shape();
    this.shape_34.graphics.f("#C1733E").s().p("ABNDxQhMgDhjhAIhWg/QgXg8gGg2IAHgKQAmhVARgeQAjg/ApgnQAcgIAdgBQBngIA/AyQAlA9ATBAQABADACAEQAEAaADAwIgNBQQgIAxgKAcQgbBLhIAAIgHAAg");
    this.shape_34.setTransform(32.9,38.3);

    this.shape_35 = new cjs.Shape();
    this.shape_35.graphics.f("#1D2226").s().p("AgRDXQgJgBgHgFQgFgDgGgIQgHgJgJgVQgMgjgJg0QgJgvgFgyQgEgvAAgeIABgNQACgtAdgfQAdggAnAAIAGABQAoACAaAhQAbAfAAAtIAAAIQgCAPgEAXQgFAcgHAbQgSBHgSA0QgQAqgNAWQgKAQgHAHQgHAGgJAAgAgtihQgWAXgCAhIAAAMQAAAkAGA4QAHBBALAvQAIAlAKATQAEALAGAFIAAABIACgCQAHgIAGgMQAKgXAQgvQAdhXANhKQADgNABgOIAAgGQAAghgUgYQgTgXgbgBIgDgBQgaAAgUAXg");
    this.shape_35.setTransform(20.6,19.2);

    this.shape_36 = new cjs.Shape();
    this.shape_36.graphics.f("#F1B50F").s().p("AgQDFQgggCgViCQgThtAEg7QADgpAagbQAbgbAhACQAkADAXAeQAXAegCApQgEA8gfBpQgkB8gdAAIgBAAg");
    this.shape_36.setTransform(20.7,19);

    this.addChild(this.shape_36,this.shape_35,this.shape_34,this.shape_33,this.shape_32,this.shape_31,this.shape_30,this.shape_29,this.shape_28,this.shape_27,this.shape_26,this.shape_25,this.shape_24,this.shape_23,this.shape_22,this.shape_21,this.shape_20,this.shape_19,this.shape_18,this.shape_17,this.shape_16,this.shape_15,this.shape_14,this.shape_13,this.shape_12,this.shape_11,this.shape_10,this.shape_9,this.shape_8,this.shape_7,this.shape_6,this.shape_5,this.shape_4,this.shape_3,this.shape_2,this.shape_1,this.shape);
  }).prototype = p = new cjs.Container();
  p.nominalBounds = rect = new cjs.Rectangle(9.5,-2.2,48.7,65.9);
  p.frameBounds = [rect];


  (lib.Body_01_TrW = function() {
    this.initialize();

    // Isolation Mode
    this.shape = new cjs.Shape();
    this.shape.graphics.f("#1D2226").s().p("AANAlIgGgDIgHgFIgagWIgDgDIAAgDIAFglIAFAAQATAAAOAHQAGACAFAGIACADIACAKIABAQIgBAJIgCALIgCAEIgCACIgGADgAgNgBQAIAGANAJIgDgXIAAABIAAgBIgCgBIgSgNg");
    this.shape.setTransform(39.9,29.4);

    this.shape_1 = new cjs.Shape();
    this.shape_1.graphics.f("#DD3900").s().p("AgMgBIgBgHQgBgFACAAIAZAPQABABAAALIgBAAQgEAAgVgPg");
    this.shape_1.setTransform(39.6,28.7);

    this.shape_2 = new cjs.Shape();
    this.shape_2.graphics.f("#A52F00").s().p("AgSAEIAAggIAlASIAAAng");
    this.shape_2.setTransform(39.6,29.1);

    this.shape_3 = new cjs.Shape();
    this.shape_3.graphics.f("#DD3900").s().p("Ag1AEIAJgGQADgCAtgDIAvgCQADABABAEQABAEgFACQgEADgtACIg0ACIgBABQgGAAAEgGg");
    this.shape_3.setTransform(16.8,29.7);

    this.shape_4 = new cjs.Shape();
    this.shape_4.graphics.f("#1D2226").s().p("Ag+AhIgDAAIgFgBQgKgFgCgLQgBgFABgIQABgLAIgLIAEgGIAHgEIADgBIANgBIApgCQAuADAjADIAEAAIADArIgGACIiFAPgAg1gGQgFAGgDAHIgBAGIAAABIACABIAOAAIAogDQAogEAigFIADgVIhLAGQgPAAgZADIgIACIAAgBIgBABIABAAgAg0gHg");
    this.shape_4.setTransform(15.8,30.2);

    this.shape_5 = new cjs.Shape();
    this.shape_5.graphics.f("#A52F00").s().p("AhBgPICJgHIgBAhIiOAMg");
    this.shape_5.setTransform(16.2,30.2);

    this.shape_6 = new cjs.Shape();
    this.shape_6.graphics.f("#1D2226").s().p("Ag/CRIAdhKIAahJQAghkALg0IAdAKQgYAygfBgIgWBMQgQA2gFAXg");
    this.shape_6.setTransform(18,43.8);

    this.shape_7 = new cjs.Shape();
    this.shape_7.graphics.f("#737A7F").s().p("AADAHQgDgBgDgCQgEgBgBgDQgBgFAIgBIAEACQAFAEABAEQgBADgEAAIgBAAg");
    this.shape_7.setTransform(34.5,50.9);

    this.shape_8 = new cjs.Shape();
    this.shape_8.graphics.f("#1D2226").s().p("AgKALQgEgFAAgGQAAgFAEgFQAFgEAFAAQAGAAAFAEQAEAFAAAFQAAAGgEAFQgFAEgGAAQgFAAgFgEg");
    this.shape_8.setTransform(34.6,51.4);

    this.shape_9 = new cjs.Shape();
    this.shape_9.graphics.f("#737A7F").s().p("AgIAEQAAgEAGgEIAEgCQAIABgBAFQgBADgEABQgEACgCABIgCAAQgEAAAAgDg");
    this.shape_9.setTransform(27.2,52.6);

    this.shape_10 = new cjs.Shape();
    this.shape_10.graphics.f("#1D2226").s().p("AgKALQgEgFAAgGQAAgFAEgFQAFgEAFAAQAGAAAFAEQAEAFAAAFQAAAGgEAFQgFAEgGAAQgFAAgFgEg");
    this.shape_10.setTransform(27.5,53.1);

    this.shape_11 = new cjs.Shape();
    this.shape_11.graphics.f("#737A7F").s().p("AADAHQgDgBgDgCQgEgBgBgDQgBgFAIgBIAEACQAFAEABAEQgBADgEAAIgBAAg");
    this.shape_11.setTransform(34.5,45.1);

    this.shape_12 = new cjs.Shape();
    this.shape_12.graphics.f("#1D2226").s().p("AgKALQgEgFAAgGQAAgFAEgFQAFgEAFAAQAGAAAFAEQAEAFAAAFQAAAGgEAFQgFAEgGAAQgFAAgFgEg");
    this.shape_12.setTransform(34.6,45.4);

    this.shape_13 = new cjs.Shape();
    this.shape_13.graphics.f("#737A7F").s().p("AgIADQAAgEAGgDIAEgCQAIAAgBAGQgBACgEACQgEADgEAAQgEAAAAgEg");
    this.shape_13.setTransform(27.2,46.8);

    this.shape_14 = new cjs.Shape();
    this.shape_14.graphics.f("#1D2226").s().p("AgKALQgEgFAAgGQAAgFAEgFQAFgEAFAAQAGAAAFAEQAEAFAAAFQAAAGgEAFQgFAEgGAAQgFAAgFgEg");
    this.shape_14.setTransform(27.5,47.1);

    this.shape_15 = new cjs.Shape();
    this.shape_15.graphics.f("#737A7F").s().p("AADAHQgDgBgDgCQgEgBgBgDQgBgFAIgBIAEACQAFAEABAEQgBADgEAAIgBAAg");
    this.shape_15.setTransform(34.5,38.3);

    this.shape_16 = new cjs.Shape();
    this.shape_16.graphics.f("#1D2226").s().p("AgKALQgEgFAAgGQAAgFAEgFQAFgEAFAAQAGAAAFAEQAEAFAAAFQAAAGgEAFQgFAEgGAAQgFAAgFgEg");
    this.shape_16.setTransform(34.6,38.7);

    this.shape_17 = new cjs.Shape();
    this.shape_17.graphics.f("#737A7F").s().p("AgIADQAAgEAGgDIAEgCQAIAAgBAGQgBACgEACQgEADgEAAQgEAAAAgEg");
    this.shape_17.setTransform(27.2,40.1);

    this.shape_18 = new cjs.Shape();
    this.shape_18.graphics.f("#1D2226").s().p("AgKALQgEgFAAgGQAAgFAEgFQAFgEAFAAQAGAAAFAEQAEAFAAAFQAAAGgEAFQgFAFgGgBQgFABgFgFg");
    this.shape_18.setTransform(27.5,40.4);

    this.shape_19 = new cjs.Shape();
    this.shape_19.graphics.f("#737A7F").s().p("AgDAEQgEgCgBgCQgBgGAIAAIAEACQAFADABAEQAAAEgEAAQgEAAgEgDg");
    this.shape_19.setTransform(34.5,32.5);

    this.shape_20 = new cjs.Shape();
    this.shape_20.graphics.f("#1D2226").s().p("AgKALQgEgFAAgGQAAgFAEgFQAFgEAFAAQAGAAAFAEQAEAFAAAFQAAAGgEAFQgFAEgGAAQgFAAgFgEg");
    this.shape_20.setTransform(34.6,32.9);

    this.shape_21 = new cjs.Shape();
    this.shape_21.graphics.f("#737A7F").s().p("AgIAEQAAgEAGgEIAEgCQAIABgBAFQgBADgEABQgFADgDAAQgEAAAAgDg");
    this.shape_21.setTransform(27.2,34.1);

    this.shape_22 = new cjs.Shape();
    this.shape_22.graphics.f("#1D2226").s().p("AgKALQgEgFAAgGQAAgFAEgFQAFgEAFAAQAGAAAFAEQAEAFAAAFQAAAGgEAFQgFAEgGAAQgFAAgFgEg");
    this.shape_22.setTransform(27.5,34.6);

    this.shape_23 = new cjs.Shape();
    this.shape_23.graphics.f("#737A7F").s().p("AgDAEQgEgCgBgCQgBgGAIAAIAEACQAFADABAEQAAAEgEAAQgEAAgEgDg");
    this.shape_23.setTransform(34.5,27.3);

    this.shape_24 = new cjs.Shape();
    this.shape_24.graphics.f("#1D2226").s().p("AgKAKQgEgEAAgGQAAgFAEgFQAFgFAFAAQAGAAAFAFQAEAFAAAFQAAAGgEAEQgFAGgGAAQgFAAgFgGg");
    this.shape_24.setTransform(34.6,28);

    this.shape_25 = new cjs.Shape();
    this.shape_25.graphics.f("#737A7F").s().p("AgIADQAAgEAGgDIAEgCQAIABgBAFQgBACgEACQgEADgEAAQgEAAAAgEg");
    this.shape_25.setTransform(27.2,29);

    this.shape_26 = new cjs.Shape();
    this.shape_26.graphics.f("#1D2226").s().p("AgKALQgEgFAAgGQAAgFAEgEQAFgFAFgBQAGABAFAFQAEAEAAAFQAAAHgEAEQgFAEgGABQgFgBgFgEg");
    this.shape_26.setTransform(27.5,29.7);

    this.shape_27 = new cjs.Shape();
    this.shape_27.graphics.f("#737A7F").s().p("AgDAEQgEgCgBgDQgBgFAIAAIAEACQAFADABAEQAAAEgEAAQgEAAgEgDg");
    this.shape_27.setTransform(34.5,21.8);

    this.shape_28 = new cjs.Shape();
    this.shape_28.graphics.f("#1D2226").s().p("AgKALQgEgFAAgGQAAgFAEgFQAFgEAFAAQAGAAAFAEQAEAFAAAFQAAAGgEAFQgFAEgGAAQgFAAgFgEg");
    this.shape_28.setTransform(34.6,22.4);

    this.shape_29 = new cjs.Shape();
    this.shape_29.graphics.f("#737A7F").s().p("AgIADQAAgEAGgDIAEgCQAIABgBAFQgBADgEABQgEADgEAAQgEAAAAgEg");
    this.shape_29.setTransform(27.2,23.4);

    this.shape_30 = new cjs.Shape();
    this.shape_30.graphics.f("#1D2226").s().p("AgKALQgEgFAAgGQAAgFAEgFQAFgEAFAAQAGAAAFAEQAEAFAAAFQAAAGgEAFQgFAEgGAAQgFAAgFgEg");
    this.shape_30.setTransform(27.5,24.1);

    this.shape_31 = new cjs.Shape();
    this.shape_31.graphics.f("#737A7F").s().p("AADAHIgGgDQgEgBgBgDQgBgFAIgBIAEACQAFAEABAEQgBADgEAAIgBAAg");
    this.shape_31.setTransform(34.5,16.1);

    this.shape_32 = new cjs.Shape();
    this.shape_32.graphics.f("#1D2226").s().p("AgKALQgEgFAAgGQAAgFAEgFQAFgEAFAAQAGAAAFAEQAEAFAAAFQAAAGgEAFQgFAEgGAAQgFAAgFgEg");
    this.shape_32.setTransform(34.6,16.6);

    this.shape_33 = new cjs.Shape();
    this.shape_33.graphics.f("#737A7F").s().p("AgIAEQAAgEAGgEIAEgCQAIABgBAFQgBADgEABQgEACgCABIgCAAQgEAAAAgDg");
    this.shape_33.setTransform(27.2,17.8);

    this.shape_34 = new cjs.Shape();
    this.shape_34.graphics.f("#1D2226").s().p("AgKALQgEgFAAgGQAAgFAEgFQAFgEAFAAQAGAAAFAEQAEAFAAAFQAAAGgEAFQgFAEgGAAQgFAAgFgEg");
    this.shape_34.setTransform(27.5,18.3);

    this.shape_35 = new cjs.Shape();
    this.shape_35.graphics.f("#FF4310").s().p("AggATIgNhWQABgIAsgHQAvgIgBAOQgBAYgNA0QgRA9gPAVQgDAEgDAAQgNAAgNhDg");
    this.shape_35.setTransform(30.7,25.1);

    this.shape_36 = new cjs.Shape();
    this.shape_36.graphics.f("#1D2226").s().p("AhZEQQAChSACilIABi4QAAghgEgaIABAAIABABIABABIABAAIACABQAAAAAAABQABAAAAAAQABAAAAABQABAAAAAAIAEABIAEACIAAAAIADACIADABIADACIABAAIABAAQgCAVgBAZIABC4IACDlIB5gcIABj7IgBiFIgBhCQgCgngHgcIACAAIABABIAAAAIABABIAAABIABAAIAAABIAAAAIABABIAAAAIAAABIAAAAIABAAIAAABIAAABIAAAAIABABIAAAAIAAABIABABIAAABIABABIAAAAIAAABIABAAIAAABIAAAAIABABIAAABIAAAAIABABIAAABIAAABIAAABIABABIAAABIABABIAAAAIAAABIABABIAAAAIABABIAAABIABAAIAAABIABABIAAAAIAAABIABABIABABIAAABIAAAAIAAABIABABIAAAAIAAACIABABIAAAAIAAABIAAABIAAAAIAAABIABAAIAAABIAAABIAAABIAAAAIAAACIABABIAAACIAAACIAAAAIAAAPIABBCIADCEQAHDFADBCIABANIi1Apg");
    this.shape_36.setTransform(30.8,33.1);

    this.shape_37 = new cjs.Shape();
    this.shape_37.graphics.f("#DD3900").s().p("AhECIIgHhCQAGgkgBgvIgChVQAAgHgDgEIADgVIAEgEQANAFAbABIAvAAQAbgBASgHIALAKIgBAGQgBAgADBAQgHAFAAAIQABBDADAuQgbAMglACQgQAAgcAOQgPAHgKAAQgFAAgDgBg");
    this.shape_37.setTransform(30.9,28.3);

    this.shape_38 = new cjs.Shape();
    this.shape_38.graphics.f("#1D2226").s().p("AAGAYQgmgOgSgTIgFgFIAcgWIACADIAGAGQALAJAPAIQAVAJAcAEIgIAiQgagGgQgHg");
    this.shape_38.setTransform(9.4,56);

    this.shape_39 = new cjs.Shape();
    this.shape_39.graphics.f("#DD3900").s().p("Ag+BxQgfg5Alh5QATg/AVgNQAIgFAaADIAGgEQAIgDAHAHQAXAVALBoQAHA9gHAkQgMA+gzAHIgMABQgoAAgUgkg");
    this.shape_39.setTransform(30.6,39.5);

    this.shape_40 = new cjs.Shape();
    this.shape_40.graphics.f("#1D2226").s().p("AgRBDQAAgCAGgGIAHgFQAEgHgOhQIgGgwIAcADIAIAqQAHAzgDA9QAAAFgKAAIgOABQgGgJgHgGg");
    this.shape_40.setTransform(42.1,46.9);

    this.shape_41 = new cjs.Shape();
    this.shape_41.graphics.f("#1D2226").s().p("AgQBMQgNhEAMgxIANglIAcgDIgGAwQgOBQAEAHIAEAAIgDAcg");
    this.shape_41.setTransform(5.6,46.9);

    this.shape_42 = new cjs.Shape();
    this.shape_42.graphics.f("#1D2226").s().p("AADBSQgmgHgigYQgTgNgJgNQgOgSAAgPQAAgTAMgQQALgPARgJQAYgPAggCQgeADgYARQgOAKgHAPQgHAQACAOQACAKANANQAJAJARAKQAcARAiAGQAnAGAWgOQAMgHAHgOQAGgMAAgPQgCghgagYQgNgNgRgGQgMgFgPgCQAkAEAZATQAeAXAKAjQAFASgFARQgGAVgRANQgRANgZAEIgOABQgNAAgPgDg");
    this.shape_42.setTransform(26.5,7.4);

    this.shape_43 = new cjs.Shape();
    this.shape_43.graphics.f("#1D2226").s().p("AgiBOQgHgEgJgJIgIgIIATAFQAHABAIgBQAVgBAGgCQANgFAKgNQAIgLADgQQACgOgDgOIgFgNIgIgMIgJgNQgBgCABgLQABgKgCgDIAQgEIARAeQAEAHAEAJQAEALABAHIAAABQABARgDASQgFASgMAQQgNAPgVALQgGAEgNABQgNAAgIgFg");
    this.shape_43.setTransform(39.1,18.3);

    this.shape_44 = new cjs.Shape();
    this.shape_44.graphics.f("#DD3900").s().p("AgjA1QgVgJgFgUQgCglAigZQARgNAPgEQANgFAPAHQAPAGAMASQAMARgTAdQgTAdgYAIQgJAEgKAAQgMAAgMgFg");
    this.shape_44.setTransform(20.2,18.7);

    this.shape_45 = new cjs.Shape();
    this.shape_45.graphics.f("#1D2226").s().p("AgCBKQgFAAgJgDQgfgMgPgXQgPgXACggIADgPIAEgOQAFgLAKgOIAAgCIACACIAEAcQgJAOgBAOQgFAaAMATQAMAWAaAIQAHAEAFAAIAKABQARgCAIgCIARgGIAYgIQgJAIgLAIQgMAIgFACQgNAEgNAAIgPgBg");
    this.shape_45.setTransform(18.7,21.4);

    this.shape_46 = new cjs.Shape();
    this.shape_46.graphics.f("#1D2226").s().p("ACZDQIgHgXIgSgqIgBgCIAAgBIgNgsIAIgSIAGgBQANgDAKgMQAKgLAGgPQAFgPgBgQQgDgSgJgIIgDgDIABgFQAEgXACgSIAAgJIgBgIQgEgKgEgHQgRghgjgcQgggbglgGIgTgCIgSgBQgKgBgKADQgJADgLAEQgmAQgeAdQgQAQgIAQQgLARACAPQABAtAHAmQADAMAIAbIALAdIADAFIABADIACACIABAEIgCADIgNAoIAAABIgBABIgNAYIgLAZQgKAcgEAYIgdgGQAIgcANgbIAcgzQAFgLAHgWIgQglIgOgqQgLglgEgxQgBgWARgaQAMgSAUgQQAfgaAugTIAqgOQANgGAIAAIAMgBIAMABQAUACAaAMQAVAKASAQQAkAfAUAqIAIAWIABAOQABAGgCAGQgDATgGAVQALAUACAKQAEASgFAWQgGAVgMAPQgLAPgOAHIAJAcIAUAvIAHAZIAFAaIgdAEIgFgWg");
    this.shape_46.setTransform(24.2,16.7);

    this.shape_47 = new cjs.Shape();
    this.shape_47.graphics.f("#1D2226").s().p("AACAiQgCgOgFgTQgGgQgGgNQgJgTgIgLIAcgJQABAPAEASQABANAGAUQAGAQAHAOQAIAUAIAKIgcAKQgBgPgEgUg");
    this.shape_47.setTransform(39.7,46.9);

    this.shape_48 = new cjs.Shape();
    this.shape_48.graphics.f("#A52F00").s().p("AicBQQgKglAEgnQAFhAAsgjQBJg0BOATQA1ANAeAgQAdAfAOBeQgCAAgggVQgdgTgFAFQgGAHgUAIQgXAJgVABQgNAAgsgVQgrgSgPAGQgSAEgRAiQgIARgFAQIABBAQgNgfgHgXg");
    this.shape_48.setTransform(25.7,9);

    this.shape_49 = new cjs.Shape();
    this.shape_49.graphics.f("#DD3900").s().p("AgJAuQgQgIgKgbQgKgZAKgOQAJgPALgEQAKgFAHAFIAVARQAVAYgEAfQgGARgPAGQgHADgHAAQgGAAgIgFg");
    this.shape_49.setTransform(38.9,16.3);

    this.shape_50 = new cjs.Shape();
    this.shape_50.graphics.f("#A52F00").s().p("AAzD4QgUgCgtg2QgDgCgCgqQgCgogDgEQgCgCgHAdQgIAegCgDQgvg5gjgjQgNgNgRhRQgOhDgBgTQgCguBAgtQBAgtA7ADQA7ACAyA4QAtAygEAgQgFAhgEAOQAQAVgBAaQgBAWgNAVQgOAUgVAHQAWA/gkBGQgfA7gXAAIgDgBg");
    this.shape_50.setTransform(25.2,20.2);

    this.shape_51 = new cjs.Shape();
    this.shape_51.graphics.f("#A52F00").s().p("AgBAlQAAiQgCAEQgOAfgdBgQghBrgKAbQgqgKgNgFQgjgQgHgbQgDgiAEghQAFgfAOgyQAIgfATgiIARgcQAKgVA6gQQA+gQA4APQCjArgzEDIgNgxQgPgygEADQgCACAEA5QAEA6gFACQgbAPgiALQgpANgmACIAAAAQgFAAgBiWg");
    this.shape_51.setTransform(23.8,41.3);

    this.shape_52 = new cjs.Shape();
    this.shape_52.graphics.f("#2B2F33").s().p("AgOB8IglgHIAXhEQAYhDADgEQABgEAOgmIASguQACgGAIgGIAIgEIACApQABBFgHCMQgLADgPAAQgQAAgSgDg");
    this.shape_52.setTransform(17.9,45.1);

    this.shape_53 = new cjs.Shape();
    this.shape_53.graphics.f("#2B2F33").s().p("AgQBHIgCi3IAlDXIgcAKg");
    this.shape_53.setTransform(39.5,43.6);

    this.addChild(this.shape_53,this.shape_52,this.shape_51,this.shape_50,this.shape_49,this.shape_48,this.shape_47,this.shape_46,this.shape_45,this.shape_44,this.shape_43,this.shape_42,this.shape_41,this.shape_40,this.shape_39,this.shape_38,this.shape_37,this.shape_36,this.shape_35,this.shape_34,this.shape_33,this.shape_32,this.shape_31,this.shape_30,this.shape_29,this.shape_28,this.shape_27,this.shape_26,this.shape_25,this.shape_24,this.shape_23,this.shape_22,this.shape_21,this.shape_20,this.shape_19,this.shape_18,this.shape_17,this.shape_16,this.shape_15,this.shape_14,this.shape_13,this.shape_12,this.shape_11,this.shape_10,this.shape_9,this.shape_8,this.shape_7,this.shape_6,this.shape_5,this.shape_4,this.shape_3,this.shape_2,this.shape_1,this.shape);
  }).prototype = p = new cjs.Container();
  p.nominalBounds = rect = new cjs.Rectangle(3.2,-6.4,41.9,68.8);
  p.frameBounds = [rect];


  (lib.ArmorPart_TrW = function() {
    this.initialize();

    // Layer 1
    this.shape = new cjs.Shape();
    this.shape.graphics.f("#E22500").s().p("AgwAkQgOgEALghQAGgSAJgRQAEAAAnAKQAaAHAHAEQASAIgCAKQgCAOgrAMQgbAIgSAAQgIAAgGgBg");
    this.shape.setTransform(12.8,1.1);

    this.shape_1 = new cjs.Shape();
    this.shape_1.graphics.f("#1D2226").s().p("AgtBIQgTgDgOgGQgMgFgGgGIgDgDIAAgEQgCgIgBgOQAAgYAKgnIAKgiIAdAKIAAABIgCAIIgHAXQgJAgAAAXIAAAKIAFACQAEACAMADQAUAEAaAAQARAAAPgDQAPgDAHgFIAFgEQANgmAFgQIAAgBIAeAJQgGASgNAmQgFALgLAIQgKAHgLADQgXAHgcAAQgVAAgUgDg");
    this.shape_1.setTransform(14.3,2.3);

    this.shape_2 = new cjs.Shape();
    this.shape_2.graphics.f("#AF2D00").s().p("AhXAxQgLgOAPgxQAIgaAKgXQACgBAaAHIAlAKIBcAfQgQAogRAVQgNAQg6ACIgNABQgyAAgMgPg");
    this.shape_2.setTransform(14.2,2.1);

    this.shape_3 = new cjs.Shape();
    this.shape_3.graphics.f("#1D2226").s().p("AgQBWQgPgBgNgIQgNgIgIgMIgIgMIgBgDIgBgDIgCgGQgEgKgDgPQgDgOgCggQgBgjABgMIAeACIABAsQABAXAEATIAFAUIABAFIACAEIAEAIQALAQARACQAIABAHgCIAJgDIAJgFQAPgJAKgUQAGgKAJgdIALgsIAUAEQgDAVgGAZQgIAegHAOQgNAbgUANIgMAHQgHAEgFABQgKADgJAAIgHAAg");
    this.shape_3.setTransform(15,9.6);

    this.shape_4 = new cjs.Shape();
    this.shape_4.graphics.f("#2B2F33").s().p("Ag3BOQgPgbgEg6QgDgeABgYQAJgjAFADIAIAIQAIAFAJABQAgAEAaAMQAZAMAfAXQgRBegzAWQgNAGgNAAQgVAAgRgQg");
    this.shape_4.setTransform(15.1,7.1);

    this.addChild(this.shape_4,this.shape_3,this.shape_2,this.shape_1,this.shape);
  }).prototype = p = new cjs.Container();
  p.nominalBounds = rect = new cjs.Rectangle(4,-5.2,20.6,23.6);
  p.frameBounds = [rect];


  (lib.ArmorPart_01_TrW = function() {
    this.initialize();

    // Layer 1
    this.shape = new cjs.Shape();
    this.shape.graphics.f("#2B2F33").s().p("AAHBQIgHgDIgJgEQgOgJgMgVQgGgMgIgcQgFgPgKg5IAmgKIAAgBIABABIABAAIABAGIAVA5QAFATAUAKQAQAJAXAAIADAAIgBAEIgEAUIgCAFIgBACIgBADIgEAHQgLAQgQACIgFAAIgNgBg");
    this.shape.setTransform(2.8,6.4);

    this.shape_1 = new cjs.Shape();
    this.shape_1.graphics.f("#E22500").s().p("AgagKQgFgKAWgLQAJgFAMgDQAEgFAGAdQAGAYAAAPQAAALgDADQgCACgMABIgBAAQgMAAgYgzg");
    this.shape_1.setTransform(8.1,0);

    this.shape_2 = new cjs.Shape();
    this.shape_2.graphics.f("#AF2D00").s().p("AgHAvQgJgGgEgJIgWg7IAfgNQAJgEALgDIARgEIAJAgQAIAhAAAUIAAAKIgJAFQgLADgIAAQgOAAgIgFgAATgsQgMAEgJAFQgWALAFAKQAXA0AOgBQAMgBACgDQADgCAAgLQAAgPgGgZQgFgYgEAAIgBAAg");
    this.shape_2.setTransform(7.4,0.4);

    this.shape_3 = new cjs.Shape();
    this.shape_3.graphics.f("#1D2226").s().p("AgPByIgNgFQgGgCgFgFQgVgNgNgbQgHgQgHgeIgQhKIAWgGIAAADQALA5AEAOQAJAcAGANQAMAUAOAJIAIAFIAJADQAIABAIAAQAQgCALgQIAFgIIABgCIAAgCIACgFIAFgVIABgDIgEAAQgWAAgRgJQgSgLgHgSIgUg5IgBgGIgCAAIAAgCIAdgJQAAACAAACQABABAAAAQAAAAAAAAQAAgBAAgCIAUA9QAEAKAJAFQAKAEAOAAQAIAAALgCIAJgEIAAgLQAAgTgIgjIgJghIgBgCIAAAAIAdgKIAKAiQAKApAAAYQAAALgCAJIgBAEIgDADQgHAHgKAFIgDARIgGAZIgEAJIgBACIgHANQgIAMgNAIQgOAIgOABIgHAAQgJAAgKgDg");
    this.shape_3.setTransform(4.5,5.7);

    this.addChild(this.shape_3,this.shape_2,this.shape_1,this.shape);
  }).prototype = p = new cjs.Container();
  p.nominalBounds = rect = new cjs.Rectangle(-5.9,-6,20.9,23.6);
  p.frameBounds = [rect];

})(lib = lib||{}, images = images||{}, createjs = window.createjs||{});
var lib, images, createjs;

module.exports = lib;