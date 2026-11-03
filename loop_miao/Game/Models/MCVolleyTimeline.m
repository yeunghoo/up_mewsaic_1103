#import "MCVolleyTimeline.h"
static const NSTimeInterval MCShotInterval = .13;
static const NSTimeInterval MCFlightDuration = .26;

@implementation MCVolleyShot
@end
@implementation MCVolleyTimeline {
    NSInteger _rows, _cols;
    NSTimeInterval _clock;
    uint8_t *_occupied, *_air, *_exposed;
    NSInteger *_airQueue;
    BOOL _exposureDirty;
    NSMutableArray<NSMutableArray<MCVolleyShot *> *> *_lanes;
    NSMutableArray<NSNumber *> *_nextFire;
    NSMutableArray<MCVolleyShot *> *_active;
    NSMutableArray *_displaySlots;
}
- (instancetype)initWithBoard:(MCBoard *)board {
    if((self=[super init])) {
        _rows=board.level.rows; _cols=board.level.cols;
        NSInteger padded=(_rows+2)*(_cols+2);_occupied=calloc(_rows*_cols,1);_air=calloc(padded,1);_exposed=calloc(_rows*_cols,1);_airQueue=malloc(sizeof(NSInteger)*padded);_exposureDirty=YES;
        _colors=[NSMutableDictionary new]; _lanes=[NSMutableArray new];
        _displaySlots=[NSMutableArray new];
        for(id entry in board.slots){if(entry==NSNull.null)[_displaySlots addObject:NSNull.null];else {MCBasket *b=entry;[_displaySlots addObject:[@{@"color":b.colorKey,@"capacity":@(b.capacity),@"filled":@(b.filled)} mutableCopy]];}}
        _active=[NSMutableArray new]; _nextFire=[NSMutableArray new];
        for(NSInteger i=0;i<_rows*_cols;i++){NSString *c=[board colorKeyAtIndex:i];if(c){_colors[@(i)]=c;_occupied[i]=1;}}
        for(NSInteger i=0;i<board.level.slotCount;i++){[_lanes addObject:[NSMutableArray new]];[_nextFire addObject:@0];}
    }
    return self;
}
- (NSArray *)displaySlots {return [_displaySlots copy];}
- (void)enqueueMove:(MCMove *)move {
    _displaySlots[move.slotIndex]=[@{@"color":move.colorKey,@"capacity":@(move.capacity),@"filled":@0} mutableCopy];
    for(MCStep *step in move.steps)if(step.kind==MCStepKindTake)for(NSNumber *index in step.indexes){
        MCVolleyShot *shot=[MCVolleyShot new];shot.index=index.integerValue;shot.slot=step.slotIndex;shot.color=step.colorKey;
        [_lanes[shot.slot] addObject:shot];
    }
}
- (BOOL)isSlotAnimating:(NSInteger)slot {
    if(_lanes[slot].count)return YES;
    for(MCVolleyShot *shot in _active)if(shot.slot==slot)return YES;
    return NO;
}
- (BOOL)running {
    if(_active.count)return YES;
    for(NSArray *lane in _lanes)if(lane.count)return YES;
    return NO;
}
- (NSArray *)flying {return [_active copy];}
- (void)dealloc {free(_occupied);free(_air);free(_exposed);free(_airQueue);}
- (void)updateExposure {
    NSInteger width=_cols+2,height=_rows+2;
    memset(_air,0,width*height);memset(_exposed,0,_rows*_cols);
    NSInteger head=0,tail=0;_airQueue[tail++]=0;_air[0]=1;
    while(head<tail){NSInteger pos=_airQueue[head++],r=pos/width,c=pos%width;
        NSInteger dr[4]={-1,1,0,0},dc[4]={0,0,-1,1};
        for(int d=0;d<4;d++){NSInteger nr=r+dr[d],nc=c+dc[d];if(nr<0||nc<0||nr>=height||nc>=width)continue;
            NSInteger p=nr*width+nc;if(_air[p])continue;
            if(nr>0&&nc>0&&nr<=_rows&&nc<=_cols&&_occupied[(nr-1)*_cols+nc-1])continue;
            _air[p]=1;_airQueue[tail++]=p;
        }
    }
    for(NSInteger idx=0;idx<_rows*_cols;idx++)if(_occupied[idx]){NSInteger p=(idx/_cols+1)*width+idx%_cols+1;_exposed[idx]=_air[p-width]||_air[p+width]||_air[p-1]||_air[p+1];}
    _exposureDirty=NO;
}
- (void)advance:(NSTimeInterval)elapsed {
    _clock+=MAX(0,elapsed);
    NSMutableArray *hits=[NSMutableArray new],*starts=[NSMutableArray new];
    for(MCVolleyShot *shot in [_active copy]){
        shot.progress=MIN(1,(_clock-shot.launchedAt)/MCFlightDuration);
        if(shot.progress>=1){[_colors removeObjectForKey:@(shot.index)];_occupied[shot.index]=0;[hits addObject:shot];[_active removeObject:shot];}
    }
    // No cannon targets a hidden tile or a tile already reserved by another shot.
    if(hits.count)_exposureDirty=YES;
    BOOL canLaunch=NO;for(NSInteger i=0;i<_lanes.count;i++)if(_lanes[i].count&&_clock>=[_nextFire[i] doubleValue]){canLaunch=YES;break;}
    if(canLaunch&&_exposureDirty)[self updateExposure];
    for(NSInteger i=0;i<_lanes.count;i++){
        MCVolleyShot *shot=_lanes[i].firstObject;
        if(!shot||_clock<[_nextFire[i] doubleValue]||!_exposed[shot.index])continue;
        [_lanes[i] removeObjectAtIndex:0];shot.launchedAt=_clock;shot.progress=0;
        [_active addObject:shot];[starts addObject:shot];_nextFire[i]=@(_clock+MCShotInterval);
        NSMutableDictionary *display=_displaySlots[i];if([display isKindOfClass:NSDictionary.class])display[@"filled"]=@([display[@"filled"] integerValue]+1);
    }
    for(NSInteger i=0;i<_displaySlots.count;i++){id slot=_displaySlots[i];if([slot isKindOfClass:NSDictionary.class]&&[slot[@"filled"] integerValue]>=[slot[@"capacity"] integerValue]&&![self isSlotAnimating:i])_displaySlots[i]=NSNull.null;}
    _launched=starts;_impacts=hits;
}
- (NSDictionary *)shotRecord:(MCVolleyShot *)shot {return @{@"index":@(shot.index),@"slot":@(shot.slot),@"color":shot.color,@"time":@(shot.launchedAt)};}
- (NSDictionary *)snapshot {
    NSMutableDictionary *colors=[NSMutableDictionary new];for(NSNumber *key in _colors)colors[key.stringValue]=_colors[key];
    NSMutableArray *lanes=[NSMutableArray new],*active=[NSMutableArray new],*display=[NSMutableArray new];
    for(NSArray *lane in _lanes){NSMutableArray *list=[NSMutableArray new];for(MCVolleyShot *shot in lane)[list addObject:[self shotRecord:shot]];[lanes addObject:list];}
    for(MCVolleyShot *shot in _active)[active addObject:[self shotRecord:shot]];
    for(id slot in _displaySlots)[display addObject:slot==NSNull.null?@{}:[slot copy]];
    return @{@"rows":@(_rows),@"cols":@(_cols),@"colors":colors,@"lanes":lanes,@"active":active,@"nextFire":[_nextFire copy],@"clock":@(_clock),@"display":display};
}
- (MCVolleyShot *)shotFromRecord:(NSDictionary *)record {
    MCVolleyShot *s=[MCVolleyShot new];s.index=[record[@"index"] integerValue];s.slot=[record[@"slot"] integerValue];s.color=record[@"color"];s.launchedAt=[record[@"time"] doubleValue];s.progress=MIN(1,MAX(0,(_clock-s.launchedAt)/MCFlightDuration));return s;
}
- (BOOL)restoreSnapshot:(NSDictionary *)snapshot {
    if(![snapshot isKindOfClass:NSDictionary.class]||[snapshot[@"rows"] integerValue]!=_rows||[snapshot[@"cols"] integerValue]!=_cols||[snapshot[@"lanes"] count]!=_lanes.count||[snapshot[@"display"] count]!=_lanes.count||[snapshot[@"nextFire"] count]!=_lanes.count)return NO;
    NSMutableArray *records=[NSMutableArray arrayWithArray:snapshot[@"active"]?:@[]];for(NSArray *lane in snapshot[@"lanes"])[records addObjectsFromArray:lane];
    for(NSDictionary *record in records){NSInteger index=[record[@"index"] integerValue],slot=[record[@"slot"] integerValue];if(index<0||index>=_rows*_cols||slot<0||slot>=_lanes.count)return NO;}
    _clock=[snapshot[@"clock"] doubleValue];[_colors removeAllObjects];memset(_occupied,0,_rows*_cols);
    for(NSString *key in snapshot[@"colors"]){NSInteger index=key.integerValue;if(index<0||index>=_rows*_cols)return NO;_colors[@(index)]=snapshot[@"colors"][key];_occupied[index]=1;}
    for(NSInteger i=0;i<_lanes.count;i++){
        [_lanes[i] removeAllObjects];for(NSDictionary *record in snapshot[@"lanes"][i])[_lanes[i] addObject:[self shotFromRecord:record]];
        _displaySlots[i]=[snapshot[@"display"][i] count]?[snapshot[@"display"][i] mutableCopy]:NSNull.null;
    }
    [_active removeAllObjects];for(NSDictionary *record in snapshot[@"active"])[_active addObject:[self shotFromRecord:record]];
    _nextFire=[snapshot[@"nextFire"] mutableCopy];_exposureDirty=YES;return YES;
}
@end
