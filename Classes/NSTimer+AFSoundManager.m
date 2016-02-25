//
//  NSTimer+AFSoundManager.m
//  AFSoundManager-Demo
//
//  Created by Alvaro Franco on 10/02/15.
//  Copyright (c) 2015 AlvaroFranco. All rights reserved.
//

#import "NSTimer+AFSoundManager.h"
#import <objc/runtime.h>

static NSString *kIsPausedKey = @"IsPaused Key";
static NSString *kRemainingTimeIntervalKey  = @"RemainingTimeInterval Key";

@implementation NSTimer (AFSoundManager)

+(id)scheduledTimerWithTimeInterval:(NSTimeInterval)inTimeInterval block:(void (^)())inBlock repeats:(BOOL)inRepeats {
    
    void (^block)() = [inBlock copy];
    id ret = [self scheduledTimerWithTimeInterval:inTimeInterval target:self selector:@selector(jdExecuteSimpleBlock:) userInfo:block repeats:inRepeats];
    
    return ret;
}

+(id)timerWithTimeInterval:(NSTimeInterval)inTimeInterval block:(void (^)())inBlock repeats:(BOOL)inRepeats {
    
    void (^block)() = [inBlock copy];
    id ret = [self timerWithTimeInterval:inTimeInterval target:self selector:@selector(jdExecuteSimpleBlock:) userInfo:block repeats:inRepeats];
    
    return ret;
}

+(void)jdExecuteSimpleBlock:(NSTimer *)inTimer {
    
    if([inTimer userInfo]) {
        void (^block)() = (void (^)())[inTimer userInfo];
        block();
    }
}

- (NSMutableDictionary *)pauseDictionary {
    static NSMutableDictionary *globalDictionary = nil;
    
    if(!globalDictionary)
        globalDictionary = [[NSMutableDictionary alloc] init];
    
    if(![globalDictionary objectForKey:[NSNumber numberWithInt:(int)self]]) {
        NSMutableDictionary *localDictionary = [[NSMutableDictionary alloc] init];
        [globalDictionary setObject:localDictionary forKey:[NSNumber numberWithInt:(int)self]];
    }
    
    return [globalDictionary objectForKey:[NSNumber numberWithInt:(int)self]];
}

-(void)pauseTimer {
    NSLog(@"%s", __func__);
    if(![self isValid])
        return;
    
    NSNumber *isPausedNumber = [[self pauseDictionary] objectForKey:kIsPausedKey];
    if(isPausedNumber && YES == [isPausedNumber boolValue])
        return;
    
    NSDate *now = [NSDate date];
    NSDate *then = [self fireDate];
    NSTimeInterval remainingTimeInterval = [then timeIntervalSinceDate:now];
    
    [[self pauseDictionary] setObject:[NSNumber numberWithDouble:remainingTimeInterval] forKey:kRemainingTimeIntervalKey];
    
    [self setFireDate:[NSDate distantFuture]];
    [[self pauseDictionary] setObject:[NSNumber numberWithBool:YES] forKey:kIsPausedKey];
}

-(void)resumeTimer {
    NSLog(@"%s", __func__);
    if(![self isValid])
        return;
    
    NSNumber *isPausedNumber = [[self pauseDictionary] objectForKey:kIsPausedKey];
    if(!isPausedNumber || NO == [isPausedNumber boolValue])
        return;
    
    NSTimeInterval remainingTimeInterval = [[[self pauseDictionary] objectForKey:kRemainingTimeIntervalKey] doubleValue];
    
    NSDate *fireDate = [NSDate dateWithTimeIntervalSinceNow:remainingTimeInterval];
    
    [self setFireDate:fireDate];
    [[self pauseDictionary] setObject:[NSNumber numberWithBool:NO] forKey:kIsPausedKey];
}
@end
