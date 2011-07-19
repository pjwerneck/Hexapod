

#include <Servo.h> 
 
// gait modes
#define WAVE 0
#define RIPPLE 1
#define TRIPOD 2

// movements
#define FORWARD 1
#define BACKWARD 2
#define TURN_R 3
#define TURN_L 4
#define STRAFE_R 5
#define STRAFE_L 6 
#define REST 7
 
 

// leg ids
#define R3 0
#define R2 1
#define R1 2
#define L1 3
#define L2 4
#define L3 5

#define TILT 0
#define PAN 1

#define MIN_SPEED_FACTOR 5
#define MAX_SPEED_FACTOR 20


// all servos
Servo joint[18];

// current value at the servos, in microseconds
int current_val[18];

// desired value at the servos, in microseconds
int target_val[18];

// current value, in degrees
int val[18] = {60, 60, 60, 60, 60, 60,
                0,  0,  0,  0,  0,  0,
                0,  0,  0,  0,  0,  0,
               };

// pins to attach to
int pins[18] = {33, 31, 29, 27, 25, 23,
                45, 43, 41, 39, 37, 35,
                32, 30, 28, 26, 24, 22,
                };

// max position
int pos_max[18] = {1394, 1110, 1030, 1960, 1640, 1390,
                   2200, 1020, 2200, 850,  800,  850,
                   2320, 2400, 2370, 720,  720,  560,
                  };

// min position
  int pos_min[18] = {1994, 1710, 1630, 1360, 1040, 790,
                    830, 2310,  880, 2180, 2120, 2160, 
                    610,  690,  610, 2400, 2400, 2270,
                  };

// some useful positions

// on ground with legs aligned at 90 degrees around the body
int initial[18] = {120, 60, 0, 0, 60, 120,
                   0,  0,  0,  0,  0,  0,
                   20, 20, 20, 20, 20, 20,
                  };

// standing at middle height
int hard_mid[18] = {60, 60, 60, 60, 60, 60,
                    90, 90, 90, 90, 90, 90,
                    60, 60, 60, 60, 60, 60,
                   };

// standing at bottom
int hard_bot[18] = {60, 60, 60, 60, 60, 60,
                    50, 50, 50, 50, 50, 50,
                    30, 30, 30, 30, 30, 30,
                   };

// standing up
int hard_top[18] = {60, 60, 60, 60, 60, 60,
                    120, 120, 120, 120, 120, 120,
                    110, 110, 110, 110, 110, 110,
                   };

// sort of a nice position for walking
int walking[18] = {60, 60, 60, 60, 60, 60,
                   90, 90, 90, 90, 90, 90,
                   60, 60, 60, 60, 60, 60,
                          };


int i = 0; 
int j = 0;
int n; 


int gait = 0;
int gait_mode = 0;

int gait_step = 0;
int gait_substep = 0;

int speed_factor = 20;

int halt = 0;

int servo_delay = 50;

// width and height according to mode
int current_width[3] = {20, 20, 20};
int current_height[3] = {30, 30, 45};


int (*func_gait)(int, int, int) = NULL;


void setup() 
{ 
  Serial.begin(19200);

  Serial.println("Starting");

  // attach everyone
  for (j=0; j < 18; j++){
    joint[j].attach(pins[j]);
    val[j] = initial[j];    
  }

  // initial position for everyone
  update_real();
  for (j=0; j < 18; j++){
    current_val[j] = target_val[j];    
    joint[j].writeMicroseconds(current_val[j]);
  }

} 

// Update everyone mapping the values from real
void update_real(){
  for (j=0; j < 18; j++){
    target_val[j] = map(val[j], 0, 120, pos_min[j], pos_max[j]);
  }
}

void set_mode(int mode){
  gait_mode = mode;
  gait_step = 0;
  gait_substep = 1;
}

void set_gait(int move){
  gait = move;
  gait_step = 0;
  gait_substep = 1;
}


// shortcut functions
void rise_fwd(int p, int h, int w){
  val[p] += w;
  val[p+6] -= h;
  //val[p+12] += h;
}

void down_fwd(int p, int h, int w){
  val[p] += w;
  val[p+6] += h;
  //val[p+12] -= h;
}

void rise_bwd(int p, int h, int w){
  val[p] -= w;
  val[p+6] -= h;
  //val[p+12] += h;
}

void down_bwd(int p, int h, int w){
  val[p] -= w;
  val[p+6] += h;
  //val[p+12] -= h;
}

void rise_push(int p, int h, int w){
  val[p+6] -= h;
  val[p+12] += w;
}

void down_push(int p, int h, int w){
  val[p+6] += h;
  val[p+12] += w;
}

void rise_pull(int p, int h, int w){
  val[p+6] -= h;
  val[p+12] -= w;
}

void down_pull(int p, int h, int w){
  val[p+6] += h;
  val[p+12] -= w;
}

void rise(int p, int h, int w){
  val[p+6] -= h;
}

void down(int p, int h, int w){
  val[p+6] += h;
}

void push(int p, int h, int w){
  val[p+12] += w;
}

void pull(int p, int h, int w){
  val[p+12] -= w;
}

//#########################################################################################
// WAVE 
//#########################################################################################

int gait_wave_forward(int oh, int ow, int finish){
  int h = (oh/speed_factor);
  int w = (ow/speed_factor);
  
  servo_delay = max(h, w) * 2;
 
  int beats[6] = {L1, L2, L3, R1, R2, R3};

  if(gait_step == 0){
    val[L1] -= 2*w;
    val[L2] -= 2*w;
    val[L3] -= 2*w;
    val[R1] -= 2*w;
    val[R2] -= 2*w;
    val[R3] -= 2*w;
  }

  if (gait_step == 1){
    rise_fwd(beats[0], h, 2*w);
  }
  if (gait_step == 2){
    down_fwd(beats[0], h, 2*w);
  }

  if (gait_step == 3){
    rise_fwd(beats[1], h, 2*w);
  }
  if (gait_step == 4){
    down_fwd(beats[1], h, 2*w);
  }

  if (gait_step == 5){
    rise_fwd(beats[2], h, 2*w);
  }
  if (gait_step == 6){
    down_fwd(beats[2], h, 2*w);
  }

  if (gait_step == 7){
    rise_fwd(beats[3], h, 2*w);
  }
  if (gait_step == 8){
    down_fwd(beats[3], h, 2*w);
  }

  if (gait_step == 9){
    rise_fwd(beats[4], h, 2*w);
  }
  if (gait_step == 10){
    down_fwd(beats[4], h, 2*w);
  }

  if (gait_step == 11){
    rise_fwd(beats[5], h, 2*w);
  }
  if (gait_step == 12){
    down_fwd(beats[5], h, 2*w);
  }

  if(gait_step == 13){
    val[L1] -= 2*w;
    val[L2] -= 2*w;
    val[L3] -= 2*w;
    val[R1] -= 2*w;
    val[R2] -= 2*w;
    val[R3] -= 2*w;
  }

  if (gait_substep <= speed_factor){
    gait_substep += 1;
  } else {
    gait_substep = 1;
    if (gait_step == 13){
      gait_step = 0;
      return 1;
    } else {
      gait_step += 1;
      return -1;      
    }
  }
  return 0;
}

int gait_wave_backward(int oh, int ow, int finish){
  int h = (oh/speed_factor);
  int w = (ow/speed_factor);
 
  servo_delay = max(h, w) * 2;

  int beats[6] = {R3, R2, R1, L3, L2, L1};
 
  if(gait_step == 0){
    val[L1] += 2*w;
    val[L2] += 2*w;
    val[L3] += 2*w;
    val[R1] += 2*w;
    val[R2] += 2*w;
    val[R3] += 2*w;
  }

  if (gait_step == 1){
    rise_bwd(beats[0], h, 2*w);
  }
  if (gait_step == 2){
    down_bwd(beats[0], h, 2*w);
  }

  if (gait_step == 3){
    rise_bwd(beats[1], h, 2*w);
  }
  if (gait_step == 4){
    down_bwd(beats[1], h, 2*w);
  }

  if (gait_step == 5){
    rise_bwd(beats[2], h, 2*w);
  }
  if (gait_step == 6){
    down_bwd(beats[2], h, 2*w);
  }

  if (gait_step == 7){
    rise_bwd(beats[3], h, 2*w);
  }
  if (gait_step == 8){
    down_bwd(beats[3], h, 2*w);
  }

  if (gait_step == 9){
    rise_bwd(beats[4], h, 2*w);
  }
  if (gait_step == 10){
    down_bwd(beats[4], h, 2*w);
  }

  if (gait_step == 11){
    rise_bwd(beats[5], h, 2*w);
  }
  if (gait_step == 12){
    down_bwd(beats[5], h, 2*w);
  }

  if(gait_step == 13){
    val[L1] += 2*w;
    val[L2] += 2*w;
    val[L3] += 2*w;
    val[R1] += 2*w;
    val[R2] += 2*w;
    val[R3] += 2*w;
  }

  if (gait_substep <= speed_factor){
    gait_substep += 1;
  } else {
    gait_substep = 1;
    if (gait_step == 13){
      gait_step = 0;
      return 1;
    } else {
      gait_step += 1;
      return -1;
    }
  }
  return 0;
}


int gait_wave_turn_right(int oh, int ow, int finish){
  int h = (oh/speed_factor);
  int w = (ow/speed_factor);
 
  servo_delay = max(h, w) * 2;

  int beats[6] = {L1, L2, L3, R3, R2, R1};
 
  if(gait_step == 0){
    val[beats[0]] -= 2*w;
    val[beats[1]] -= 2*w;
    val[beats[2]] -= 2*w;
    val[beats[3]] += 2*w;
    val[beats[4]] += 2*w;
    val[beats[5]] += 2*w;
  }

  if (gait_step == 1){
    rise_fwd(beats[0], h, 2*w);
  }
  if (gait_step == 2){
    down_fwd(beats[0], h, 2*w);
  }

  if (gait_step == 3){
    rise_fwd(beats[1], h, 2*w);
  }
  if (gait_step == 4){
    down_fwd(beats[1], h, 2*w);
  }

  if (gait_step == 5){
    rise_fwd(beats[2], h, 2*w);
  }
  if (gait_step == 6){
    down_fwd(beats[2], h, 2*w);
  }

  if (gait_step == 7){
    rise_bwd(beats[3], h, 2*w);
  }
  if (gait_step == 8){
    down_bwd(beats[3], h, 2*w);
  }

  if (gait_step == 9){
    rise_bwd(beats[4], h, 2*w);
  }
  if (gait_step == 10){
    down_bwd(beats[4], h, 2*w);
  }

  if (gait_step == 11){
    rise_bwd(beats[5], h, 2*w);
  }
  if (gait_step == 12){
    down_bwd(beats[5], h, 2*w);
  }

  if(gait_step == 13){
    val[beats[0]] -= 2*w;
    val[beats[1]] -= 2*w;
    val[beats[2]] -= 2*w;
    val[beats[3]] += 2*w;
    val[beats[4]] += 2*w;
    val[beats[5]] += 2*w;
  }

  if (gait_substep <= speed_factor){
    gait_substep += 1;
  } else {
    gait_substep = 1;
    if (gait_step == 13){
      gait_step = 0;
      return 1;
    } else {
      gait_step += 1;
      return -1;      
    }
  }
  return 0;
}

int gait_wave_turn_left(int oh, int ow, int finish){
  int h = (oh/speed_factor);
  int w = (ow/speed_factor);
 
  servo_delay = max(h, w) * 2;

  int beats[6] = {R1, R2, R3, L3, L2, L1};
 
  if(gait_step == 0){
    val[beats[0]] -= 2*w;
    val[beats[1]] -= 2*w;
    val[beats[2]] -= 2*w;
    val[beats[3]] += 2*w;
    val[beats[4]] += 2*w;
    val[beats[5]] += 2*w;
  }

  if (gait_step == 1){
    rise_fwd(beats[0], h, 2*w);
  }
  if (gait_step == 2){
    down_fwd(beats[0], h, 2*w);
  }

  if (gait_step == 3){
    rise_fwd(beats[1], h, 2*w);
  }
  if (gait_step == 4){
    down_fwd(beats[1], h, 2*w);
  }

  if (gait_step == 5){
    rise_fwd(beats[2], h, 2*w);
  }
  if (gait_step == 6){
    down_fwd(beats[2], h, 2*w);
  }

  if (gait_step == 7){
    rise_bwd(beats[3], h, 2*w);
  }
  if (gait_step == 8){
    down_bwd(beats[3], h, 2*w);
  }

  if (gait_step == 9){
    rise_bwd(beats[4], h, 2*w);
  }
  if (gait_step == 10){
    down_bwd(beats[4], h, 2*w);
  }

  if (gait_step == 11){
    rise_bwd(beats[5], h, 2*w);
  }
  if (gait_step == 12){
    down_bwd(beats[5], h, 2*w);
  }

  if(gait_step == 13){
    val[beats[0]] -= 2*w;
    val[beats[1]] -= 2*w;
    val[beats[2]] -= 2*w;
    val[beats[3]] += 2*w;
    val[beats[4]] += 2*w;
    val[beats[5]] += 2*w;
  }

  if (gait_substep <= speed_factor){
    gait_substep += 1;
  } else {
    gait_substep = 1;
    if (gait_step == 13){
      gait_step = 0;
      return 1;
    } else {
      gait_step += 1;
      return -1;      
    }
  }
  return 0;
}


int gait_wave_strafe_right(int oh, int ow, int finish){
  int h = (oh/speed_factor);
  int w = (ow/speed_factor);

  servo_delay = max(h, w) * 2;
 
  int beats[6] = {R1, R2, R3, L1, L2, L3};
 
  if (gait_step == 0){
    rise_push(R3, h, w);
  }

  if (gait_step == 1){
    down_push(R3, h, w);
  }

  if (gait_step == 2){
    rise_push(R2, h, w);
  }

  if (gait_step == 3){
    down_push(R2, h, w);
  }

  if (gait_step == 4){
    rise_push(R1, h, w);
  }

  if (gait_step == 5){
    down_push(R1, h, w);    
  }

  if (gait_step == 6){
    push(L1, h, 2*w);
    push(L2, h, 2*w);
    push(L3, h, 2*w);
    pull(R1, h, 2*w);
    pull(R2, h, 2*w);
    pull(R3, h, 2*w);
  }

  if (gait_step == 7){
    rise_pull(L3, h, w);
  }

  if (gait_step == 8){
    down_pull(L3, h, w);    
  }
  
  if (gait_step == 7){
    rise_pull(L2, h, w);
  }

  if (gait_step == 8){
    down_pull(L2, h, w);    
  }
  
  if (gait_step == 7){
    rise_pull(L1, h, w);
  }

  if (gait_step == 8){
    down_pull(L1, h, w);    
  }


  if (gait_substep <= speed_factor){
    gait_substep += 1;
  } else {
    gait_substep = 1;
    if (gait_step == 13){
      gait_step = 0;
      return 1;
    } else {
      gait_step += 1;
      return -1;      
    }
  }
  return 0;
}

int gait_wave_rest(int oh, int ow, int finish){
  return 1;
}

//#########################################################################################
// RIPPLE
//#########################################################################################

int gait_ripple_forward(int oh, int ow, int finish){
  int h = (oh/speed_factor);
  int w = (ow/speed_factor);
 
  servo_delay = max(h, w) * 2;

  if(gait_step == 0){
    val[L1] -= 2*w;
    val[L2] -= 2*w;
    val[L3] -= 2*w;
    val[R1] -= 2*w;
    val[R2] -= 2*w;
    val[R3] -= 2*w;
  }

  if (gait_step == 1){
    rise_fwd(L3, h, 2*w);
  }
  
  if (gait_step == 2){
    down_fwd(L3, h, 2*w);
    rise_fwd(R1, h, 2*w);
  }

  if (gait_step == 3){
    down_fwd(R1, h, 2*w);
    rise_fwd(L2, h, 2*w);
  }
  
  if (gait_step == 4){
    down_fwd(L2, h, 2*w);
    rise_fwd(R3, h, 2*w);
  }
  
  if (gait_step == 5){
    down_fwd(R3, h, 2*w);
    rise_fwd(L1, h, 2*w);
  }
  
  if (gait_step == 6){
    down_fwd(L1, h, 2*w);
    rise_fwd(R2, h, 2*w);
  }
  
  if (gait_step == 7){
    down_fwd(R2, h, 2*w);
  }

  if(gait_step == 8){
    val[L1] -= 2*w;
    val[L2] -= 2*w;
    val[L3] -= 2*w;
    val[R1] -= 2*w;
    val[R2] -= 2*w;
    val[R3] -= 2*w;
  }

  if (gait_substep <= speed_factor){
    gait_substep += 1;
  } else {
    gait_substep = 1;
    if (gait_step == 8){
      gait_step = 0 ;
      return 1;
    } else {
      gait_step += 1;
      return -1;      
    }
  }
  return 0;
}


int gait_ripple_backward(int oh, int ow, int finish){
  int h = (oh/speed_factor);
  int w = (ow/speed_factor);
 
  servo_delay = max(h, w) * 2;

  if(gait_step == 0){
    val[L1] += 2*w;
    val[L2] += 2*w;
    val[L3] += 2*w;
    val[R1] += 2*w;
    val[R2] += 2*w;
    val[R3] += 2*w;
  }

  if (gait_step == 1){
    rise_bwd(R1, h, 2*w);
  }
  
  if (gait_step == 2){
    down_bwd(R1, h, 2*w);
    rise_bwd(L3, h, 2*w);
  }

  if (gait_step == 3){
    down_bwd(L3, h, 2*w);
    rise_bwd(R2, h, 2*w);
  }
  
  if (gait_step == 4){
    down_bwd(R2, h, 2*w);
    rise_bwd(L1, h, 2*w);
  }
  
  if (gait_step == 5){
    down_bwd(L1, h, 2*w);
    rise_bwd(R3, h, 2*w);
  }
  
  if (gait_step == 6){
    down_bwd(R3, h, 2*w);
    rise_bwd(L2, h, 2*w);
  }
  
  if (gait_step == 7){
    down_bwd(L2, h, 2*w);
  }

  if(gait_step == 8){
    val[L1] += 2*w;
    val[L2] += 2*w;
    val[L3] += 2*w;
    val[R1] += 2*w;
    val[R2] += 2*w;
    val[R3] += 2*w;
  }

  if (gait_substep <= speed_factor){
    gait_substep += 1;
  } else {
    gait_substep = 1;
    if (gait_step == 8){
      gait_step = 0 ;
      return 1;
    } else {
      gait_step += 1;
      return -1;      
    }
  }
  return 0;
}

int gait_ripple_turn_right(int oh, int ow, int finish){
  int h = (oh/speed_factor);
  int w = (ow/speed_factor);

  servo_delay = max(h, w) * 2;
 
  int beats[6] = {L1, R3, L2, R2, L3, R1};

  if (gait_step == 0){
    val[R1] += 2*w;
    val[R2] += 2*w;
    val[R3] += 2*w;
    val[L1] -= 2*w;
    val[L2] -= 2*w;
    val[L3] -= 2*w;
  }

  if (gait_step == 1){
    rise_fwd(beats[0], h, 2*w);
  }
  
  if (gait_step == 2){
    down_fwd(beats[0], h, 2*w);
    rise_bwd(beats[1], h, 2*w);
  }
  
  if (gait_step == 3){
    down_bwd(beats[1], h, 2*w);
    rise_fwd(beats[2], h, 2*w);
  }

  if (gait_step == 4){
    down_fwd(beats[2], h, 2*w);
    rise_bwd(beats[3], h, 2*w);
  }

  if (gait_step == 5){
    down_bwd(beats[3], h, 2*w);
    rise_fwd(beats[4], h, 2*w);
  }

  if (gait_step == 6){
    down_fwd(beats[4], h, 2*w);
    rise_bwd(beats[5], h, 2*w);
  }

  if (gait_step == 7){
    down_bwd(beats[5], h, 2*w);
  }


  if (gait_step == 8){
    val[R1] += 2*w;
    val[R2] += 2*w;
    val[R3] += 2*w;
    val[L1] -= 2*w;
    val[L2] -= 2*w;
    val[L3] -= 2*w;
  }


  if (gait_substep <= speed_factor){
    gait_substep += 1;
  } else {
    gait_substep = 1;
    if (gait_step == 8){
      gait_step = 0 ;
      return 1;
    } else {
      gait_step += 1;
      return -1;      
    }
  }
  return 0;
}

int gait_ripple_turn_left(int oh, int ow, int finish){
  int h = (oh/speed_factor);
  int w = (ow/speed_factor);

  servo_delay = max(h, w) * 2;

  int beats[6] = {R1, L3, R2, L2, R3, L1};
 
  if (gait_step == 0){
    val[R1] -= 2*w;
    val[R2] -= 2*w;
    val[R3] -= 2*w;
    val[L1] += 2*w;
    val[L2] += 2*w;
    val[L3] += 2*w;
  }

  if (gait_step == 1){
    rise_fwd(beats[0], h, 2*w);
  }
  
  if (gait_step == 2){
    down_fwd(beats[0], h, 2*w);
    rise_bwd(beats[1], h, 2*w);
  }
  
  if (gait_step == 3){
    down_bwd(beats[1], h, 2*w);
    rise_fwd(beats[2], h, 2*w);
  }

  if (gait_step == 4){
    down_fwd(beats[2], h, 2*w);
    rise_bwd(beats[3], h, 2*w);
  }

  if (gait_step == 5){
    down_bwd(beats[3], h, 2*w);
    rise_fwd(beats[4], h, 2*w);
  }

  if (gait_step == 6){
    down_fwd(beats[4], h, 2*w);
    rise_bwd(beats[5], h, 2*w);
  }

  if (gait_step == 7){
    down_bwd(beats[5], h, 2*w);
  }


  if (gait_step == 8){
    val[R1] -= 2*w;
    val[R2] -= 2*w;
    val[R3] -= 2*w;
    val[L1] += 2*w;
    val[L2] += 2*w;
    val[L3] += 2*w;
  }


  if (gait_substep <= speed_factor){
    gait_substep += 1;
  } else {
    gait_substep = 1;
    if (gait_step == 8){
      gait_step = 0 ;
      return 1;
    } else {
      gait_step += 1;
      return -1;      
    }
  }
  return 0;
}

int gait_ripple_rest(int oh, int ow, int finish){
  return 1;
}

//#########################################################################################
// TRIPOD
//#########################################################################################

int gait_tripod_forward(int oh, int ow, int finish){
  int h = (oh/speed_factor);
  int w = (ow/speed_factor);
 
  servo_delay = max(h, w) * 2;

  if (gait_step == 0){
    rise_fwd(L1, h, w);
    rise_fwd(R2, h, w);
    rise_fwd(L3, h, w);
    val[R1] -= w;
    val[L2] -= w;
    val[R3] -= w;
  }

  if (gait_step == 1){
    down_fwd(L1, h, w);
    down_fwd(R2, h, w);
    down_fwd(L3, h, w);
    val[R1] -= w;
    val[L2] -= w;
    val[R3] -= w;
  }

  if (gait_step == 2){
    rise_fwd(R1, h, 2*w);
    rise_fwd(L2, h, 2*w);
    rise_fwd(R3, h, 2*w);
    val[L1] -= 2*w;
    val[R2] -= 2*w;
    val[L3] -= 2*w;
  }

  if (gait_step == 3){
    down_fwd(R1, h, 2*w);
    down_fwd(L2, h, 2*w);
    down_fwd(R3, h, 2*w);
    val[L1] -= 2*w;
    val[R2] -= 2*w;
    val[L3] -= 2*w;
  }
  
  // full double steps in here
  if (gait_step == 4){
    rise_fwd(L1, h, 2*w);
    rise_fwd(R2, h, 2*w);
    rise_fwd(L3, h, 2*w);
    val[R1] -= 2*w;
    val[L2] -= 2*w;
    val[R3] -= 2*w;
  }

  if (gait_step == 5){
    down_fwd(L1, h, 2*w);
    down_fwd(R2, h, 2*w);
    down_fwd(L3, h, 2*w);
    val[R1] -= 2*w;
    val[L2] -= 2*w;
    val[R3] -= 2*w;
  }

  if (gait_step == 6){
    rise_fwd(R1, h, 2*w);
    rise_fwd(L2, h, 2*w);
    rise_fwd(R3, h, 2*w);
    val[L1] -= 2*w;
    val[R2] -= 2*w;
    val[L3] -= 2*w;
  }

  if (gait_step == 7){
    down_fwd(R1, h, 2*w);
    down_fwd(L2, h, 2*w);
    down_fwd(R3, h, 2*w);
    val[L1] -= 2*w;
    val[R2] -= 2*w;
    val[L3] -= 2*w;
  }
  // full double steps end
  if (gait_step == 8){
    rise_fwd(L1, h, w);
    rise_fwd(R2, h, w);
    rise_fwd(L3, h, w);
    val[R1] -= w;
    val[L2] -= w;
    val[R3] -= w;
  }

  if (gait_step == 9){
    down_fwd(L1, h, w);
    down_fwd(R2, h, w);
    down_fwd(L3, h, w);
    val[R1] -= w;
    val[L2] -= w;
    val[R3] -= w;
  }


  if (gait_substep <= speed_factor){
    gait_substep += 1;
  } else {
    gait_substep = 1;
    if (finish){
      if (gait_step == 9){
        gait_step = 0;
        return 1;
      } else {
        gait_step += 1;
        return -1;      
      }
    } else {
      if (gait_step == 7){
        gait_step = 4;
        return 1;
      } else {
        gait_step += 1;
        return -1;      
      }
    }
  }
  return 0;
}


int gait_tripod_backward(int oh, int ow, int finish){
  int h = (oh/speed_factor);
  int w = (ow/speed_factor);
 
  servo_delay = max(h, w) * 2;

  if (gait_step == 0){
    rise_bwd(L1, h, w);
    rise_bwd(R2, h, w);
    rise_bwd(L3, h, w);
    val[R1] += w;
    val[L2] += w;
    val[R3] += w;
  }

  if (gait_step == 1){
    down_bwd(L1, h, w);
    down_bwd(R2, h, w);
    down_bwd(L3, h, w);
    val[R1] += w;
    val[L2] += w;
    val[R3] += w;
  }

  if (gait_step == 2){
    rise_bwd(R1, h, 2*w);
    rise_bwd(L2, h, 2*w);
    rise_bwd(R3, h, 2*w);
    val[L1] += 2*w;
    val[R2] += 2*w;
    val[L3] += 2*w;
  }

  if (gait_step == 3){
    down_bwd(R1, h, 2*w);
    down_bwd(L2, h, 2*w);
    down_bwd(R3, h, 2*w);
    val[L1] += 2*w;
    val[R2] += 2*w;
    val[L3] += 2*w;
  }
  
  // full double steps in here
  if (gait_step == 4){
    rise_bwd(L1, h, 2*w);
    rise_bwd(R2, h, 2*w);
    rise_bwd(L3, h, 2*w);
    val[R1] += 2*w;
    val[L2] += 2*w;
    val[R3] += 2*w;
  }

  if (gait_step == 5){
    down_bwd(L1, h, 2*w);
    down_bwd(R2, h, 2*w);
    down_bwd(L3, h, 2*w);
    val[R1] += 2*w;
    val[L2] += 2*w;
    val[R3] += 2*w;
  }

  if (gait_step == 6){
    rise_bwd(R1, h, 2*w);
    rise_bwd(L2, h, 2*w);
    rise_bwd(R3, h, 2*w);
    val[L1] += 2*w;
    val[R2] += 2*w;
    val[L3] += 2*w;
  }

  if (gait_step == 7){
    down_bwd(R1, h, 2*w);
    down_bwd(L2, h, 2*w);
    down_bwd(R3, h, 2*w);
    val[L1] += 2*w;
    val[R2] += 2*w;
    val[L3] += 2*w;
  }
  // full double steps end
  if (gait_step == 8){
    rise_bwd(L1, h, w);
    rise_bwd(R2, h, w);
    rise_bwd(L3, h, w);
    val[R1] += w;
    val[L2] += w;
    val[R3] += w;
  }

  if (gait_step == 9){
    down_bwd(L1, h, w);
    down_bwd(R2, h, w);
    down_bwd(L3, h, w);
    val[R1] += w;
    val[L2] += w;
    val[R3] += w;
  }

  if (gait_substep <= speed_factor){
    gait_substep += 1;
  } else {
    gait_substep = 1;
    if (finish){
      if (gait_step == 9){
        gait_step = 0;
        return 1;
      } else {
        gait_step += 1;
        return -1;      
      }
    } else {
      if (gait_step == 7){
        gait_step = 4;
        return 1;
      } else {
        gait_step += 1;
        return -1;      
      }
    }
  }
  return 0;
}

int gait_tripod_turn_left(int oh, int ow, int finish){
  int h = (oh/speed_factor);
  int w = (ow/speed_factor);
  
  servo_delay = max(h, w) * 2;

  if (gait_step == 0){
    rise_fwd(R1, h, w);
    rise_bwd(L2, h, w);
    rise_fwd(R3, h, w);
    val[L1] += w;
    val[R2] -= w;
    val[L3] += w;
  }
  
  if (gait_step == 1){
    down_fwd(R1, h, w);
    down_bwd(L2, h, w);
    down_fwd(R3, h, w);
    val[L1] += w;
    val[R2] -= w;
    val[L3] += w;
  }

  if (gait_step == 2){
    rise_bwd(L1, h, 2*w);
    rise_fwd(R2, h, 2*w);
    rise_bwd(L3, h, 2*w);
    val[R1] -= 2*w;
    val[L2] += 2*w;
    val[R3] -= 2*w;
  }
  
  if (gait_step == 3){
    down_bwd(L1, h, 2*w);
    down_fwd(R2, h, 2*w);
    down_bwd(L3, h, 2*w);
    val[R1] -= 2*w;
    val[L2] += 2*w;
    val[R3] -= 2*w;
  }

  if (gait_step == 4){
    rise_fwd(R1, h, 2*w);
    rise_bwd(L2, h, 2*w);
    rise_fwd(R3, h, 2*w);
    val[L1] += 2*w;
    val[R2] -= 2*w;
    val[L3] += 2*w;
  }
  
  if (gait_step == 5){
    down_fwd(R1, h, 2*w);
    down_bwd(L2, h, 2*w);
    down_fwd(R3, h, 2*w);
    val[L1] += 2*w;
    val[R2] -= 2*w;
    val[L3] += 2*w;
  }

  if (gait_step == 6){
    rise_bwd(L1, h, w);
    rise_fwd(R2, h, w);
    rise_bwd(L3, h, w);
    val[R1] -= w;
    val[L2] += w;
    val[R3] -= w;
  }
  
  if (gait_step == 7){
    down_bwd(L1, h, w);
    down_fwd(R2, h, w);
    down_bwd(L3, h, w);
    val[R1] -= w;
    val[L2] += w;
    val[R3] -= w;
  }

  if (gait_substep <= speed_factor){
    gait_substep += 1;
  } else {
    gait_substep = 1;
    if (finish){
      if (gait_step == 7){
        gait_step = 0;
        return 1;
      } else {
        gait_step += 1;
        return -1;      
      }
    } else {
      if (gait_step == 5){
        gait_step = 2;
        return 1;
      } else {
        gait_step += 1;
        return -1;      
      }
    }
  }
  return 0;
}

int gait_tripod_turn_right(int oh, int ow, int finish){
  int h = (oh/speed_factor);
  int w = (ow/speed_factor);
  
  servo_delay = max(h, w) * 2;

  if (gait_step == 0){
    rise_fwd(L1, h, w);
    rise_bwd(R2, h, w);
    rise_fwd(L3, h, w);
    val[R1] += w;
    val[L2] -= w;
    val[R3] += w;
  }
  
  if (gait_step == 1){
    down_fwd(L1, h, w);
    down_bwd(R2, h, w);
    down_fwd(L3, h, w);
    val[R1] += w;
    val[L2] -= w;
    val[R3] += w;
  }

  if (gait_step == 2){
    rise_bwd(R1, h, 2*w);
    rise_fwd(L2, h, 2*w);
    rise_bwd(R3, h, 2*w);
    val[L1] -= 2*w;
    val[R2] += 2*w;
    val[L3] -= 2*w;
  }
  
  if (gait_step == 3){
    down_bwd(R1, h, 2*w);
    down_fwd(L2, h, 2*w);
    down_bwd(R3, h, 2*w);
    val[L1] -= 2*w;
    val[R2] += 2*w;
    val[L3] -= 2*w;
  }

  if (gait_step == 4){
    rise_fwd(L1, h, 2*w);
    rise_bwd(R2, h, 2*w);
    rise_fwd(L3, h, 2*w);
    val[R1] += 2*w;
    val[L2] -= 2*w;
    val[R3] += 2*w;
  }
  
  if (gait_step == 5){
    down_fwd(L1, h, 2*w);
    down_bwd(R2, h, 2*w);
    down_fwd(L3, h, 2*w);
    val[R1] += 2*w;
    val[L2] -= 2*w;
    val[R3] += 2*w;
  }

  if (gait_step == 6){
    rise_bwd(R1, h, w);
    rise_fwd(L2, h, w);
    rise_bwd(R3, h, w);
    val[L1] -= w;
    val[R2] += w;
    val[L3] -= w;
  }
  
  if (gait_step == 7){
    down_bwd(R1, h, w);
    down_fwd(L2, h, w);
    down_bwd(R3, h, w);
    val[L1] -= w;
    val[R2] += w;
    val[L3] -= w;
  }

  if (gait_substep <= speed_factor){
    gait_substep += 1;
  } else {
    gait_substep = 1;
    if (finish){
      if (gait_step == 7){
        gait_step = 0;
        return 1;
      } else {
        gait_step += 1;
        return -1;      
      }
    } else {
      if (gait_step == 5){
        gait_step = 2;
        return 1;
      } else {
        gait_step += 1;
        return -1;      
      }
    }
  }
  return 0;
}

int gait_tripod_strafe_right(int oh, int ow, int finish){
  int h = (oh/speed_factor);
  int w = (ow/speed_factor);
 
  servo_delay = max(h, w) * 2;

  int beats[6] = {R1, R2, R3, L1, L2, L3};
 
  if (gait_step == 0){
    rise_push(R1, h, w);
  }

  if (gait_step == 1){
    down_push(R1, h, w);
  }

  if (gait_step == 2){
    rise_push(R3, h, w);
  }

  if (gait_step == 3){
    down_push(R3, h, w);
  }

  if (gait_step == 4){
    rise_push(R2, h, w);
    rise(L1, h, w);
    rise(L3, h, w);
  }
  
  if (gait_step == 5){
    push(L2, h, 2*w);
    pull(R1, h, 2*w);
    pull(R3, h, 2*w);
  }
      
  if (gait_step == 6){
    down_push(R2, h, w);
    down(L1, h, w);
    down(L3, h, w);
  }


  if (gait_substep <= speed_factor){
    gait_substep += 1;
  } else {
    gait_substep = 1;
    if (gait_step == 13){
      gait_step = 0;
      return 1;
    } else {
      gait_step += 1;
      return -1;      
    }
  }
  return 0;
}


int gait_tripod_rest(int oh, int ow, int finish){
  return 1;
}

//#########################################################################################
// MAINLOOP
//#########################################################################################

void loop(){ 
  char c;
  
  if (Serial.available()){
    c = Serial.read();
    
    
    
    if (c == 'r'){
      for (j=0; j < 6; j++)
        val[j] = initial[j];
    }
    
    if (c == 'R'){
      for (j=0; j < 18; j++)
        val[j] = initial[j];
    }

    if (c == 't'){
      for (j=0; j < 18; j++)
        val[j] = hard_top[j];
    }
        
    if (c == 'g'){
      for (j=6; j < 18; j++)
        val[j] = hard_mid[j];
    }

    if (c == 'b'){
      for (j=6; j < 18; j++)
        val[j] = hard_bot[j];
    }

    if (c == 'i'){
      for (j=0; j < 6; j++){
        val[j] += 10;
        if (val[j] >= 120)
          val[j] = 120;
      }
    }
    
    if (c == 'I'){
      for (j=0; j < 6; j++)
          val[j] = 120;
    }
       
    if (c == 'P'){
      for (j=0; j < 6; j++)
          val[j] = 0;
    }
      
    if (c == 'o'){
      for (j=0; j < 6; j++)
        val[j] = 60;
    }

    if (c == 'p'){
      for (j=0; j < 6; j++){
        val[j] -= 10;
        if (val[j] <= 0)
          val[j] = 0;
      }
    }

    // basejoint
    if (c == 'u'){
      for (j=12; j < 18; j++){
        val[j] += 10;
        if (val[j] >= 120)
          val[j] = 120;
      }
    }

    if (c == 'j'){
      for (j=12; j < 18; j++)
        val[j] = 60;
    }

    if (c == 'm'){
      for (j=12; j < 18; j++){
        val[j] -= 10;
        if (val[j] <= 0)
          val[j] = 0;
      }
    }

    // midjoint
    if (c == 'y'){
      for (j=6; j < 12; j++){
        val[j] += 10;
        if (val[j] >= 120)
          val[j] = 120;
      }
    }

    if (c == 'h'){
      for (j=6; j < 12; j++)
        val[j] = 60;
    }

    if (c == 'n'){
      for (j=6; j < 12; j++){
        val[j] -= 10;
        if (val[j] <= 0)
          val[j] = 0;
      }
    }

    if (c == 'x'){
      for (j=0; j < 6; j++)
        val[j] = walking[j];
    }

    if (c == 'X'){
      for (j=0; j < 18; j++)
        val[j] = walking[j];
    }


    // gait movement types
    if (c == 'w')
      set_gait(FORWARD);

    if (c == 's')
      set_gait(BACKWARD);
    
    if (c == 'd')
      set_gait(TURN_R);

    if (c == 'a')
      set_gait(TURN_L);

    if (c == 'e')
      set_gait(STRAFE_R);

    if (c == 'q')
      set_gait(STRAFE_L);

    if (c == 'z')
      set_gait(REST);

    // gait modes
    if (c == '1')
      set_mode(WAVE);

    if (c == '2')
      set_mode(RIPPLE);

    if (c == '3')
      set_mode(TRIPOD);


    if (gait_mode == WAVE){
      if (gait == FORWARD)
        func_gait = &gait_wave_forward;        
      if (gait == BACKWARD)
        func_gait = &gait_wave_backward;
      if (gait == TURN_R)
        func_gait = &gait_wave_turn_right;
      if (gait == TURN_L)
        func_gait = &gait_wave_turn_left;
      if (gait == STRAFE_R)
        func_gait = &gait_wave_strafe_right;
      if (gait == REST)
        func_gait = &gait_wave_rest;
    }
    
    if (gait_mode == RIPPLE){
      if (gait == FORWARD)
        func_gait = &gait_ripple_forward;        
      if (gait == BACKWARD)
        func_gait = &gait_ripple_backward;        
      if (gait == TURN_R)
        func_gait = &gait_ripple_turn_right;
      if (gait == TURN_L)
        func_gait = &gait_ripple_turn_left;
      if (gait == REST)
        func_gait = &gait_ripple_rest;
    }
    
    if (gait_mode == TRIPOD){
      if (gait == FORWARD)
        func_gait = &gait_tripod_forward;
      if (gait == BACKWARD)
        func_gait = &gait_tripod_backward;
      if (gait == TURN_R)
        func_gait = &gait_tripod_turn_right;
      if (gait == TURN_L)
        func_gait = &gait_tripod_turn_left;
      if (gait == REST)
        func_gait = &gait_tripod_rest;
    }

    if (c == '.'){
      while (1){
        update_real();
          for (j=0; j < 18; j++)
            current_val[j] = target_val[j];

          for (j=0; j < 18; j++)
            joint[j].writeMicroseconds(current_val[j]);

          // assure enough time for servos to move
          delay(servo_delay);
          // then some delay for speed adjustment
          delay(15);
          
          
          // go next step, or stop if needed
          halt = (*func_gait)(current_height[gait_mode], current_width[gait_mode], 0);
          if (halt != 0)
            break;
      }
    }
    

    if (c == ';'){
      // continuous move without finish
      while (1){
        update_real();
          for (j=0; j < 18; j++)
            current_val[j] = target_val[j];

          for (j=0; j < 18; j++)
            joint[j].writeMicroseconds(current_val[j]);

          // assure enough time for servos to move
          delay(servo_delay);
          // then some delay for speed adjustment
          delay(15);
          
          // go next step, or stop if needed
          halt = (*func_gait)(current_height[gait_mode], current_width[gait_mode], 0);
          if (halt == 1)
            break;
      }
    }

    if (c == ':'){
      // continuous move with finish call, if available
      while (1){
        update_real();
          for (j=0; j < 18; j++)
            current_val[j] = target_val[j];

          for (j=0; j < 18; j++)
            joint[j].writeMicroseconds(current_val[j]);

          // assure enough time for servos to move
          delay(servo_delay);
          // then some delay for speed adjustment
          delay(15);
          
          // go next step, or stop if needed
          halt = (*func_gait)(current_height[gait_mode], current_width[gait_mode], 1);
          if (halt == 1)
            break;
      }
    }

    if (c == '/'){
      Serial.print("Speed: ");            
      Serial.println(speed_factor, DEC);
      Serial.print("Height: ");
      Serial.println(current_height[gait_mode]);
      Serial.print("Width: ");
      Serial.println(current_width[gait_mode]);
    } 
    
    if (c == '?'){
      for (j=0; j < 6; j++){
        Serial.print(val[j], DEC);      
        Serial.print(", ");
      }
      Serial.println("");
      for (j=6; j < 12; j++){
        Serial.print(val[j], DEC);      
        Serial.print(", ");
      }
      Serial.println("");
      for (j=12; j < 18; j++){
        Serial.print(val[j], DEC);      
        Serial.print(", ");
      }
      Serial.println("");
    } 

    // SPEED
    if (c == '>'){
      speed_factor -= 5;
      speed_factor = constrain(speed_factor, MIN_SPEED_FACTOR, MAX_SPEED_FACTOR);
    }
    if (c == '<'){
      speed_factor += 5;
      speed_factor = constrain(speed_factor, MIN_SPEED_FACTOR, MAX_SPEED_FACTOR);
    }

    // HEIGHT
    if (c == '{'){
       current_height[gait_mode] -= 5;
       current_height[gait_mode] = constrain(current_height[gait_mode], 0, 60);
    }
    if (c == '}'){
       current_height[gait_mode] += 5;
       current_height[gait_mode] = constrain(current_height[gait_mode], 0, 60);
    }
    
    // WIDTH
    if (c == '['){
       current_width[gait_mode] -= 5;
       current_width[gait_mode] = constrain(current_width[gait_mode], 0, 60);
    }
    if (c == ']'){
       current_width[gait_mode] += 5;
       current_width[gait_mode] = constrain(current_width[gait_mode], 0, 60);
    }
  }

  update_real();

  for (j=0; j < 18; j++){
    current_val[j] = target_val[j];
    joint[j].writeMicroseconds(current_val[j]);
  }
}

  

