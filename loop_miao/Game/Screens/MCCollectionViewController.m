#import "MCCollectionViewController.h"
@implementation MCCollectionViewController
- (void)viewDidLoad {[super viewDidLoad];self.overrideUserInterfaceStyle=UIUserInterfaceStyleLight;[self renderScreen];}
- (void)renderScreen {
    if(self.busy)return;[self begin:@"collection"];[self backBar:@"Your keepsakes"];
    [self label:[NSString stringWithFormat:@"%lu colorful memories",(unsigned long)self.completed.count] size:27];
    UIStackView *grid=[UIStackView new];grid.axis=UILayoutConstraintAxisVertical;grid.distribution=UIStackViewDistributionFillEqually;grid.spacing=8;[self.stack addArrangedSubview:grid];self.flexView=grid;self.flexHeight=[grid.heightAnchor constraintEqualToConstant:360];self.flexHeight.active=YES;
    for(int r=0;r<3;r++){UIStackView *row=[UIStackView new];row.distribution=UIStackViewDistributionFillEqually;row.spacing=8;[grid addArrangedSubview:row];for(int c=0;c<2;c++){NSInteger i=self.galleryPage*6+r*2+c;if(i>=self.catalog.count){[row addArrangedSubview:[UIView new]];continue;}MCArtworkView *art=[MCArtworkView new];art.backgroundColor=[UIColor colorWithWhite:1 alpha:.75];art.layer.cornerRadius=15;art.clipsToBounds=YES;art.contentMode=UIViewContentModeRedraw;
    if([self.completed containsObject:self.catalog[i][@"id"]])art.level=[MCLevel levelWithDictionary:self.catalog[i]];
    else{UILabel *lock=[UILabel new];lock.text=[NSString stringWithFormat:@"☆  %ld",(long)i+1];lock.textAlignment=NSTextAlignmentCenter;lock.textColor=Ink();lock.frame=CGRectMake(0,0,130,60);[art addSubview:lock];} [row addArrangedSubview:art];}}
    [self label:[NSString stringWithFormat:@"Page %ld / 34  •  Finish puzzles to reveal artwork",(long)self.galleryPage+1] size:12];
    UIStackView *nav=[self row];UIButton *prev=[self button:@"‹ Previous" action:@selector(prevGallery)];prev.enabled=self.galleryPage>0;[nav addArrangedSubview:prev];UIButton *next=[self button:@"Next ›" action:@selector(nextGallery)];next.enabled=self.galleryPage<33;[nav addArrangedSubview:next];
}

- (void)prevGallery {self.galleryPage=MAX(0,self.galleryPage-1);[self renderScreen];}

- (void)nextGallery {self.galleryPage=MIN(33,self.galleryPage+1);[self renderScreen];}
@end
