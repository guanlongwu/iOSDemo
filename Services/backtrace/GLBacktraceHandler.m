//
//  GLBacktraceHandler.m
//  YYTool
//
//  Created by wugl on 2022/8/31.
//

#import "GLBacktraceHandler.h"
#include <mach/mach.h>

typedef uintptr_t GLThread;
static GLThread g_reservedThreads[10];
static int g_reservedThreadsMaxIndex = sizeof(g_reservedThreads) / sizeof(g_reservedThreads[0]) - 1;
static int g_reservedThreadsCount = 0;

@implementation GLBacktraceHandler


GLThread glthread_self()
{
    thread_t thread_self = mach_thread_self();
    mach_port_deallocate(mach_task_self(), thread_self);
    return (GLThread)thread_self;
}

static inline bool isThreadInList(thread_t thread, GLThread* list, int listCount)
{
    for(int i = 0; i < listCount; i++)
    {
        if(list[i] == (GLThread)thread)
        {
            return true;
        }
    }
    return false;
}


void glmc_suspendEnvironment(__unused thread_act_array_t *suspendedThreads, __unused mach_msg_type_number_t *numSuspendedThreads)
{
    NSLog(@"Suspending environment.");
    kern_return_t kr;
    const task_t thisTask = mach_task_self();
    const thread_t thisThread = (thread_t)glthread_self();
    
    if((kr = task_threads(thisTask, suspendedThreads, numSuspendedThreads)) != KERN_SUCCESS)
    {
        NSLog(@"task_threads: %s", mach_error_string(kr));
        return;
    }
    
    for(mach_msg_type_number_t i = 0; i < *numSuspendedThreads; i++)
    {
        thread_t thread = (*suspendedThreads)[i];
        if(thread != thisThread && !isThreadInList(thread, g_reservedThreads, g_reservedThreadsCount))
        {
            if((kr = thread_suspend(thread)) != KERN_SUCCESS)
            {
                // Record the error and keep going.
                NSLog(@"thread_suspend (%08x): %s", thread, mach_error_string(kr));
            }
        }
    }
    
    NSLog(@"Suspend complete.");
}

void glmc_resumeEnvironment(__unused thread_act_array_t threads, __unused mach_msg_type_number_t numThreads)
{
    NSLog(@"Resuming environment.");
    kern_return_t kr;
    const task_t thisTask = mach_task_self();
    const thread_t thisThread = (thread_t)glthread_self();
    
    if(threads == NULL || numThreads == 0)
    {
        NSLog(@"we should call glmc_suspendEnvironment() first");
        return;
    }
    
    for(mach_msg_type_number_t i = 0; i < numThreads; i++)
    {
        thread_t thread = threads[i];
        if(thread != thisThread && !isThreadInList(thread, g_reservedThreads, g_reservedThreadsCount))
        {
            if((kr = thread_resume(thread)) != KERN_SUCCESS)
            {
                // Record the error and keep going.
                NSLog(@"thread_resume (%08x): %s", thread, mach_error_string(kr));
            }
        }
    }
    
    for(mach_msg_type_number_t i = 0; i < numThreads; i++)
    {
        mach_port_deallocate(thisTask, threads[i]);
    }
    vm_deallocate(thisTask, (vm_address_t)threads, sizeof(thread_t) * numThreads);
    
    NSLog(@"Resume complete.");
}

void glmc_addReservedThread(GLThread thread)
{
    int nextIndex = g_reservedThreadsCount;
    if(nextIndex > g_reservedThreadsMaxIndex)
    {
        NSLog(@"Too many reserved threads (%d). Max is %d", nextIndex, g_reservedThreadsMaxIndex);
        return;
    }
    g_reservedThreads[g_reservedThreadsCount++] = thread;
}


@end
