package;

import Random;

import flash.Lib;
import flash.display.Stage;
import flash.display.Shape;
import flash.geom.Point;
import flash.display.Sprite;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.ui.Keyboard;
import flash.events.EventDispatcher;

class Main extends Sprite{

  //NOTE: Any new players must be added to this array
  var snakes: Array<Snake>;

  //Frame timer
  var fpsTimer:haxe.Timer;
  //There should only ever be one apple at a time
  var apple:Apple;

  function new(){
    super();
    init();
  }

  public function init(){

    Lib.current.addEventListener(KeyboardEvent.KEY_DOWN, Input);

    snakes = new Array<Snake>();
    //TODO: Create a keymap structure for cleanliness
    snakes.push(new Snake(100,150,1, 0x00FF00, Keyboard.A, Keyboard.D, Keyboard.W, Keyboard.S));
    snakes.push(new Snake(600,150,1, 0x0080BF, Keyboard.J, Keyboard.L, Keyboard.I, Keyboard.K));
    //Board dimensions are 960 x 640
    apple = new Apple(Random.int(35, 925), Random.int(35, 605));
    //Bounds is a singleton object
    Bounds.instance.DrawBounds();

    BeginFPSTimer();

  }

  /*NOTE: Perhaps another option would be to count frame using the built in EVERY_FRAME event and performing an
  update at set intervals*/
  private function BeginFPSTimer(){
    fpsTimer = new haxe.Timer(33); //tick frame every 33 milliseconds ~30 fps
    fpsTimer.run = Tick;
  }

  private function PauseFPSTimer(){
    if(fpsTimer != null){
      fpsTimer.stop();
    }
  }

  private function StopFPSTimer(){
    if(fpsTimer != null){
      fpsTimer.stop();
      fpsTimer = null;
    }
  }

  private function RestartFPSTimer(){
    if(fpsTimer != null){
      fpsTimer.run();
    }
  }
  //PROGRAM STATIC ENTRY POINT
  public static function main(){
    Lib.current.stage.align = flash.display.StageAlign.TOP_LEFT;
		Lib.current.stage.scaleMode = flash.display.StageScaleMode.NO_SCALE;
    Lib.current.addChild(new Main());
  }

  //
  private function Input(event:KeyboardEvent):Void{
  }

  private function Tick():Void{

     for(snake in snakes){
       snake.tick();

      if(snake.hasCollidedWithApple(apple)){

        //trace("Apple is located at ", apple.position.x, " , " ,apple.position.y);
        apple.eaten(snake);
        Lib.current.stage.removeChild(apple.sprite);
        apple = new Apple(Random.int(35, 925), Random.int(35, 605));
        Lib.current.stage.addChild(apple.sprite);
        //trace("Apple is located at ", apple.position.x, " , " ,apple.position.y);
      }

      if(snake.checkIfDead(snakes)){
      //  trace("ded");
        snake.die();
        snakes.remove(snake);


      }
     }
     if(snakes.length == 0){
       //Game over, restart!
       //De-Stage apple
       Lib.current.stage.removeChild(apple.sprite);
       StopFPSTimer();
       init();
     }
  }

}

class Snake{
  public var color = 0x000000;
  public var length = 3;
  public var speed = 5;
  public var headPosition = new Point(0,0);
  public var tailPositions:Array<Point> = new Array<Point>();
  public var size: Float = 1; //1 size unit = 10 pixels

  public static var pixelsPerUnit = 10;
  public static var pixelSpacing  = 8;

  public var directionX:Int = 1;
  public var directionY:Int = 0;

  public var head:Sprite = new Sprite();
  public var tail:Array<Sprite> = new Array<Sprite>();

  var commandLeft:UInt;
  var commandRight:UInt;
  var commandUp:UInt;
  var commandDown:UInt;

  public function new(x,y, size, color, commandLeft, commandRight, commandUp, commandDown){
    headPosition.x = x;
    headPosition.y = y;
    this.size = size;
    this.color = color;
    this.commandLeft = commandLeft;
    this.commandRight = commandRight;
    this.commandUp = commandUp;
    this.commandDown = commandDown;

    Lib.current.stage.addEventListener(KeyboardEvent.KEY_DOWN, Input);
    for(i in 0...length){
      tail[i] = new Sprite();
      tailPositions[i] = new Point();
      tailPositions[i].x = headPosition.x - ((i + 1) * (size * (pixelsPerUnit + 1)));
      tailPositions[i].y = headPosition.y;
    }
  }

  public function tick(){

    move();
    render();
  }

  public function Input(event:KeyboardEvent):Void{

    if (event.keyCode == commandLeft){
      //No hairpin turns allowed
        if(directionX == 0){
          //Make sure you are only travelling in one plane
          directionX = -1;
          directionY = 0;
        }

    }
    if (event.keyCode == commandRight){
      if(directionX == 0){
        directionX = 1;
        directionY = 0;
      }

    }
    if (event.keyCode == commandUp){
      if(directionY == 0){
        directionX = 0;
        directionY = -1;
      }

    }
    if(event.keyCode == commandDown){
      if(directionY == 0){
        directionX = 0;
        directionY = 1;
      }

    }
  }
  //Debug helper method, I previously had this assigned to the 'I' key
  public function PrintDebugInfo(){
    trace("Head Position is ", headPosition.x, ", ", headPosition.y);
    for(i in 0...tail.length){
      trace("Tail segement ", i, " positon is ", tailPositions[i].x, ",", tailPositions[i].y);
    }
  }

  public function render(){
    //Draw headPosition
    head.graphics.beginFill(color);
    head.graphics.drawRoundRect(0 ,0,pixelsPerUnit * size ,pixelsPerUnit * size, 1);
    head.x = headPosition.x;
    head.y = headPosition.y;
    head.graphics.endFill();

    Lib.current.stage.addChild(head);

    for(i in 0...tail.length){
      tail[i].graphics.beginFill(color);
      tail[i].graphics.drawRoundRect(0 ,0,pixelsPerUnit * size ,pixelsPerUnit * size, 1);
      tail[i].x = tailPositions[i].x;
      tail[i].y = tailPositions[i].y;
      tail[i].graphics.endFill();

      Lib.current.stage.addChild(tail[i]);
    //
    }
  }

  public function move(){
      //by updating from the back forwards we ensure that the snake only moves one tile per update
   var i = tail.length - 1;
    while(i > 0){
      //I multiply by 8 here just because I found that to be the spacing that looks best
      tailPositions[i].x = tailPositions[i - 1].x + (directionX * pixelSpacing * size * -1);
      tailPositions[i].y = tailPositions[i - 1].y + (directionY * pixelSpacing * size * -1);
      i--;
    }

    tailPositions[0].x = headPosition.x + (directionX * pixelSpacing * size * -1);
    tailPositions[0].y = headPosition.y + (directionY * pixelSpacing * size * -1);

    headPosition.x += speed * directionX;
    headPosition.y += speed * directionY;


  }
  /*hitTestPoint is not a perfect collision test by any means, however hitTestObject throws
  a runtime error if called between objects that are not parent/child */
  public function hasCollidedWithApple(apple:Apple):Bool{
    return head.hitTestPoint(apple.position.x, apple.position.y, false);
  }

  public function checkSelfCollision(s1:Sprite, s2:Sprite):Bool{
    return s1.hitTestPoint(s2.x, s2.y, true);
  }

  public function checkCollideWithSnake(snake:Snake){
    for(s in snake.tail){
      if(head.hitTestPoint(s.x, s.y, false)){
        return true;
      }
    }
    return false;
  }

  public function checkIfSegementIsOutOfBounds(sprite:Sprite):Bool{
    return(sprite.x < Bounds.instance.xBoundMin || sprite.x > Bounds.instance.xBoundMax
      || sprite.y < Bounds.instance.yBoundMax ||  sprite.y > Bounds.instance.yBoundMin);
      // {
      //   return true;
      // }
      // return false;

  }

  public function checkIfDead(snakes:Array<Snake>):Bool{
    if(checkIfSegementIsOutOfBounds(head)){
      return true;
    }
    for(i in 0...tail.length){
      if(checkIfSegementIsOutOfBounds(tail[i])){
        return true;
      }
    }
    //check head for self collide
    for(i in 0...tail.length){
      if(checkSelfCollision(head,tail[i])){
        return true;
      }
    }

    for(s in snakes){
      if(s != this){
        if(checkCollideWithSnake(s)){
          return true;
        }
      }
    }

    return false;
  }

  public function grow(){
    length++;
    tail[length - 1] = new Sprite();
    tailPositions[length - 1] = new Point();
    tailPositions[length - 1].x = tailPositions[length - 2].x + (directionX * pixelSpacing * size * -1);
    tailPositions[length - 1].y = tailPositions[length - 2].y + (directionY * pixelSpacing * size * -1);
    tail[length - 1].x = tailPositions[length - 1].x;
    tail[length - 1].y = tailPositions[length - 1].y;
    Lib.current.stage.addChild(tail[length - 1]);
  }

  public function die(){
    //remove each segement of the snake from the stage
    Lib.current.stage.removeChild(head);
    for(i in 0...tail.length){
      Lib.current.stage.removeChild(tail[i]);
    }
  }


}

class Apple{

  public var position:Point;
  public var sprite: Sprite;

  public function new(x,y){
    position = new Point(x,y);
    sprite = new Sprite();

    sprite.graphics.beginFill(0xFF0000);
    sprite.graphics.drawCircle(position.x, position.y, 5);

    Lib.current.stage.addChild(sprite);
  }

  public function eaten(s:Snake){
//    trace("eaten");
    s.grow();
  }
}

class Bounds{
  //The board does not implement any check to see if the board has been filled with snakes
  //However, given the size ratio, its pretty unlikely that this will happen currently.
  //for future ref a tiled board would probably have been simpler and lend itself better to such calculations
  //and also provide more accurate collision detection
  public var xBoundMin = 20;
  public var xBoundMax = 940;
  public var yBoundMin = 620;
  public var yBoundMax = 20;

  public var sprite:Sprite;

  public static var instance(default, null):Bounds = new Bounds();

  private function  new(){
    sprite = new Sprite();
  }

  public function DrawBounds(){
    sprite.graphics.lineStyle(2, 0x0000FF, 1);

    sprite.graphics.moveTo(xBoundMin, yBoundMin);
    sprite.graphics.lineTo(xBoundMin, yBoundMax);
    sprite.graphics.moveTo(xBoundMin, yBoundMin);
    sprite.graphics.lineTo(xBoundMax, yBoundMin);
    sprite.graphics.moveTo(xBoundMax, yBoundMax);
    sprite.graphics.lineTo(xBoundMax, yBoundMin);
    sprite.graphics.moveTo(xBoundMax, yBoundMax);
    sprite.graphics.lineTo(xBoundMin, yBoundMax);

    Lib.current.stage.addChild(sprite);
  }
}
