#import <UIKit/UIKit.h>
#import "MCDepthButton.h"
#import "MCCannonView.h"
#import "MCMapView.h"
UIColor *MCShade(UIColor *color, CGFloat amount);
void MCDrawTile(CGRect rect, UIColor *color);
void MCFillRounded(CGRect rect, CGFloat radius, UIColor *color);
void MCFillShaded(CGRect rect, CGFloat radius, UIColor *color);
void MCDrawCannon(CGRect rect, UIColor *color, CGFloat progress);
void MCDrawMagazine(CGRect rect, UIColor *color);
