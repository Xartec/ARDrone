//
//  DefaultLayoutViewController.m
//  UXSDKOCSample
//
//  MIT License
//
//  Copyright © 2018-2020 DJI
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:

//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.

//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//
#define RADIAN(x) ((x)*M_PI/180.0)
#define CALMODE YES

#define MAX_PARTICLES 50

#import "DefaultLayoutViewController.h"

@interface DefaultLayoutViewController () <DJIFlightControllerDelegate, DJIGimbalDelegate>

- (IBAction)onBackButtonClicked:(id)sender;

@end

@implementation DefaultLayoutViewController

BOOL measureMode;
CLLocationCoordinate2D homeLocation;
DJIGimbalAttitude gimbalAttinDegrees;
SCNNode *droneNode;
SCNNode *gimbalNode;
GridNode *theGridNode;

SCNNode *calBallNode;

BOOL sprayMode;
NSTimer* sprayTimer;
NSMutableArray *particlesInAir;
SCNNode* masterParticleNode;
SCNNode *fireextNode;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    SCNScene *newScene = [SCNScene new];
    self.arView.scene = newScene;
    self.arView.preferredFramesPerSecond = 30;
    self.arView.autoenablesDefaultLighting = YES;
    self.arView.scene.physicsWorld.gravity = SCNVector3Make(0, -2, 0);
    
    //create a node to represent the drone and add it to the 3D scene:
    droneNode = [SCNNode node];
    [self.arView.scene.rootNode addChildNode:droneNode];
    //droneNode.position = SCNVector3Make(0, 0, 0);
    
    //create a gimbal node and attach it to the drone node
    gimbalNode = [SCNNode node];
    [droneNode addChildNode:gimbalNode];
    
    //create a camera node and assign it to the gimbal node
    SCNCamera* gimbalCamera = [SCNCamera new];
    gimbalNode.camera = gimbalCamera;
    
    //set up the camera
    gimbalNode.camera.zNear = 0.01;
    gimbalNode.camera.zFar = 1000;
    gimbalNode.camera.projectionDirection = SCNCameraProjectionDirectionHorizontal;
    gimbalNode.camera.focalLength = 25;
    gimbalNode.camera.sensorHeight = 4.71;
    
    //set the main camera of the 3D scene to be the gimbal node
    self.arView.pointOfView = gimbalNode;
    
    //set the homelocation to invalid so we can check later if it's been set to valid coordinates
    homeLocation = kCLLocationCoordinate2DInvalid;
    
    //hide mini-map
    self.previewViewController.view.hidden = YES;
    DUXFPVViewController *fpvVC = (DUXFPVViewController*)self.contentViewController;
    //hide camera name
    fpvVC.fpvView.showCameraDisplayName = NO;
}

-(void)viewDidAppear:(BOOL)animated {
    //reset the delegates when the view appears.
    [self resetDelegates];
}

- (void) updateARDrone: (DJIGimbalAttitude)gimbalAtt altitude:(double)altitude {
 
    //update gimbal
    gimbalNode.simdRotation = simd_make_float4(1, 0, 0, RADIAN(gimbalAtt.pitch));
    
    //apply the altitude to the drone node
    droneNode.position = SCNVector3Make(0, altitude, 0);
   
}

- (void) updateDroneHeading:(double)heading {
    droneNode.simdRotation = simd_make_float4(0, -1, 0, RADIAN(heading));
}

- (void) updateDronePosition: (CLLocationCoordinate2D)newDroneCoord altitude:(double)altitude {

    //set the position of the virtual drone node
    //the center of the 3D world is mapped to the RTH point of the drone
    //to determine the desired location in the 3D world, we calculate the offset between the
    //drone’s current GPS location and the RTH point, and then convert it to meters.

    double latMid, m_per_deg_lat, m_per_deg_lon, deltaLat, deltaLon;
    latMid = (homeLocation.latitude+newDroneCoord.latitude )/2.0;
    
    //the following two lines are used to calculate a conversion factor for meters per degree for Longtitude and Latitude.
    m_per_deg_lat = 111132.954 - 559.822 * cos( 2.0 * latMid ) + 1.175 * cos( 4.0 * latMid);
    m_per_deg_lon = (M_PI/180 ) * 6367449 * cos ( latMid );
    
    //apply the offset between drone and home point to the virtual drone
    deltaLat = (newDroneCoord.latitude - homeLocation.latitude) * m_per_deg_lat;
    deltaLon = (newDroneCoord.longitude - homeLocation.longitude) * m_per_deg_lon;
    
    droneNode.position = SCNVector3Make(deltaLat, altitude, deltaLon);
    
    self.arDroneAltitude.text = [NSString stringWithFormat:@"Alt: %0.0fm", droneNode.position.y];
    self.arDronePos.text = [NSString stringWithFormat:@"Pos: %0.0f, %0.0f", droneNode.position.x,droneNode.position.z];

    //update gimbal
    //gimbalNode.rotation = SCNVector4Make(1, 0, 0, RADIAN(gimbalAttinDegrees.pitch));
       
}

- (void)resetDelegates {
    DJIFlightController* fc = [self fetchFlightController];
    if (fc) {
        fc.delegate = self;
    }
    
    DJIGimbal *gb = [self fetchGimbal];
    if (gb) {
        gb.delegate = self;
    }
    
}

-(void)flightController:(DJIFlightController *)fc didUpdateState:(DJIFlightControllerState *)state {
    
    if (measureMode) {
        [self updateARDrone:gimbalAttinDegrees altitude:state.altitude];
        //[self updateGrid:state.altitude];
        
    } else if (sprayMode) {
        
        //[self updateARDrone:gimbalAttinDegrees altitude:state.altitude];
        [self updateDroneHeading:state.attitude.yaw];
        [self updateDronePosition: state.aircraftLocation.coordinate altitude:state.altitude];
        
    }
    
    if (CALMODE) {
        [self updateDroneHeading:state.attitude.yaw];
        gimbalNode.simdRotation = simd_make_float4(1, 0, 0, RADIAN(gimbalAttinDegrees.pitch));
    }
    
    if (state.isHomeLocationSet) { //if real drone's RTH point has been set
        if (!CLLocationCoordinate2DIsValid(homeLocation)) { //and our stored homelocation is still invalid
            homeLocation = state.homeLocation.coordinate; //store the homelocation
        }
    }
    
}

- (void)gimbal:(DJIGimbal *)gimbal didUpdateState:(DJIGimbalState *)state {
    gimbalAttinDegrees = state.attitudeInDegrees; //store the gimbal attitude
}


//The following three methods are copied from DemoComponentHelper.m in the regular SDK and included here for completeness sake.
-(DJIFlightController*) fetchFlightController {
    if (![DJISDKManager product]) {
        return nil;
    }
    
    if ([[DJISDKManager product] isKindOfClass:[DJIAircraft class]]) {
        return ((DJIAircraft*)[DJISDKManager product]).flightController;
    }
    
    return nil;
}

-(DJIGimbal*) fetchGimbal {
    if (![DJISDKManager product]) {
        return nil;
    }
    
    if ([[DJISDKManager product] isKindOfClass:[DJIAircraft class]]) {
        return ((DJIAircraft*)[DJISDKManager product]).gimbal;
    }
    else if ([[DJISDKManager product] isKindOfClass:[DJIHandheld class]]) {
        return ((DJIHandheld*)[DJISDKManager product]).gimbal;
    }
    
    return nil;
}

- (IBAction)modeSegmentControlChanged:(UISegmentedControl*)sender {
    
    if (sender.selectedSegmentIndex==0) {
        measureMode = NO;
        
        //remove the grid:
        [theGridNode removeFromParentNode];
        self.gridSizeLabel.hidden = YES;
        
        if (CALMODE) {
            [calBallNode removeFromParentNode];
        }
        
    } else  if (sender.selectedSegmentIndex==1) {
        measureMode = YES;
        self.gridSizeLabel.hidden = NO;
        
        //add the grid:
        theGridNode = [[GridNode alloc] initWithInterval:2];
        [self.arView.scene.rootNode addChildNode:theGridNode];
        
        DUXFPVViewController* theContentView = (DUXFPVViewController*)self.contentViewController;
        DJIMovieGLView* theGLView;
        for (int i = 0; i< theContentView.fpvView.subviews.count; i++) {
            NSObject* viewTest = [theContentView.fpvView.subviews objectAtIndex:i];
            if ([viewTest isKindOfClass:[DJIMovieGLView class]]) {
                theGLView = (DJIMovieGLView*)viewTest;
                if ((DJIVideoPreviewer *)theGLView.delegate) {
                    //use this to set arview
                    [self.arView setFrame: CGRectMake(theGLView.frame.origin.x, theGLView.frame.origin.y+40, theGLView.frame.size.width, theGLView.frame.size.height)];

                    gimbalNode.camera.focalLength = 25;
                    gimbalNode.camera.sensorHeight = 4.71;
                }
            }
        }
         
        if (CALMODE) {
            SCNGeometry *sphereGeo = [SCNSphere sphereWithRadius:0.13625]; //radius of the circle on the wall
            calBallNode = [SCNNode nodeWithGeometry:sphereGeo];
            calBallNode.geometry.firstMaterial.diffuse.contents = [UIColor blueColor];
            
            //put sphere at drone pos
            calBallNode.worldPosition = SCNVector3Make(droneNode.worldPosition.x, droneNode.worldPosition.y, droneNode.worldPosition.z);
            
            //move sphere 3 meter in front of drone
            SCNMatrix4 infrontMat = SCNMatrix4MakeTranslation(droneNode.simdWorldFront.x*3.0, droneNode.simdWorldFront.y, droneNode.simdWorldFront.z*3.0);
            calBallNode.transform = SCNMatrix4Mult(calBallNode.transform, infrontMat);
            
            [self.arView.scene.rootNode addChildNode:calBallNode];
        }
        
    }
    
}

-(void)updateGrid:(double)altitude {
    
    double newInterval = 0;
    
    if (altitude>50 && theGridNode.currentInterval !=5) {
        //if altitude is > 50 meters and grid interval is not 5 meter, update grid
        newInterval = 5;
        
        [theGridNode removeFromParentNode];
        theGridNode = [[GridNode alloc] initWithInterval:newInterval];
        [self.arView.scene.rootNode addChildNode:theGridNode];
    }
}

- (IBAction)waterButtonDown:(id)sender {
    sprayMode = YES;
    SCNScene *fireextscn = [SCNScene sceneNamed:@"/fireext.scn"];
    fireextNode = [fireextscn.rootNode childNodeWithName:@"fireext" recursively:YES];
    fireextNode.position = SCNVector3Make(droneNode.position.x, droneNode.position.y-0.05, droneNode.position.z-0.12);
    [droneNode addChildNode:fireextNode];
    //self.arView.userInteractionEnabled = YES;
    
    sprayTimer = [NSTimer scheduledTimerWithTimeInterval:0.01666667
                                                              target:self
                                                            selector:@selector(addSprayParticle:)
                                                            userInfo:nil
                                                             repeats:YES];
    
    masterParticleNode = [fireextscn.rootNode childNodeWithName:@"sphere" recursively:YES];
    
    if (!particlesInAir) {
        particlesInAir = [NSMutableArray new];
    }
    
    self.arView.playing = YES;
}


-(void)addSprayParticle:(id)sender {
    
    SCNNode *newParticleNode = masterParticleNode.clone;
    
    
    //create particle at drone pos
    newParticleNode.worldPosition = SCNVector3Make(droneNode.worldPosition.x, droneNode.worldPosition.y - 0.05, droneNode.worldPosition.z);
    
    //move particle 0.1 meter in front of drone
    SCNMatrix4 infrontMat = SCNMatrix4MakeTranslation(droneNode.simdWorldFront.x*0.28, droneNode.simdWorldFront.y*0.28, droneNode.simdWorldFront.z*0.28);
    newParticleNode.transform = SCNMatrix4Mult(newParticleNode.transform, infrontMat);

    newParticleNode.physicsBody = [SCNPhysicsBody dynamicBody];
    newParticleNode.physicsBody.type = SCNPhysicsBodyTypeDynamic;
    newParticleNode.physicsBody.affectedByGravity = YES;
    newParticleNode.physicsBody.collisionBitMask = 0;
    newParticleNode.physicsBody.mass = 0.001;
    newParticleNode.physicsBody.damping = 0.01;
    newParticleNode.physicsBody.velocity = SCNVector3Make(droneNode.simdWorldFront.x*6, droneNode.simdWorldFront.y*6, droneNode.simdWorldFront.z*6);
    
    [particlesInAir addObject:newParticleNode];
    [self.arView.scene.rootNode addChildNode:newParticleNode];
    
    if (particlesInAir.count > MAX_PARTICLES) {
        [particlesInAir.firstObject removeFromParentNode];
        [particlesInAir removeObject: particlesInAir.firstObject];
    }
}


- (IBAction)waterButtonReleased:(id)sender {
    sprayMode = NO;
    [sprayTimer invalidate];
    for (SCNNode* particle in particlesInAir) {
        [particle removeFromParentNode];
    }

    [particlesInAir removeAllObjects];
    
    self.arView.playing = NO;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onBackButtonClicked:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
