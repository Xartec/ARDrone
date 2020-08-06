# ARDrone
Augmented Reality Demo for DJI Drones


This demo is part of a tutorial in the DJI dev forums and requires DJI IOS UX SDK (download version 4.13). 

Replace the files in the DefaultLayout with the files in this repos. Add the waterdropicon folder to Assets.xcassets.

For more info see: https://forum.dji.com/forum.php?mod=viewthread&tid=221710

For a demo vid see: https://github.com/Xartec/ARDrone

Note: this rough demo is created with a DJI Spark and for an iPad Pro 10.5". With other drones and other mobiles devices the FoV (sensorHeight and FocalLength camera properties) need to be adjusted.  

How to use the app in Measure Mode:
 - Connect to your DJI drone, wait till drone has sufficient satellites connected and is in GPS mode and recorded RTH point. Put the drone in Video mode.
 - Take off, tap Grid On to have the SceneKit overlay match the video feed and to enter Measure Mode. By default each square in the grid is 2x2 meter. Code for adjusting the grid size based on altitude is included by not enabled.
 
 
How to use the app in fire extinguisher Mode:
 - Connect to your DJI drone, wait till drone has sufficient satellites connected and is in GPS mode and recorded RTH point.  Put the drone in Video mode.
 - Take off, tap Grid On to have the SceneKit overlay match the video feed. Tap Grid Off. Hold down the water drop button to spray 'water'.
 
 The water sphere's are loaded from a scn file because the SCNSphere objects provided by SceneKit are horrible for performance.
 
 
 
