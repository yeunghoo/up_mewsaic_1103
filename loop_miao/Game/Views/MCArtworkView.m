#import "MCArtworkView.h"
#import "MCPalette.h"
#import "MCVisuals.h"
@implementation MCArtworkView {
    NSMutableDictionary<NSString *,UIImage *> *_tileImages;
    CGFloat _cachedCell;
}
- (void)drawRect:(CGRect)rect {
    MCLevel *l=self.level; if(!l)return;
    CGFloat cell=MIN((self.bounds.size.width-24)/l.cols,(self.bounds.size.height-24)/l.rows);
    if(cell<=0)return;
    if(!_tileImages||fabs(_cachedCell-cell)>.01){_tileImages=[NSMutableDictionary new];_cachedCell=cell;}
    CGFloat ox=(self.bounds.size.width-cell*l.cols)/2, oy=(self.bounds.size.height-cell*l.rows)/2;
    // Clip the iteration itself, not just the drawing, to the damaged tile region.
    NSInteger firstRow=MAX(0,(NSInteger)floor((CGRectGetMinY(rect)-oy)/cell)),lastRow=MIN(l.rows-1,(NSInteger)floor((CGRectGetMaxY(rect)-oy)/cell));
    NSInteger firstCol=MAX(0,(NSInteger)floor((CGRectGetMinX(rect)-ox)/cell)),lastCol=MIN(l.cols-1,(NSInteger)floor((CGRectGetMaxX(rect)-ox)/cell));
    for(NSInteger r=firstRow;r<=lastRow;r++) for(NSInteger c=firstCol;c<=lastCol;c++) {
        NSString *key=self.displayedColors?self.displayedColors[@(r*l.cols+c)]:self.board?[self.board colorKeyAtIndex:r*l.cols+c]:[l.pattern[r] substringWithRange:NSMakeRange(c,1)];
        if(!key || [key isEqualToString:@"."])continue;
        CGRect tile=CGRectMake(ox+c*cell,oy+r*cell,cell,cell);
        if(!CGRectIntersectsRect(tile,rect))continue;
        UIImage *image=_tileImages[key];
        if(!image){
            UIGraphicsImageRenderer *renderer=[[UIGraphicsImageRenderer alloc]initWithSize:CGSizeMake(cell,cell)];
            image=[renderer imageWithActions:^(UIGraphicsImageRendererContext *context){MCDrawTile(CGRectMake(0,0,cell-.7,cell-.7),[MCPalette colorForKey:key]);}];
            _tileImages[key]=image;
        }
        [image drawInRect:tile];
    }
}
@end
