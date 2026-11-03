#import "MCVisuals.h"
UIColor *MCShade(UIColor *c, CGFloat amount) {
    CGFloat r=0,g=0,b=0,a=1;[c getRed:&r green:&g blue:&b alpha:&a];
    if(amount>0)return [UIColor colorWithRed:r+(1-r)*amount green:g+(1-g)*amount blue:b+(1-b)*amount alpha:a];
    return [UIColor colorWithRed:r*(1+amount) green:g*(1+amount) blue:b*(1+amount) alpha:a];
}
void MCFillRounded(CGRect r, CGFloat radius, UIColor *color){[color setFill];[[UIBezierPath bezierPathWithRoundedRect:r cornerRadius:radius] fill];}
void MCFillShaded(CGRect r, CGFloat radius, UIColor *color){
    CGContextRef ctx=UIGraphicsGetCurrentContext();CGContextSaveGState(ctx);
    [[UIBezierPath bezierPathWithRoundedRect:r cornerRadius:radius] addClip];
    NSArray *colors=@[(id)MCShade(color,.10).CGColor,(id)color.CGColor,(id)MCShade(color,-.05).CGColor];
    CGColorSpaceRef space=CGColorSpaceCreateDeviceRGB();CGGradientRef grad=CGGradientCreateWithColors(space,(__bridge CFArrayRef)colors,NULL);
    CGContextDrawLinearGradient(ctx,grad,CGPointMake(0,CGRectGetMinY(r)),CGPointMake(0,CGRectGetMaxY(r)),0);CGGradientRelease(grad);CGColorSpaceRelease(space);CGContextRestoreGState(ctx);
}
void MCDrawTile(CGRect r,UIColor *color){
    CGFloat depth=MAX(1.2,r.size.height*.17),radius=MAX(1.2,r.size.width*.18);
    MCFillRounded(CGRectOffset(r,0,depth*.35),radius,[UIColor colorWithWhite:0 alpha:.13]);
    MCFillRounded(r,radius,MCShade(color,-.30));CGRect face=r;face.size.height-=depth;MCFillShaded(face,radius,color);
    CGRect glint=CGRectInset(face,MAX(1,r.size.width*.15),0);glint.origin.y+=MAX(.6,r.size.height*.09);glint.size.height=MAX(.6,r.size.height*.07);
    MCFillRounded(glint,1,[UIColor colorWithWhite:1 alpha:.20]);
}
void MCDrawCannon(CGRect r,UIColor *color,CGFloat progress){
    CGFloat w=r.size.width,h=r.size.height;
    UIColor *steel=[UIColor colorWithRed:.22 green:.34 blue:.35 alpha:1];
    MCFillRounded(CGRectMake(3,h*.73,w-6,h*.24),12,MCShade(steel,-.45));
    MCFillShaded(CGRectMake(3,h*.65,w-6,h*.23),12,steel);
    CGRect ring=CGRectMake(w*.15,h*.32,w*.70,h*.43);
    MCFillRounded(CGRectOffset(ring,0,4),w*.22,MCShade(color,-.45));MCFillShaded(ring,w*.22,color);
    // A broad barrel, bevelled sleeve and deep elliptical bore establish a clear direction.
    CGRect barrel=CGRectMake(w*.32,h*.04,w*.36,h*.48);
    MCFillRounded(CGRectOffset(barrel,2,2),7,MCShade(steel,-.45));MCFillShaded(barrel,7,MCShade(steel,.15));
    MCFillRounded(CGRectMake(w*.33,h*.32,w*.34,h*.08),3,color);
    CGRect muzzle=CGRectMake(w*.27,h*.015,w*.46,h*.17);
    [MCShade(steel,.35) setFill];[[UIBezierPath bezierPathWithOvalInRect:muzzle] fill];
    [MCShade(steel,-.65) setFill];[[UIBezierPath bezierPathWithOvalInRect:CGRectInset(muzzle,3,3)] fill];
    [MCShade(color,.35) setFill];[[UIBezierPath bezierPathWithOvalInRect:CGRectInset(muzzle,6,5)] fill];
    for(int side=0;side<2;side++){
        CGRect screw=CGRectMake(side?w-12:7,h*.71,5,5);[MCShade(steel,.55) setFill];[[UIBezierPath bezierPathWithOvalInRect:screw] fill];
    }
    MCFillRounded(CGRectMake(w*.23,h*.91,w*.54,2),1,MCShade(color,-.35));
    if(progress>0)MCFillRounded(CGRectMake(w*.23,h*.91,w*.54*progress,2),1,MCShade(color,.45));
}
void MCDrawMagazine(CGRect r,UIColor *color){
    CGRect card=CGRectInset(r,3,3);card.size.height-=4;
    MCFillRounded(CGRectOffset(card,0,4),13,MCShade(color,-.33));
    MCFillShaded(card,13,color);
    UIBezierPath *rim=[UIBezierPath bezierPathWithRoundedRect:CGRectInset(card,1,1) cornerRadius:12];
    [[UIColor colorWithWhite:1 alpha:.65]setStroke];rim.lineWidth=1.5;[rim stroke];
    MCFillRounded(CGRectMake(card.origin.x+9,card.origin.y+6,card.size.width-18,3),1.5,[UIColor colorWithWhite:1 alpha:.25]);
}
