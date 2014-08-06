//*SETTINGS FOR ANIMATIONS*
//LINE_STEPS = 10
final int ITERS = 11;//number of iterations to draw the tree
final float ANGLE_FACTOR = PI/3;//constant for setting the angle factor of the tree
final float ANGLE_SHAKE = PI/6;
final float LENGTH_SHAKE = 0.9;//percentage value from 0-1 delimiting how much a line can shrink
final float SHRINK_FACTOR = 0.67;
final int LINE_STEPS = 10;
final int SW=700, SH=500;
final float TRUNK_LEN = 150;//initial tree trunk length
final float TRUNK_ANGLE = -90;//initial trunk angle from the ground
final float MAX_END_FRAMES = 15;//how many frames to draw after the tree is finished being drawn (for gif export).

binTree bTree;
int endFramesDrawn;

void setup(){
  strokeWeight(0.5);
  size(SW,SH);
  background(255);
  //create a new tree object
  //starting point will be x in the middle, y 2/3 down from the top
  bTree = new binTree(SW/2, SH-(SH/6), TRUNK_LEN, TRUNK_ANGLE, ITERS);
  endFramesDrawn = 0;
}

void draw(){
  bTree.draw_me();
  if(!bTree.finished || endFramesDrawn < MAX_END_FRAMES){
    //saveFrame("btree###.gif");
    if(bTree.finished){
       ++endFramesDrawn; 
    }
  }
}

class Point{
  float x, y;
  Point(float _x, float _y){
    x = _x;
    y = _y;
  }
  Point(){
    x = 0;
    y = 0;
  }
}
/*
float pointDist(Point p0, Point p1){
  float result;
  result = sqrt(pow(p1.y-p0.y,2)+pow(p1.x-p0.x,2));
  return result;
}
*/

//binTree is dependent on the easeLine class
class binTree{
  int x;//x coordinate for placement of base of tree
  int y;//y coordinate for placement of base of tree
  float initial_angle;//the angle of the 'trunk' at the base (radians)
  float start_length;//length of the first line to be drawn
  float current_length;//the length of the current iteration of leaves
  float shrink_factor;//amount to shrink the lines each time
  float angle_shake_range;//the range at which the angle will vary randomly
  float length_shake_range;//the range at which the length will vary randomly
  int line_steps;//how many steps to draw each line
  float angle_factor;//how much to modify the angle each level
  int iterations;//how many levels of the tree to draw
  ArrayList<easeLine> tree;//the list that will hold all of the lines of the tree
  int leaf_index;//where the first leaf line currently is in the line list
  int current_iteration;
  boolean finished;
  
  int current_step;
  
  binTree(int _x, int _y, float _start_length, float _initial_angle, int _iterations){
    x = _x;
    y = _y;
    start_length = abs(_start_length);//must be positive since it's a distance
    //initial angle will be in degrees
    //it must be 'unwound' and then converted to radians
    initial_angle = (PI*(_initial_angle%360))/180;
    iterations = abs(_iterations);
    init();
  }
  //the init function does all of the non-parameterized initialization
  void init(){
    finished = false;
    shrink_factor = SHRINK_FACTOR;//will shrink by half each time
    line_steps = LINE_STEPS;
    current_step = 0;
    current_length = start_length;
    angle_factor = ANGLE_FACTOR;
    angle_shake_range = ANGLE_SHAKE;
    length_shake_range = LENGTH_SHAKE;
    tree = new ArrayList<easeLine>();
  }
  
  void tree_setup(){
    //this is where all of the initialization for the tree generation will take place.
    //The first step is to add a single like at the right angle and distance
    Point p1 = new Point(x,y);
    Point p2 = new Point(x+(start_length*cos(initial_angle)),y+(start_length*sin(initial_angle)));
    tree.add(new easeLine(p1,p2,line_steps));
    leaf_index = tree.size()-1;
    current_iteration = 0;//ieration 0 includes the tree trunk
  }
  //leaf_generate function
  //purpose: Generates the next iteration of leaves on the tree
  void leaf_generate(){
    //Start are the first leaf which is located at leaf_index.
    //For each leaf, generate 2 new leaves
    
    //first set the length of the new leaves using the shrink_factor
    current_length *= shrink_factor;
    float temp_angle;//temp value to store angle of seeding branch
    Point p1,p2;//temp points to seed new branches
    float randAngle1, randAngle2;//these store randomly generated angles.
    float randLength1,randLength2;//will store the random value generated that determines the length
    int temp_index = leaf_index;//temporary variable to store leaf_index,
    
    //set leaf_index to qual start of next series of leaves.
    leaf_index = tree.size();
    for(int i = temp_index; i < leaf_index; ++i){
      //generate random shake values.
      randLength1 = random(-length_shake_range/2,length_shake_range/2);
      randLength2 = random(-length_shake_range/2,length_shake_range/2);
      randAngle1 = random(-angle_shake_range/2,angle_shake_range/2);
      randAngle2 = random(-angle_shake_range/2,angle_shake_range/2);
      //the new length and new angle of each leaf is based on the one before it.
      current_length = tree.get(i).getLength() * shrink_factor;
      temp_angle=tree.get(i).getAngle();
      //two new points will be created
      p1 = new Point(tree.get(i).p2.x+((1-randLength1)*current_length*cos(temp_angle+angle_factor+randAngle1)), tree.get(i).p2.y+((1-randLength1)*current_length*sin(temp_angle+angle_factor+randAngle1)));
      p2 = new Point(tree.get(i).p2.x+((1-randLength2)*current_length*cos(temp_angle-angle_factor+randAngle2)), tree.get(i).p2.y+((1-randLength2)*current_length*sin(temp_angle-angle_factor+randAngle2)));

      tree.add(new easeLine( tree.get(i).p2, p1, line_steps));
      tree.add(new easeLine( tree.get(i).p2, p2, line_steps));
    }
    print("iteration "+(current_iteration+1)+" generated\n");
  }
  void draw_me(){
    
    
    if(current_step==0){
      //if this is the first frame the tree is being drawn, set up the tree
      tree_setup();
    }
    //The tree will be drawn using an array.
    //A variable will mark the index at which the current "leaf" lines begin.
    //Once the leaf lines ease to completion, new leaf lines will be generated.
    //These leaf lines will then be added to the list and the index marker is updated.
    for(int i = 0; i < tree.size(); ++i){
      tree.get(i).draw_me();
    }
    //Check to see if the leaf line at leaf_index is finished being drawn yet.
    //If it has, we can assume that every leaf is also finished and it is time to
    //either quit or generate the next level
    if(tree.get(leaf_index).finished && current_iteration < iterations){
      leaf_generate();
      ++current_iteration;
    }else if(tree.get(leaf_index).finished && current_iteration == iterations){
      finished = true;
    }
    ++current_step;
  }
  
}


//The easeLine class
//Creates and line that can be drawn step by step
//the line eases using an ease function
//Dependent on the Point class
class easeLine{
  static final int MAX_STEPS_DEFAULT = 10;
  Point p1,p2;
  int max_steps;//The maximum number of "frames" for drawing a line
  int current_step;
  float DY,DX;
  boolean finished;
  void init(){
    finished = false;
    current_step = 0;
  }
  easeLine(Point start_point, Point end_point, int maxSteps){
    p1 = start_point;
    p2 = end_point;
    max_steps = maxSteps;
    init();
  }
  easeLine(Point start_point, Point end_point){
    p1 = start_point;
    p2 = end_point;
    max_steps = MAX_STEPS_DEFAULT;
    init();
  }
  void draw_me(){
      if(current_step < max_steps){
        //draw line to current_step/max_steps percent distance
        //from p1 to p2
        //decomp:
        //1) get distance between 2 points
        float tempLength = getLength();
        //2) get percentage distance between the two points
        float percent = float(current_step)/max_steps;
        float eased = expo(percent);
        //3) draw a line of percentage distance between p1 and p2
        //3a) get angle of line between p1 and p2
        float angle = getAngle();//in radians
        //3b) use cos/sin to draw line w/ polar coordinates
        line(p1.x,p1.y,p1.x+(cos(angle)*tempLength*eased),p1.y+(sin(angle)*tempLength*eased));
        ++current_step;
      }else{
        //draw the line normally
        line(p1.x,p1.y,p2.x,p2.y);
        finished = true;
      }
      
  }
  //getLength() replaces the lineDist memeber variable,
  //this is to make the easeLine class more dynamic and versatile.
  float getLength(){
      return sqrt(pow(p2.y-p1.y,2)+pow(p2.x-p1.x,2));
  }
  float getAngle(){
    return atan2(p2.y-p1.y,p2.x-p1.x);
  }
  final float e = 2.7182818284590;//constant delimiting the natural number, e
  //This function is 
  //precondition: float between 0 and 1
  //              e is the natural number
  //credit: James Anderson (AKA DissidentIV)
  float expo(float x){
    final int SQUISH = 6;//this is a factor that transforms the function
    x = abs(x);
    //this is the original return value. Since it broke, trying a refactored version
    //return (res==0)? 0 : 1 + pow(-e, -SQUISH * res);
    return (x==0)? 0 : 1 + (-1*(1/pow(e, SQUISH * x)));
  }
}

//precondition: float between 0 and 1
float square(float x){
  final int FACTOR = 2;
  float res = abs(x);
  return (res==0)? 0 : pow(x,1.0/FACTOR);
}
