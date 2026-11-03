#import "MCHomeShowcaseView.h"
#import "MCArtworkView.h"
@implementation MCHomeShowcaseView {
    MCArtworkView *_art;
    UILabel *_badge,*_title,*_caption;
    UIProgressView *_progress;
}
- (instancetype)initWithLevel:(MCLevel *)level title:(NSString *)title completed:(NSInteger)completed {
    if((self=[super initWithFrame:CGRectZero])){
        self.backgroundColor=[UIColor colorWithRed:.81 green:.92 blue:.89 alpha:1];self.layer.cornerRadius=26;self.clipsToBounds=YES;
        _badge=[UILabel new];_badge.text=@"YOUR NEXT KEEPSAKE";_badge.font=[UIFont systemFontOfSize:11 weight:UIFontWeightHeavy];
        _title=[UILabel new];_title.text=title;_title.font=[UIFont systemFontOfSize:21 weight:UIFontWeightHeavy];
        _caption=[UILabel new];_caption.text=[NSString stringWithFormat:@"%ld / 200 colorful memories",(long)completed];_caption.font=[UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
        for(UILabel *label in @[_badge,_title,_caption]){label.textAlignment=NSTextAlignmentCenter;label.textColor=[UIColor colorWithRed:.10 green:.25 blue:.26 alpha:1];[self addSubview:label];}
        _art=[MCArtworkView new];_art.level=level;_art.backgroundColor=UIColor.clearColor;_art.opaque=NO;_art.contentMode=UIViewContentModeRedraw;[self addSubview:_art];
        _progress=[UIProgressView new];_progress.progress=completed/200.0;_progress.progressTintColor=[UIColor colorWithRed:.07 green:.57 blue:.47 alpha:1];[self addSubview:_progress];
    }return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];CGFloat w=self.bounds.size.width,h=self.bounds.size.height;
    _badge.frame=CGRectMake(12,12,w-24,15);_title.frame=CGRectMake(12,30,w-24,27);
    _caption.frame=CGRectMake(12,h-37,w-24,18);_progress.frame=CGRectMake(28,h-13,w-56,3);
    _art.frame=CGRectMake(10,60,w-20,MAX(20,h-104));
}
@end
