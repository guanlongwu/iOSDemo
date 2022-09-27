//
//  GLBacktraceHandler.h
//  YYTool
//
//  Created by wugl on 2022/8/31.
//

#import <Foundation/Foundation.h>
#include <mach/mach.h>

/** Suspend the runtime environment.
 */
void glmc_suspendEnvironment(thread_act_array_t *suspendedThreads, mach_msg_type_number_t *numSuspendedThreads);

/** Resume the runtime environment.
 */
void glmc_resumeEnvironment(thread_act_array_t threads, mach_msg_type_number_t numThreads);

NS_ASSUME_NONNULL_BEGIN

@interface GLBacktraceHandler : NSObject

@end

NS_ASSUME_NONNULL_END
