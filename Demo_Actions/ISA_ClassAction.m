//
//  ISA_ClassAction.m
//  YYTool
//
//  Created by wugl on 2022/7/14.
//

#import "ISA_ClassAction.h"
#import "GLObject.h"
#import <objc/runtime.h>
#import "GLSubObj.h"

@implementation ISA_ClassAction

- (void)doWork
{
    [self _testClass];
    
    [self _testClassAPI];
    
    [self _testISA];
}


#pragma mark - isa class object_getClass

- (void)_testClass
{
//    GLObject *obj = [GLObject new];
    
    // class 方法
    
//    NSLog(@"obj.class : %@", obj.class);    // 实例方法 - (Class) class
//    NSLog(@"class.class : %@", GLObject.class); // 类方法 + (Class) class
    
    /**
     // 类方法，返回自身
     + (Class)class {
         return self;
     }
      
     // 实例方法，查找isa（类）
     - (Class)class {
         return object_getClass(self);
     }
     */
    
    
    // object_getClass 方法
    
//    NSLog(@"obj.object_getClass : %@", object_getClass(obj)); // 传入实例对象，返回class类对象
//    NSLog(@"class.object_getClass : %@", object_getClass(object_getClass(obj))); // 传入class类对象，返回metaClass元类对象
//    NSLog(@"metaClass.object_getClass : %@", object_getClass(object_getClass(object_getClass(obj)))); // 传入metaClass元类对象，返回NSObject根元类
//
//    NSLog(@"obj.objc_getMetaClass : %@", objc_getMetaClass(object_getClassName(obj))); // 传入实例对象，返回class类对象
//    NSLog(@"GLObject.objc_getMetaClass : %@", objc_getMetaClass("GLObject")); // 传入实例对象，返回class类对象
    
    /**
     Class object_getClass(id obj)
     {
         if (obj) return obj->getIsa();
         else return Nil;
     }
     */
    
    
    
    /**
     1、当obj为 ”实例变量“ 时

     object_getClass(obj)与[obj class]输出结果一直，均获得isa指针，即指向类对象的指针。
     */
    
    //obj为实例对象
    id obj = [[GLObject alloc] init];
    GLObject *people = obj;
    
    /*----obj为实例对象----*/
    Class cls = [obj class];
    Class cls2 = object_getClass(obj);
    Class cls3 = [people class];
    Class cls4 = object_getClass(people);
    
    NSLog(@"");
    NSLog(@"----obj为实例对象----");
    NSLog(@"实例对象:class----              %p" , cls);
    NSLog(@"实例对象:object_getClass----    %p" , cls2);
    NSLog(@"实例对象:class----              %p" , cls3);    // 传入对象object， obj.class 返回 类
    NSLog(@"实例对象:object_getClass----    %p" , cls4);    // 传入对象object， object_getClass(obj)返回 类
    
    
    
    
    /**
     2、当obj为 “类对象“ 时

     object_getClass(obj)返回类对象中的isa指针，即指向元类对象的指针；

     [obj class]返回的则是类对象其本身
     */
    
    //obj为实例对象
    obj = [[GLObject alloc] init];
    people = obj;
    //classObj为类对象
    Class classObj = [obj class];
    
    /*----obj为类对象----*/
    Class clsc = [classObj class];
    Class clsc2 = object_getClass(classObj);
    NSLog(@"");
    NSLog(@"----obj为类对象----");
    NSLog(@"对象:class----                 %p" , classObj);
    NSLog(@"类对象:class----               %p" , clsc);    // 传入类class，class.class 返回 类本身
    NSLog(@"类对象:object_getClass----     %p" , clsc2);   // 传入类class ，object_getClass(class) 返回 元类
    
    
    
    
    /**
     3、当obj为Metaclass（元类）对象时

     object_getClass(obj)返回元类对象中的isa指针，因为元类对象的isa指针指向根类，所有返回的是根类对象的地址指针；

     [obj class]返回的则是元类本身
     */
    
    //obj为实例对象
    obj = [[GLObject alloc] init];
    //classObj为类对象
    Class classObj2 = [obj class];
    //metaClassObj为元类对象
    Class metaClassObj = object_getClass(classObj2);
    
    /*----obj为元类对象----*/
    Class clso = [metaClassObj class];
    Class clso2 = object_getClass(metaClassObj);
    NSLog(@"");
    NSLog(@"----obj为元类对象----");
    NSLog(@"类对象:[obj class]--类本身--      %p, %@" , classObj2, classObj2);    // 传入类class，class.class 返回 类本身
    NSLog(@"类对象:object_getClass([obj class])--元类--     %p, %@" , metaClassObj, metaClassObj);   // 传入类class ，object_getClass(class) 返回 元类
    NSLog(@"元类对象:[元类 class]--元类本身-- %p, %@" , clso, clso);    // 传入元类 metaClass，metaClass.class 返回 元类 本身
    NSLog(@"元类对象:object_getClass([元类 class])--根元类--    %p, %@" , clso2, clso2);   // 传入元类 metaClass，object_getClass(metaClass) 返回 根元类 NSObject
    
    NSLog(@"元类对象:[根元类 class] --根元类本身--    %p, %@" , clso2.class, clso2.class);   // 传入元类 metaClass，object_getClass(metaClass) 返回 NSObject
    NSLog(@"根元类对象:object_getClass --根元类的元类--    %p, %@" , object_getClass(clso2.class), object_getClass(clso2.class));   // 根元类的元类 还是自己 NSObject
    NSLog(@"元类对象:object_getClass --根元类的元类--    %p, %@" , NSObject.class, NSObject.class);   // 传入元类 metaClass，object_getClass(metaClass) 返回 根元类 rootClass
    
    
    
    
    
    /**
     4、当obj为Rootclass（根类）对象时

     object_getClass(obj)返回根类对象中的isa指针，
     因为根类对象的isa指针指向Rootclass‘s metaclass(根元类)，即返回的是根元类的地址指针；

     [obj class]返回的则是其本身。
     因为根类的isa指针其实是指向本身的，所有根元类其实就是根类，所有输出的结果是一样的。
     */
    
    //obj为实例对象
    obj = [[GLObject alloc] init];
    //classObj为类对象
    classObj = [obj class];
    //metaClassObj为元类对象
    metaClassObj = object_getClass(classObj);
    //rootClassObj为根类对象
    Class rootClassObj = object_getClass(metaClassObj);
    
    /*----obj为根类对象----*/
    Class clsr = [rootClassObj class];
    Class clsr2 = object_getClass(rootClassObj);
    NSLog(@"");
    NSLog(@"----obj为根类对象----");
    NSLog(@"类对象:[obj class]--类本身--      %p, %@" , classObj2, classObj2);    // 传入类class，class.class 返回 类本身
    NSLog(@"类对象:object_getClass([obj class])--元类--     %p, %@" , metaClassObj, metaClassObj);   // 传入类class ，object_getClass(class) 返回 元类
    NSLog(@"根类对象:object_getClass(metaClassObj)--根类--     %p, %@" , rootClassObj, rootClassObj);   // 传入类class ，object_getClass(class) 返回 元类
    NSLog(@"根类对象:class--根类本身--              %p, %@" , clsr, clsr);
    NSLog(@"根类对象:object_getClass(rootClassObj)--根类自己--     %p, %@" , clsr2, clsr2);
    
    
    
    
    void (^testBlock)() = [^{} copy];
    Class blockCls0 = [testBlock class];
    Class blockCls = object_getClass(testBlock);
    Class blockMetaCls = objc_getMetaClass(object_getClassName(testBlock));
    Class blockClsCls = object_getClass(blockCls);
    
    NSLog(@"");
    NSLog(@"----testBlock为NSBlock对象----");
    NSLog(@"----block---        %p, %@", testBlock, testBlock);
    NSLog(@"类对象:[block class]--类本身--      %p, %@" , blockCls0, blockCls0);    // 传入类class，class.class 返回 类本身
    NSLog(@"类对象:block.class--类本身--      %p, %@" , blockCls, blockCls);    // 传入类class，class.class 返回 类本身
    NSLog(@"元类对象:block.metaclass--类本身--      %p, %@" , blockMetaCls, blockMetaCls);    // 传入类class，class.class 返回 类本身
    NSLog(@"元类对象:block.class.class--类本身--      %p, %@" , blockClsCls, blockClsCls);    // 传入类class，class.class 返回 类本身
    NSLog(@"元类对象:block.class.class.class--类本身--      %p, %@" , object_getClass(object_getClass(blockCls)), object_getClass(object_getClass(blockCls)));    // 传入类class，class.class 返回 类本身

    

    
    /**
     总结：
     
     1、object_getClass(obj)
     返回的是obj的isa指针

     2、[obj class]
     （1）obj为实例对象
     调用的是实例方法：- (Class)class，返回的obj对象中的isa指针；

     （2）obj为类对象（包括元类和根类以及根元类）
     调用的是类方法：+ (Class)class，返回的结果为调用者本身。
     */
    
    NSLog(@"");
    
}


#pragma mark - class / object_getClass / class_isMetaClass

- (void)_testClassAPI
{
    GLObject *obj = [GLObject new];
    
    Class cls = obj.class;
    Class baseCls = object_getClass(obj);
    BOOL isMetaCls = class_isMetaClass(cls);
    NSLog(@"class : %@", NSStringFromClass(cls));
    NSLog(@"baseClass : %@", NSStringFromClass(baseCls));
    NSLog(@"isMetaClass : %d", isMetaCls);
    
    isMetaCls = class_isMetaClass(baseCls);
    NSLog(@"isMetaClass : %d", isMetaCls);
    
    NSLog(@"====");
    
    cls = GLObject.class;
    baseCls = object_getClass(object_getClass(cls));
    isMetaCls = class_isMetaClass(baseCls);
    NSLog(@"class : %@", NSStringFromClass(cls));
    NSLog(@"baseClass : %@", NSStringFromClass(baseCls));
    NSLog(@"isMetaClass : %d", isMetaCls);
}


#pragma mark - isa

// isa 和 superclass 的流向图 验证
- (void)_testISA
{
//    id obj = [GLObject new];
    id obj = [GLSubObj new];
    
    NSLog(@"[obj class] = %@", [obj class]);
    NSLog(@"object_getClass(obj) = %@", object_getClass(obj));
    NSLog(@"object_getClass(object_getClass(obj)) = %@", object_getClass(object_getClass(obj)));
    NSLog(@"object_getClass(object_getClass(object_getClass(obj))) = %@", object_getClass(object_getClass(object_getClass(obj))));
    
    NSLog(@"[obj class] = %p", [obj class]);
    NSLog(@"object_getClass(obj) = %p, isMetaClass = %d", object_getClass(obj), class_isMetaClass(object_getClass(obj)));
    NSLog(@"object_getClass(object_getClass(obj)) = %p, isMetaClass = %d", object_getClass(object_getClass(obj)), class_isMetaClass(object_getClass(object_getClass(obj))));
    NSLog(@"object_getClass(object_getClass(object_getClass(obj))) = %p, isMetaClass = %d", object_getClass(object_getClass(object_getClass(obj))), class_isMetaClass(object_getClass(object_getClass(object_getClass(obj)))));
    
    
    NSLog(@"======");
    
    NSLog(@"[obj superclass] = %@", [obj superclass]);
    NSLog(@"[[obj superclass] superclass] = %@", [[obj superclass] superclass]);
    NSLog(@"[[[obj superclass] superclass] superclass] = %@", [[[obj superclass] superclass] superclass]);
    
    
    NSLog(@"======");

    NSLog(@"[object_getClass(obj) superclass] = %@, %p", [object_getClass(obj) superclass], [object_getClass(obj) superclass]);
    NSLog(@"[[object_getClass(obj) superclass] superclass] = %@, %p", [[object_getClass(obj) superclass] superclass], [[object_getClass(obj) superclass] superclass]);
    
    
    NSLog(@"======");
    
    NSLog(@"[object_getClass(object_getClass(obj)) superclass] = %@, %p", [object_getClass(object_getClass(obj)) superclass], [object_getClass(object_getClass(obj)) superclass]);
    NSLog(@"[[object_getClass(object_getClass(obj)) superclass] superclass] = %@, %p", [[object_getClass(object_getClass(obj)) superclass] superclass], [[object_getClass(object_getClass(obj)) superclass] superclass]);
    NSLog(@"[[object_getClass(object_getClass(object_getClass(obj))) superclass] superclass] = %@, %p", [[object_getClass(object_getClass(object_getClass(obj))) superclass] superclass], [[object_getClass(object_getClass(object_getClass(obj))) superclass] superclass]);
    
}




@end
