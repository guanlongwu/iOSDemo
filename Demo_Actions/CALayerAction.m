//
//  CALayerAction.m
//  YYTool
//
//  Created by wugl on 2022/7/14.
//

#import "CALayerAction.h"


@interface CALayerAction ()
@property (nonatomic, strong) GLView *myView;

@end

@implementation CALayerAction

- (void)doWork
{
    [self _runCADisplayLink];
}


#pragma mark - CALayer

- (void)_runCADisplayLink
{
    CADisplayLink *link = [CADisplayLink displayLinkWithTarget:self selector:@selector(_LayerAnimation)];
    [link addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)_LayerAnimation
{
    static CGFloat x, y = 0.0;
    static CGFloat w, h = 10;
    
    if (x > 300) {
        x = 0;
        y = 0;
    }
    if (w > 600) {
        w = 10;
        h = 10;
    }
    
    self.myView.frame = CGRectMake(x, y, w, h);
    
    x += 0.2;
    y += 0.2;
    w += 1;
    h += 1;
}

- (void)_testLayer
{
    static int count = 0;
    if (self.myView.superview == nil) {
        self.myView = [[GLView alloc] initWithFrame:CGRectMake(0, 0, 300, 600)];
        self.myView.backgroundColor = [UIColor redColor];
        [self.vc.view addSubview:self.myView];
    }
    
    
    if (count % 3 == 0) {
        NSLog(@"--- setNeedsDisplay ---");
//        self.myView.backgroundColor = [UIColor yellowColor];
        self.myView.frame = CGRectMake(50, 50, 50, 50);
        [self.myView setNeedsDisplay];
    }
    else {
        
        self.myView.backgroundColor = count % 2 ? [UIColor blueColor] : [UIColor greenColor];
        self.myView.frame = count % 2 ? CGRectMake(100, 200, 300, 600) : CGRectMake(0, 400, 300, 400);
    }
    count ++;
}

@end
