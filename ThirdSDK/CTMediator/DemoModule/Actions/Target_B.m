//
//  Target_B.m
//  YYTool
//
//  Created by wugl on 2022/6/17.
//

#import "Target_B.h"

@implementation Target_B

- (void)B_presentImage:(UIImage *)image
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"" message:@"这是一张B图片" preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
    }]];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
}

- (void)B_showAlertWithMessage:(NSString *)message cancelAction:(void(^)(NSDictionary *info))cancelAction confirmAction:(void(^)(NSDictionary *info))confirmAction
{
    NSDictionary *map = @{@"msg":message?:@"", @"name":@"wyl", @"height":@163};
    if (cancelAction) {
        cancelAction(map);
    }
    if (confirmAction) {
        confirmAction(map);
    }
}


@end
