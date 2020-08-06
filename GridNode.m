//
//  GridNode.m
//  UXSDKOCSample
//
//  Created by J. Hiemstra on 29/07/2020.
//  2020 Xartec
//  Use this code however you please.

#define NROFLINES 20
#define rgb_r 0.1
#define rgb_g 0.85
#define rgb_b 0.1

#import "GridNode.h"


@implementation GridNode

typedef struct gridVert {
    float x, y, z, r, g, b;
} gridVert;


- (id) initWithInterval:(double)interval {
    self = [super init];
    
    self.currentInterval = interval;
    
    NSLog(@"creating grid");
    
    // set the number of points
    NSUInteger numPoints = 164;
    
    gridVert gridVerts[numPoints];
    float startX = -(NROFLINES*interval);
    
    //create horizontal lines
    for (NSUInteger i = 0; i < numPoints/2; i++) {
        
        gridVert vertex;
        float x = 0;
        float z = 0;
        
        x = startX;
        
        if (i % 2 == 0) {
            z = (NROFLINES*interval);
        } else {
            startX+=interval;
            z = -(NROFLINES*interval);
        }
        
        vertex.x = x;
        vertex.y = 0;
        vertex.z = z;
        
        vertex.r = rgb_r;
        vertex.g = rgb_g;
        vertex.b = rgb_b;
        
        gridVerts[i] = vertex;
    }
    
    float startZ = -(NROFLINES*interval);
    //create vert lines
    for (NSUInteger i = numPoints/2; i < numPoints; i++) {
        
        gridVert vertex;
        float x = 0;
        float z = 0;
        
        z = startZ;
        
        if (i % 2 == 0) {
            x = (NROFLINES*interval);
        } else {
            x = -(NROFLINES*interval);
            startZ+=interval;
        }
        
        vertex.x = x;
        vertex.y = 0;
        vertex.z = z;
        
        vertex.r = rgb_r;
        vertex.g = rgb_g;
        vertex.b = rgb_b;
        
        gridVerts[i] = vertex;
    }
    
    // convert array to grid data (position and color)
    NSData *gridData = [NSData dataWithBytes:&gridVerts length:sizeof(gridVerts)];
    
    // create vertex source
    SCNGeometrySource *vertexSource = [SCNGeometrySource geometrySourceWithData:gridData
                                                                       semantic:SCNGeometrySourceSemanticVertex
                                                                    vectorCount:numPoints
                                                                floatComponents:YES
                                                            componentsPerVector:3
                                                              bytesPerComponent:sizeof(float)
                                                                     dataOffset:0
                                                                     dataStride:sizeof(gridVert)];
    
    // create color source
    SCNGeometrySource *colorSource = [SCNGeometrySource geometrySourceWithData:gridData
                                                                      semantic:SCNGeometrySourceSemanticColor
                                                                   vectorCount:numPoints
                                                               floatComponents:YES
                                                           componentsPerVector:3
                                                             bytesPerComponent:sizeof(float)
                                                                    dataOffset:sizeof(float) * 3
                                                                    dataStride:sizeof(gridVert)];
    
    // create element
    SCNGeometryElement *element = [SCNGeometryElement geometryElementWithData:nil
                                                                primitiveType:SCNGeometryPrimitiveTypeLine
                                                               primitiveCount:numPoints/2
                                                                bytesPerIndex:sizeof(int)];
    
    // create geometry
    SCNGeometry *gridGeometry = [SCNGeometry geometryWithSources:@[ vertexSource, colorSource ] elements:@[ element]];
    

    self.geometry = gridGeometry;
    self.renderingOrder = -100; //grid is always rendered first.
    
    SCNProgram *gridShaderProgram = [SCNProgram new];
    gridShaderProgram.vertexFunctionName = @"myLineVertex";
    gridShaderProgram.fragmentFunctionName = @"myLineFragment";
    
    self.geometry.program = gridShaderProgram;
    
    self.name = @"Grid";
    
    return self;
}



@end
