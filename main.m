//
//  main.m
//  YYTool
//
//  Created by wugl on 2022/5/30.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

int test(int a, int b) {
    return a + b;
}

float run(float a, int b) {
    return a + b;
}

int sum(int a, int b, int c, int d, int e, int f, int g, int h, int i, int j) {
    int lg = test(a, b);
    return a + b + c + d + e + f + g + h + lg;
}

int main(int argc, char * argv[]) {
    
//    int c = test(1, 2);
//
//    float d = run(1.5, 2);
    
//    int e = sum(1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
//    return 0;
    
    NSString * appDelegateClassName;
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
        appDelegateClassName = NSStringFromClass([AppDelegate class]);
    }
    return UIApplicationMain(argc, argv, nil, appDelegateClassName);
}
