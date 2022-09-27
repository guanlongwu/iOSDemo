//
//  GLView.m
//  YYInterview
//
//  Created by wugl on 2022/4/27.
//

#import "GLView.h"
#import "NSObject+SafeKVO.h"


NSString * const kNotifyName = @"kNotifyName";

@interface GLView ()
@property (nonatomic, strong) UIButton *btn;
@end

@implementation GLView

- (void)dealloc
{
    NSLog(@"wugl - GLView dealloc");
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self setupUI];
//        [self addObserver];
        [self addNotification];
    }
    return self;
}

- (void)setupUI
{
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width / 3, self.frame.size.height / 3)];
    btn.backgroundColor = [UIColor grayColor];
    [btn addTarget:self action:@selector(clickBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:btn];
    self.btn = btn;
}

- (void)clickBtn:(id)sender
{
    NSLog(@"%@", NSStringFromSelector(_cmd));
}


- (void)addObserver
{
    [self.obj addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:nil];
    
//    [self.obj safe_addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSLog(@"收到kvo通知");
}

//- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
//{
//    UIView *view = [super hitTest:point withEvent:event];
//    CGRect btnFrame = self.btn.frame;
//    if (CGRectContainsPoint(btnFrame, point)) {
//        NSLog(@"point in btn");
//        return self.btn;
//    }
//    else {
//        NSLog(@"point out btn");
//    }
//    return view;
//}


- (void)addNotification
{
//    __weak typeof(self)weakS = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:kNotifyName object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * notification) {
        NSLog(@"wugl - GLView内部收到通知");
        self.btn.backgroundColor = [UIColor blueColor];
    }];
}





// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    NSLog(@"drawRect");
    //1. 注：如果没有获取context时，是什么都不做的（背景无变化）
//    [super drawRect:rect];
    return;
    
    
    // 获取上下文
    CGContextRef context =UIGraphicsGetCurrentContext();
    CGSize size = rect.size;
    CGFloat offset = 20;
    
    // 画脑袋
    CGContextSetRGBStrokeColor(context,1,1,1,1.0);
    CGContextSetLineWidth(context, 1.0);
    CGContextAddArc(context, size.width / 2, offset + 30, 30, 0, 2*M_PI, 0);
    CGContextDrawPath(context, kCGPathStroke);
    
    // 画眼睛和嘴巴
    CGContextMoveToPoint(context, size.width / 2 - 23, 40);
    CGContextAddArcToPoint(context, size.width / 2 - 15, 26, size.width / 2 - 7, 40, 10);
    CGContextStrokePath(context);
    
    CGContextMoveToPoint(context, size.width / 2 + 7, 40);
    CGContextAddArcToPoint(context, size.width / 2 + 15, 26, size.width / 2 + 23, 40, 10);
    CGContextStrokePath(context);//绘画路径
    
    CGContextMoveToPoint(context, size.width / 2 - 8, 65);
    CGContextAddArcToPoint(context, size.width / 2, 80, size.width / 2 + 8, 65, 10);
    CGContextStrokePath(context);//绘画路径
    
    // 画鼻子
    CGPoint nosePoints[3];
    nosePoints[0] = CGPointMake(size.width / 2, 48);
    nosePoints[1] = CGPointMake(size.width / 2 - 3, 58);
    nosePoints[2] = CGPointMake(size.width / 2 + 3, 58);
    CGContextAddLines(context, nosePoints, 3);
    CGContextClosePath(context);
    CGContextDrawPath(context, kCGPathFillStroke);
    
    // 画脖子
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextStrokeRect(context, CGRectMake(size.width / 2 - 5, 80, 10, 10));
    CGContextFillRect(context,CGRectMake(size.width / 2 - 5, 80, 10, 10));
    
//    // 画衣裳
//    CGPoint clothesPoints[4];
//    clothesPoints[0] = CGPointMake(size.width / 2 - 30, 90);
//    clothesPoints[1] = CGPointMake(size.width / 2 + 30, 90);
//    clothesPoints[2] = CGPointMake(size.width / 2 + 100, 200);
//    clothesPoints[3] = CGPointMake(size.width / 2 - 100, 200);
//    CGContextAddLines(context, clothesPoints, 4);
//    CGContextClosePath(context);
//    CGContextDrawPath(context, kCGPathFillStroke);
    
    // 衣裳颜色渐变
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, size.width / 2 - 30, 90);
    CGPathAddLineToPoint(path, NULL, size.width / 2 + 30, 90);
    CGPathAddLineToPoint(path, NULL, size.width / 2 + 100, 200);
    CGPathAddLineToPoint(path, NULL, size.width / 2 - 100, 200);
    CGPathCloseSubpath(path);
    [self drawLinearGradient:context path:path startColor:[UIColor cyanColor].CGColor endColor:[UIColor yellowColor].CGColor];
    CGPathRelease(path);
    
    // 画胳膊
    CGContextSetFillColorWithColor(context, [UIColor colorWithRed:0 green:1 blue:1 alpha:1].CGColor);
    CGContextMoveToPoint(context, size.width / 2 - 28, 90);
    CGContextAddArc(context, size.width / 2 - 28, 90, 80,  - M_PI, -1.05 * M_PI, 1);
    CGContextClosePath(context);
    CGContextDrawPath(context, kCGPathFill);
    CGContextMoveToPoint(context, size.width / 2 + 28, 90);
    CGContextAddArc(context, size.width / 2 + 28, 90, 80,  0, 0.05 * M_PI, 0);
    CGContextClosePath(context);
    CGContextDrawPath(context, kCGPathFill);
    
    // 画左手
    CGPoint aPoints[2];
    aPoints[0] =CGPointMake(size.width / 2 - 30 - 81, 90);
    aPoints[1] =CGPointMake(size.width / 2 - 30 - 86, 90);
    CGContextAddLines(context, aPoints, 2);
    aPoints[0] =CGPointMake(size.width / 2 - 30 - 80, 93);
    aPoints[1] =CGPointMake(size.width / 2 - 30 - 85, 93);
    CGContextAddLines(context, aPoints, 2);
    CGContextDrawPath(context, kCGPathStroke);
    // 画右手
    aPoints[0] =CGPointMake(size.width / 2 + 30 + 81, 90);
    aPoints[1] =CGPointMake(size.width / 2 + 30 + 86, 90);
    CGContextAddLines(context, aPoints, 2);
    aPoints[0] =CGPointMake(size.width / 2 + 30 + 80, 93);
    aPoints[1] =CGPointMake(size.width / 2 + 30 + 85, 93);
    CGContextAddLines(context, aPoints, 2);
    CGContextDrawPath(context, kCGPathStroke);
    
//    // 画虚线
//    aPoints[0] =CGPointMake(size.width / 2 + 30 + 81, 90);
//    aPoints[1] =CGPointMake(size.width / 2 + 30 + 86, 90);
//    CGContextAddLines(context, aPoints, 2);
//    aPoints[0] =CGPointMake(size.width / 2 + 30 + 80, 93);
//    aPoints[1] =CGPointMake(size.width / 2 + 30 + 85, 93);
//    CGContextAddLines(context, aPoints, 2);
//    CGFloat arr[] = {1, 1};
//    CGContextSetLineDash(context, 0, arr, 2);
//    CGContextDrawPath(context, kCGPathStroke);
    
    // 画双脚
    CGContextSetFillColorWithColor(context, [UIColor blueColor].CGColor);
    CGContextAddEllipseInRect(context, CGRectMake(size.width / 2 - 30, 210, 20, 15));
    CGContextDrawPath(context, kCGPathFillStroke);
    CGContextSetFillColorWithColor(context, [UIColor yellowColor].CGColor);
    CGContextAddEllipseInRect(context, CGRectMake(size.width / 2 + 10, 210, 20, 15));
    CGContextDrawPath(context, kCGPathFillStroke);
    
    // 绘制图片
    UIImage *image = [UIImage imageNamed:@"loveu"];
    [image drawInRect:CGRectMake(60, 270, 100, 120)];
    //[image drawAtPoint:CGPointMake(100, 340)];
    //CGContextDrawImage(context, CGRectMake(100, 340, 20, 20), image.CGImage);
    
    // 绘制文字
    UIFont *font = [UIFont boldSystemFontOfSize:20.0];
    NSDictionary *attriDict = @{NSFontAttributeName:font, NSForegroundColorAttributeName:[UIColor redColor]};
    [@"绘制文字" drawInRect:CGRectMake(180, 270, 150, 30) withAttributes:attriDict];

}


- (void)drawLinearGradient:(CGContextRef)context
                      path:(CGPathRef)path
                startColor:(CGColorRef)startColor
                  endColor:(CGColorRef)endColor {
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat locations[] = { 0.0, 1.0 };
    NSArray *colors = @[(__bridge id) startColor, (__bridge id) endColor];
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef) colors, locations);
    CGRect pathRect = CGPathGetBoundingBox(path);
    //具体方向可根据需求修改
    CGPoint startPoint = CGPointMake(CGRectGetMidX(pathRect), CGRectGetMinY(pathRect));
    CGPoint endPoint = CGPointMake(CGRectGetMidX(pathRect), CGRectGetMaxY(pathRect));
    CGContextSaveGState(context);
    CGContextAddPath(context, path);
    CGContextClip(context);
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
    CGContextRestoreGState(context);
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
}




@end
