package;

import haxe.Timer;
import flixel.util.FlxColor;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.FlxObject;
import flixel.FlxG;
import flixel.math.FlxPoint;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.util.FlxTimer;
import flixel.math.FlxRandom;
import flixel.system.scaleModes.RatioScaleMode;
import flixel.system.FlxSound;
//import flixel.addons.effects.FlxTrailArea;

@:structInit
class Rule
{
	public var l: String;
	public var r: Array<String>;
}

@:structInit
class StoredState
{
	public var x: Float;
	public var y: Float;
	public var angle: Float;
}

class PlayState extends FlxState
{
	var algorithm: Array<Rule>;
	var axiom: String;
	var currentState: String;

	var random: FlxRandom;
	var branchGroup: FlxGroup;
	var leafGroup: FlxGroup;

	var leaf: FlxSprite;
	var root1: FlxSprite;
	var root2: FlxSprite;
	var root3: FlxSprite;
	var trunk1: FlxSprite;
	var trunk2: FlxSprite;
	var trunk3: FlxSprite;
	var trunk_top1: FlxSprite;
	var trunk_top2: FlxSprite;
	var trunk_top3: FlxSprite;
	var branch1: FlxSprite;
	var branch2: FlxSprite;
	var branch3: FlxSprite;
	var branch_top1: FlxSprite;
	var branch_top2: FlxSprite;
	var branch_top3: FlxSprite;

	var currentIteration: Int;
	var iterationTimer: FlxTimer;

	var iterationCallback: Void->Void;

	// if enabled, then the growth is animated after mouse click
	var timerEnabled = true;

	var leaves: Array<FlxSprite>;
	var branches: Array<FlxSprite>;

	var leafAnimationTimer: FlxTimer;

	var storedState: Array<StoredState>;
	var stopTrunk: Bool;

	var currentPos: FlxPoint;
	var currentAngle: Float;

	var startingAngle = Math.PI / 2;

	var groundY: Float;
	var deltaAngle: Float = 45;

	var generations: Int = 6;

	//var trailArea: FlxTrailArea;

	var soundLeaves: FlxSound;
	var hint: FlxText;

	override public function create():Void
	{
		super.create();

		FlxG.scaleMode = new RatioScaleMode(false);
		FlxG.fixedTimestep = false;

		bgColor = 0xff1b0a2d;

		hint = new FlxText(10, 10, FlxG.width - 20, "click to (re)start | procjam 2017 | github.com/starry-abyss/golden-hours", 8);
		hint.alignment = RIGHT;
		hint.color = 0xffe38c2c;
		hint.pixelPerfectRender = true;
		//hint.setBorderStyle(SHADOW, 0xffefcd2f, 1);
		//hint.shadowOffset.set(1, 0);

		branchGroup = new FlxGroup();
		leafGroup = new FlxGroup();

		//trailArea = new FlxTrailArea(0, 0, FlxG.width, FlxG.height);

		add(branchGroup);
		add(hint);
		//add(trailArea);
		add(leafGroup);

		soundLeaves = new FlxSound();
		// https://freesound.org/people/Sandermotions/sounds/276294/ (CC0)
		soundLeaves.loadEmbedded("assets/sound/276294__sandermotions__leaves-in-wind.ogg", true);
		soundLeaves.volume = 0;
		soundLeaves.play();

		// this is where the leaves will stop falling
		var groundHeight = 100;
		groundY = FlxG.height - groundHeight;

		/*ground = new FlxSprite();
		ground.immovable = true;
		ground.makeGraphic(FlxG.width, groundHeight, FlxColor.TRANSPARENT);
		ground.setPosition(0, FlxG.height - groundHeight);
		add(ground);*/

		// generator of numbers
		random = new FlxRandom(Math.floor(Timer.stamp() * 1000));

		leaves = new Array<FlxSprite>();
		branches = new Array<FlxSprite>();

		currentIteration = 0;

		iterationTimer = new FlxTimer();
		leafAnimationTimer = new FlxTimer();

		leafAnimationTimer.start(0.3, function (_) leafAnimationCallback(), 0);

// INIT & EVALUATE

		generateTreeString();

// EXECUTE

		branch1 = new FlxSprite();
		branch1.loadGraphic("assets/images/branch3.png");
		branch2 = new FlxSprite();
		branch2.loadGraphic("assets/images/branch4.png");
		branch3 = new FlxSprite();
		branch3.loadGraphic("assets/images/branch5.png");

		branch_top1 = new FlxSprite();
		branch_top1.loadGraphic("assets/images/branch_top1.png");
		branch_top2 = new FlxSprite();
		branch_top2.loadGraphic("assets/images/branch_top2.png");
		branch_top3 = new FlxSprite();
		branch_top3.loadGraphic("assets/images/branch_top3.png");

		leaf = new FlxSprite();
		leaf.loadGraphic("assets/images/leaf4.png", true, 48, 32);

		root1 = new FlxSprite();
		root1.loadGraphic("assets/images/root2.png");
		root2 = new FlxSprite();
		root2.loadGraphic("assets/images/root3.png");
		root3 = new FlxSprite();
		root3.loadGraphic("assets/images/root4.png");

		trunk1 = new FlxSprite();
		trunk1.loadGraphic("assets/images/trunk2.png");
		trunk2 = new FlxSprite();
		trunk2.loadGraphic("assets/images/trunk3.png");
		trunk3 = new FlxSprite();
		trunk3.loadGraphic("assets/images/trunk4.png");

		trunk_top1 = new FlxSprite();
		trunk_top1.loadGraphic("assets/images/trunk_top2.png");
		trunk_top2 = new FlxSprite();
		trunk_top2.loadGraphic("assets/images/trunk_top3.png");
		trunk_top3 = new FlxSprite();
		trunk_top3.loadGraphic("assets/images/trunk_top4.png");

		var deltaPos = 10;

		var deltaAngleRight = Math.PI / 180.0 * deltaAngle;
		var angleCircle = 2 * Math.PI;
		var deltaAngleLeft = angleCircle - deltaAngleRight;

		function turnLeft()
		{
			currentAngle = (currentAngle + deltaAngleLeft) % angleCircle;
		}

		function turnRight()
		{
			currentAngle = (currentAngle + deltaAngleRight) % angleCircle;
		}

		reset();

		// interpret one symbol in the L-system-generated string
		iterationCallback 
			= function ()
			{
				var char = currentState.charAt(currentIteration);

				//var leafDraw = true;

				switch (char)
				{
					case "r":
						stopTrunk = false;
						//leafDraw = false;
						drawPart(randomSprite( [root1,root2,root3] ), currentPos, currentAngle);
					case "F" | "g" | "1" | "0" | " ":
						currentPos.x += deltaPos * Math.cos(currentAngle);
						currentPos.y -= deltaPos * Math.sin(currentAngle);

						if (char == "1")
						{
							//leafDraw = false;

							if (!stopTrunk)
								drawPart(randomSprite( [trunk1,trunk2,trunk3] ), currentPos, currentAngle);
							else
								drawPart(randomSprite( [branch1,branch2,branch3] ), currentPos, currentAngle);
						}
						else if (char == " ")
						{
							//leafDraw = false;
						}
						else
						{
							//leafDraw = true;

							if (stopTrunk)
								drawPart(randomSprite( [branch1,branch2,branch3] ), currentPos, currentAngle);

							drawPart(leaf, currentPos, startingAngle);
						}
					case "-":
						turnLeft();
						//leafDraw = false;
					case "+":
						turnRight();
						//leafDraw = false;
					case "[":
						storedState.push({ x: currentPos.x, y: currentPos.y, angle: currentAngle });
						turnLeft();
						//leafDraw = false;
					case "]":
						if (stopTrunk)
						{
							currentPos.x += deltaPos * Math.cos(currentAngle);
							currentPos.y -= deltaPos * Math.sin(currentAngle);
							drawPart(randomSprite( [branch_top1,branch_top2,branch_top3] ), currentPos, currentAngle);
						}

						{
							var state = storedState.pop();
							if (state == null)
								throw "nothing to pop from stack";

							currentPos.set(state.x, state.y);
							currentAngle = state.angle;
						}
						turnRight();
						//leafDraw = false;

						//if (stopTrunk)
						//	drawPart(randomSprite( [branch_top1,branch_top2,branch_top3] ), currentPos, currentAngle);

					case "X":
						//leafDraw = false;
					case s:
						throw 'unknown token: ${s}';
				}

				if (Math.abs(currentAngle - startingAngle) > 0.001)
				{
					if (!stopTrunk)
					{
						currentPos.y -= trunk_top1.height /** 0.1*/ / 2;
						drawPart(randomSprite( [trunk_top1,trunk_top2,trunk_top3] ), currentPos, startingAngle);
						currentPos.y += trunk_top1.height /** 0.1*/ / 2;
					}

					stopTrunk = true;
				}

				//if (leafDraw)
					//drawPart(leaf, currentPos, currentAngle);
				//	drawPart(leaf, currentPos, startingAngle);

				++currentIteration;
			}

		//drawPart(root, currentPos, currentAngle);
		if (timerEnabled)
		{
			
		}
		else
		{
			for (i in 0...currentState.length)
			{
				//currentIteration = i;
				iterationCallback();
			}
		}
	}

	// draw one leaf, branch part, etc
	function drawPart(part: FlxSprite, currentPos: FlxPoint, currentAngle: Float)
	{
		var sprite = part.clone();
		sprite.setPosition(currentPos.x - sprite.width / 2, currentPos.y - sprite.height / 2);
		sprite.angle = 90 - currentAngle / Math.PI * 180;
		//sprite.scale.set(0.1, 0.1);

		sprite.active = false;

		if (part == leaf)
		{
			leaves.push(sprite);
			leafGroup.add(sprite);
			//trailArea.add(sprite);
		}
		else
		{
			branches.push(sprite);
			branchGroup.add(sprite);
		}
	}

	// leaves animation and physics
	function leafAnimationCallback()
	{
		var newArray = new Array<FlxSprite>();

		var activeLeavesCount = 0;

		for (leaf in leaves)
		{
			//if (!leaf.isTouching(FlxObject.DOWN))

			var animate = true;

			if (leaf.active)
			{
				leaf.velocity.set(leaf.velocity.x + random.float(-15, 10), leaf.velocity.y + random.float(-5, 15));

				if (leaf.y > (groundY + random.float(-5, 5)) && leaf.velocity.y > 0)
				{
					animate = false;
					leaf.velocity.set();

					//leaf.velocity.x = 2 * leaf.velocity.x;
					//leaf.velocity.y = -0.2 * leaf.velocity.y;
				}
			}
			else
			{
				var i = random.int(0, 25);
				if (i == 0)
				{
					leaf.active = true;
				}
			}

			if (animate)
			{
				leaf.animation.frameIndex = (leaf.animation.frameIndex + random.int(0, 3)) % leaf.animation.frames;
				activeLeavesCount++;
			}

			if (!leaf.isOnScreen())
			{
				leafGroup.remove(leaf);
				//trailArea.remove(leaf);
				leaf.destroy();
			}
			else
			{
				newArray.push(leaf);
			}
		}

		leaves = newArray;

		soundLeaves.volume = Math.min(activeLeavesCount / 100.0, 1.0);
	}

	function randomSprite(sprites: Array<FlxSprite>): FlxSprite
	{
		if (sprites.length == 0)
			return null;

		var index = random.int(0, sprites.length - 1);

		return sprites[index];
	}

	function reset()
	{
		currentIteration = 0;

		storedState = new Array<StoredState>();
		stopTrunk = true;

		for (branch in branches)
		{
			branchGroup.remove(branch);
			branch.destroy();
		}

		if (branches.length > 0)
			branches = new Array<FlxSprite>();

		currentPos = new FlxPoint(FlxG.width / 2 + 100, FlxG.height - 10);
		currentAngle = startingAngle;
	}

	function generateTreeString()
	{

// INIT

		algorithm = new Array<Rule>();

		// -+ - change angle, [] - (re)store position and angle (also changes the angle)

		// start
		axiom = "S";
		// forest layout, r - puts root, T - starts the tree growth
		algorithm.push({ l:"S", r: ["       [+    rT]-------              ++++++[+   rT]-++++++                            ------[+  rT]-"] });
		// trunk/branch linear growth (without leaves)
		algorithm.push({ l:"1", r: ["11", "111"] });

		// branches and leaves

		/*algorithm.push({ l:"T", r: ["0[F]Fg"] });
		algorithm.push({ l:"F", r: ["[1g]gg1F"] });
		algorithm.push({ l:"0", r: ["11[1F]g[00]"] });*/

		algorithm.push({ l:"T", r: ["0[F]Fg", "0ggF[g]", "0++[gF]gF[g]"] });
		algorithm.push({ l:"F", r: ["[1g]gg1F", "-Fg++1g", "+[Fg]gg-Fg"] });
		algorithm.push({ l:"0", r: ["11[1F]g[00]", "11[1F]g[10F]"/*, "11[---gFF]---[ggFF]+F"*/] });

		// delta angle when turning
		deltaAngle = 15;

		// number of L-system generations
		generations = 6;

// EVALUATE

		// get the specified generation state for the L-system
		currentState = axiom;
		var nextState: String;
		for (generation in 1...generations)
		{
			nextState = "";

			for (i in 0...currentState.length)
			{
				var ruleTriggered = false;
				for (rule in algorithm)
				{
					if (currentState.charAt(i) == rule.l)
					{
						nextState += rule.r[random.int(0, rule.r.length - 1)];
						ruleTriggered = true;
						break;
					}
				}

				if (!ruleTriggered)
				{
					nextState += currentState.charAt(i);
				}
			}

			trace('generation ${generation}: ' + nextState);
			currentState = nextState;
		}
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		/*for (leaf in leaves)
		{
			if (FlxG.collide(leaf, ground) && leaf.velocity.y > 0)
			{
				leaf.velocity.x = 0;
			}
		}*/

		if (timerEnabled /*&& !iterationTimer.active*/ && FlxG.mouse.justPressed)
		{
			hint.visible = false;

			reset();

			// drop all current leaves on restart
			for (leaf in leaves)
			{
				if (!leaf.active)
				{
					leaf.velocity.set(leaf.velocity.x + random.float(-10, 10), leaf.velocity.y + random.float(-5, 15));
				}

				leaf.active = true;
			}

			generateTreeString();

			iterationTimer.start(0.05, function (_) if (currentIteration < currentState.length) iterationCallback(), 0);
		}
	}
}
