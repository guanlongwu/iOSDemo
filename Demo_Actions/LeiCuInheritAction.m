//
//  LeiCuInheritAction.m
//  YYTool
//
//  Created by wugl on 2022/7/14.
//

#import "LeiCuInheritAction.h"
#import "GLString.h"
#import "GLMutableArray.h"

@interface LeiCuInheritAction ()
@property (nonatomic, strong) GLMutableArray *glArr;

@end

@implementation LeiCuInheritAction

- (void)doWork
{
    [self _testLeiCu];
}

#pragma mark - 类簇为啥不能被继承

- (void)_testLeiCu
{
//    GLString *str = [GLString stringWithString:@"ABC"];
//    NSLog(@"%@", str);  // crash
    
    // 不要对NSString  NSArray 等类簇继承
    self.glArr = [GLMutableArray arrayWithObjects:@"1", @"2", nil];

    NSLog(@"arr:---%@", self.glArr);
    [self.glArr enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSLog(@" obj : ---%@", obj);
    }];
    
    
    
    
    
    id obj1 = [NSString alloc];
    id obj2 = [NSMutableString alloc];
    
    id obj3 = [obj1 init];
    id obj4 = [obj2 init];
    
    id obj5 = [GLString alloc];
    id obj6 = [obj5 init];
    
    NSLog(@"obj1 = %@", [obj1 class]);
    NSLog(@"obj2 = %@", [obj2 class]);
    NSLog(@"obj3 = %@", [obj3 class]);
    NSLog(@"obj4 = %@", [obj4 class]);
    NSLog(@"obj5 = %@", [obj5 class]);
    NSLog(@"obj6 = %@", [obj6 class]);
    
    
    /**
     NSString和NSMutableString调用alloc的时候会生成一个对象NSPlaceholderString。
     NSString调用init的时候会生成对象__NSCFConstantString，
     而NSMutableString调用init的时候会生成对象__NSCFString。
     
     GLString调用alloc和init的时候还是GLString对象。
     为什么会是这个样子，其实可以从下面几个情况着手：

     这里，NSPlaceholderString是一个中间对象。
     后面的- init或- initWithXXXXX消息都是发送给这个中间对象，再由它做工厂，
     生成真的对象分别是这里的NSCFConstantString和NSCFString类。
     */
    
    /**
     那么问题来了：
     那么为什么我们自己的类调用alloc时，就不返回NSPlaceholderString这个类对象了呢？
     关键就在于NSString alloc方法的实现。
     NSString的alloc方法实现可以猜测一下：
     
     @class NSPlaceholderString;

     @interface NSString:(NSObject)

     +  (id) alloc;

     @ end

     @implementation NSString

     +(id) alloc
     {
         if ([self isEquals:[NSString class]]) {
             return [NSPlaceholderString alloc];
         }
         else
             return [super alloc];
     }
     @end

     @interface NSPlaceholderString:(NSString)

     @end
     */
    
    /**
     关键就在于alloc的实现，可以发现，
     当只用NSString调用alloc的时候，由于self == [NSString class]，
     所以这时返回的是NSPlaceholderString的类对象；
     
     而使用其他类（比如派生类）调用alloc时，返回的是super的 alloc，
     这里也就是[NSObject alloc]，而NSObject的alloc方法返回的是调用类的类对象，
     所以在我们用我们自己的GLString就是GLString类的类对象了所以没有NSString 的一些方法了。
     */
    
    
}


@end
