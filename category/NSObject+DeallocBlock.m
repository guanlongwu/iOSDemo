//
//  NSObject+DeallocBlock.m
//  YYInterview
//
//  Created by wugl on 2022/5/25.
//

#import "NSObject+DeallocBlock.h"
#import <objc/runtime.h>

@interface AssociatedObject : NSObject

- (instancetype)initWithTarget:(NSObject *)target;
- (void)addActionBlock:(DeallocBlock)block;

@end


@interface AssociatedObject ()

// 这里不用weak是由于在target释放的时候，
// 先释放关联对象，然后有weak引用会清除weak表数据，回调的地方拿到的就是nil了，使用unsafe_unretained
@property (nonatomic, unsafe_unretained) NSObject *target;
@property (nonatomic, strong) NSMutableArray<DeallocBlock> *deallocBlocks;

@end


@implementation AssociatedObject

- (instancetype)initWithTarget:(NSObject *)target
{
    self = [super init];
    if (self) {
        _deallocBlocks = [NSMutableArray arrayWithCapacity:0];
        _target = target;
    }
    return self;
}

- (void)addActionBlock:(DeallocBlock)block
{
    [self.deallocBlocks addObject:[block copy]];
}

- (void)dealloc
{
    [_deallocBlocks enumerateObjectsUsingBlock:^(DeallocBlock  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj ? obj(_target) : nil;
    }];
}

@end

// 这里支持设置多个回调，内部存储在关联对象的数组中，dealloc的时候遍历去执行回调
static char kAssociatedObjectKey;

@implementation NSObject (DeallocBlock)

- (void)addDeallocBlock:(DeallocBlock)block
{
    if (block) {
        // 这里尝试过设置一个HCBlock就生成一个HCAssociatedObject对象，
        // 然后将其追加到对象已有的NSMutableArray<HCAssociatedObject *>数组中，
        // 后面调试发现，在kvo remove observer的时候会crash；采用下面这种方式则没有该问题

        AssociatedObject *associatedObject = objc_getAssociatedObject(self, &kAssociatedObjectKey);
        if (!associatedObject) {
            associatedObject = [[AssociatedObject alloc] initWithTarget:self];
            objc_setAssociatedObject(self, &kAssociatedObjectKey, associatedObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

            // 这里用下面这句，在测试移除kvo的时候会异常。TODO：什么原因
            // objc_setAssociatedObject(self, &kHCAssociatedObjectKey, associatedObject, OBJC_ASSOCIATION_RETAIN);
        }
        [associatedObject addActionBlock:block];
    }
}

@end


