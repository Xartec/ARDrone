//
//  GridNode.h
//  UXSDKOCSample
//
//  Created by J.Hiemstra on 29/07/2020.
//  2020 Xartec
//  Use this code however you please.

#import <SceneKit/SceneKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface GridNode : SCNNode

- (id) initWithInterval:(double)interval;


@property (assign) double currentInterval;

@end

NS_ASSUME_NONNULL_END
