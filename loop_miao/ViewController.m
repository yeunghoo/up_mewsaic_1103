//
//  ViewController.m
//  loop_miao
//
//  Created by 刘冈 on 2026/9/22.
//

#import "ViewController.h"
#import "Game/MCGameViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    MCGameViewController *game = [[MCGameViewController alloc] init];
    [self addChildViewController:game];
    game.view.frame = self.view.bounds;
    game.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:game.view];
    [game didMoveToParentViewController:self];
}


@end
