//
//  AFSoundQueue.m
//  AFSoundManager-Demo
//
//  Created by Alvaro Franco on 21/01/15.
//  Copyright (c) 2015 AlvaroFranco. All rights reserved.
//

#import "AFSoundQueue.h"
#import "AFSoundManager.h"
#import "NSTimer+AFSoundManager.h"

#import <objc/runtime.h>

@interface AFSoundQueue ()

@property (nonatomic, strong) AFSoundPlayback *queuePlayer;
@property (nonatomic, strong) NSMutableArray *items;

@property (nonatomic, strong) NSTimer *feedbackTimer;

@end

@implementation AFSoundQueue

-(id)initWithItems:(NSArray *)items {
    
    if (self == [super init]) {
        
        if (items) {
            
            _items = [NSMutableArray arrayWithArray:items];
            _queuePlayer = [[AFSoundPlayback alloc] initWithItem:items.firstObject];
            
            [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
        }
    }
    
    return self;
}

-(void)listenFeedbackUpdatesWithBlock:(feedbackBlock)block andFinishedBlock:(itemFinishedBlock)finishedBlock {
    
    CGFloat updateRate = 0.5f;
    
    if (_queuePlayer.player.rate > 0) {
        
        updateRate = 1 / _queuePlayer.player.rate;
    }
    
    _feedbackTimer = [NSTimer scheduledTimerWithTimeInterval:updateRate block:^{
        if (self.queuePlayer && self.queuePlayer.currentItem) {
            
            if (self.queuePlayer.currentItem.timePlayed > 0) {
                [self updateNowPlayingInfo];
            }
            
            if (block) {
                _queuePlayer.currentItem.timePlayed = (int)CMTimeGetSeconds(_queuePlayer.player.currentTime);
                block(_queuePlayer.currentItem);
            }
            
            if (self.queuePlayer.currentItem.timePlayed == self.queuePlayer.currentItem.duration) {
                
                if (finishedBlock) {
                    
                    if ([self indexOfCurrentItem] + 1 < [self.dataSource numberOfItems]) {
                        AFSoundItem *nextItem = [self.dataSource itemAtIndex:[self indexOfCurrentItem] + 1];
                        finishedBlock(nextItem);
                    } else {
                        finishedBlock(nil);
                    }
                }
                
                [_feedbackTimer pauseTimer];
                
                [self playNextItem];
            }
        }
        
    } repeats:YES];
    [_feedbackTimer pauseTimer];
}

-(void)addItem:(AFSoundItem *)item {
    
    [self addItem:item atIndex:_items.count];
}

-(void)addItem:(AFSoundItem *)item atIndex:(NSInteger)index {
    
    [_items insertObject:item atIndex:(_items.count >= index) ? _items.count : index];
}

-(void)removeItem:(AFSoundItem *)item {
    
    if ([_items containsObject:item]) {
        
        [self removeItemAtIndex:[_items indexOfObject:item]];
    }
}

-(void)removeItemAtIndex:(NSInteger)index {
    
    if (_items.count >= index) {
        
        AFSoundItem *item = _items[index];
        [_items removeObject:item];
        
        if (_queuePlayer.currentItem == item) {
            
            [self playNextItem];
            
            [_feedbackTimer resumeTimer];
        }
    }
}

-(void)clearQueue {
    
    [_queuePlayer pause];
    [_items removeAllObjects];
    [_feedbackTimer pauseTimer];
}

-(void)playCurrentItem {
    
    [_queuePlayer play];
    [[MPRemoteCommandCenter sharedCommandCenter] playCommand];
    
    [_feedbackTimer resumeTimer];
}

-(void)pause {
    [_feedbackTimer pauseTimer];
    [_queuePlayer pause];
    [[MPRemoteCommandCenter sharedCommandCenter] pauseCommand];
}

-(void)playNextItem {
    NSInteger nextIndex = [self.dataSource indexOfItem:[self.queuePlayer currentItem]] + 1;
    if ([self.dataSource numberOfItems] > nextIndex) {
        [self playItemAtIndex:nextIndex];
    }
}

-(void)playPreviousItem {
    NSInteger prevIndex = [self.dataSource indexOfItem:[self.queuePlayer currentItem]] - 1;
    if (prevIndex >= 0) {
        [self playItemAtIndex:prevIndex];
    }
}

-(void)playItemAtIndex:(NSInteger)index {
    
    if (self.dataSource) {
        if ([self.dataSource numberOfItems] > index && index >=0 ) {
            AFSoundItem *item = [self.dataSource itemAtIndex:index];
            [self playItem:item];
        }
    }
}

-(void)playItem:(AFSoundItem *)item {
    [self playItem:item atSecond:0];
}

-(void)playItem:(AFSoundItem *)item atSecond:(NSInteger)second {
    if (self.queuePlayer.status == AFSoundStatusNotStarted || self.queuePlayer.status == AFSoundStatusPaused || self.queuePlayer.status == AFSoundStatusFinished) {
        [self.feedbackTimer resumeTimer];
    }
    self.queuePlayer = [[AFSoundPlayback alloc] initWithItem:item];
    if (second > 0) {
        [self.queuePlayer playAtSecond:second];
    } else {
        [self.queuePlayer play];
    }
    
    [[MPRemoteCommandCenter sharedCommandCenter] playCommand];
}

-(AFSoundItem *)getCurrentItem {
    
    return _queuePlayer.currentItem;
}

-(NSInteger)indexOfCurrentItem {
    
    AFSoundItem *currentItem = [self getCurrentItem];
    return [self.dataSource indexOfItem:currentItem];
    
    return NAN;
}

-(void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent {
    
    if (receivedEvent.type == UIEventTypeRemoteControl) {
        
        switch (receivedEvent.subtype) {
                
            case UIEventSubtypeRemoteControlPreviousTrack:
                [self playPreviousItem];
                break;
                
            case UIEventSubtypeRemoteControlNextTrack:
                [self playNextItem];
                break;
                
            default:
                break;
        }
    }
}

-(AFSoundStatus)status {
    return self.queuePlayer ? [self.queuePlayer status] : AFSoundStatusNotStarted;
}

#pragma mark -- Now Playing Info
-(void)updateNowPlayingInfo {
    
}

@end
