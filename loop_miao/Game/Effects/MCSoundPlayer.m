#import "MCSoundPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
@interface MCSoundPlayer ()
@property(atomic) BOOL interrupted;
@property(atomic) BOOL active;
@end
@implementation MCSoundPlayer {
    dispatch_queue_t _audioQueue;
    NSMutableDictionary<NSString *,NSArray<AVAudioPlayer *> *> *_voices;
    NSMutableDictionary<NSString *,NSNumber *> *_lastPlayed;
}
+ (instancetype)shared {static MCSoundPlayer *p;static dispatch_once_t once;dispatch_once(&once,^{p=[MCSoundPlayer new];});return p;}
- (instancetype)init {
    if((self=[super init])) {
        _audioQueue=dispatch_queue_create("com.mewsaic.sound",DISPATCH_QUEUE_SERIAL);
        _voices=[NSMutableDictionary new];_lastPlayed=[NSMutableDictionary new];self.active=UIApplication.sharedApplication.applicationState==UIApplicationStateActive;
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(resignActive) name:UIApplicationWillResignActiveNotification object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(becomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(interruption:) name:AVAudioSessionInterruptionNotification object:nil];
        // Decode and prepare voices off the render thread; requests share this serial queue.
        dispatch_async(_audioQueue,^{
            [AVAudioSession.sharedInstance setCategory:AVAudioSessionCategoryAmbient error:nil];
            for(NSString *effect in @[@"load",@"shot",@"hit",@"win"]){
                NSURL *url=[NSBundle.mainBundle URLForResource:effect withExtension:@"wav"];if(!url)continue;NSMutableArray *pool=[NSMutableArray new];
                for(int i=0;i<4;i++){AVAudioPlayer *p=[[AVAudioPlayer alloc]initWithContentsOfURL:url error:nil];if(p){[p prepareToPlay];[pool addObject:p];}}
                self->_voices[effect]=pool;
            }
        });
    }return self;
}
- (void)resignActive {self.active=NO;[self stop];}
- (void)becomeActive {self.active=YES;}
- (void)interruption:(NSNotification *)note {
    self.interrupted=[note.userInfo[AVAudioSessionInterruptionTypeKey] integerValue]==AVAudioSessionInterruptionTypeBegan;
    if(self.interrupted)[self stop];
}
- (void)play:(NSString *)effect {
    if(self.interrupted||!self.active||![NSUserDefaults.standardUserDefaults boolForKey:@"atelier.sound"])return;
    NSTimeInterval requested=NSProcessInfo.processInfo.systemUptime;
    dispatch_async(_audioQueue,^{
        NSTimeInterval now=NSProcessInfo.processInfo.systemUptime;
        // Drop stale sounds rather than playing a backlog after a slow audio-session start.
        if(!self.active||self.interrupted||now-requested>.15||now-[self->_lastPlayed[effect] doubleValue]<.055)return;
        for(AVAudioPlayer *p in self->_voices[effect])if(!p.playing){p.currentTime=0;[p play];self->_lastPlayed[effect]=@(now);break;}
    });
}
- (void)stop {dispatch_async(_audioQueue,^{for(NSArray *pool in self->_voices.allValues)for(AVAudioPlayer *p in pool){[p pause];p.currentTime=0;}[self->_lastPlayed removeAllObjects];});}
@end
