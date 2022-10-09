// Copyright (c) 2013, Facebook, Inc.
// All rights reserved.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//   * Redistributions of source code must retain the above copyright notice,
//     this list of conditions and the following disclaimer.
//   * Redistributions in binary form must reproduce the above copyright notice,
//     this list of conditions and the following disclaimer in the documentation
//     and/or other materials provided with the distribution.
//   * Neither the name Facebook nor the names of its contributors may be used to
//     endorse or promote products derived from this software without specific
//     prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "fishhook.h"

#import <dlfcn.h>
#import <stdlib.h>
#import <string.h>
#import <sys/types.h>

#include <mach/mach.h>
#include <mach/vm_map.h>
#include <mach/vm_region.h>

#import <mach-o/dyld.h>
#import <mach-o/loader.h>
#import <mach-o/nlist.h>

#ifdef __LP64__
typedef struct mach_header_64 mach_header_t;
typedef struct segment_command_64 segment_command_t;
typedef struct section_64 section_t;
typedef struct nlist_64 nlist_t;
#define LC_SEGMENT_ARCH_DEPENDENT LC_SEGMENT_64
#else
typedef struct mach_header mach_header_t;
typedef struct segment_command segment_command_t;
typedef struct section section_t;
typedef struct nlist nlist_t;
#define LC_SEGMENT_ARCH_DEPENDENT LC_SEGMENT
#endif

#ifndef SEG_DATA_CONST
#define SEG_DATA_CONST  "__DATA_CONST"
#endif

#if 0
static int get_protection(void *addr, vm_prot_t *prot, vm_prot_t *max_prot) {
  mach_port_t task = mach_task_self();
  vm_size_t size = 0;
  vm_address_t address = (vm_address_t)addr;
  memory_object_name_t object;
#ifdef __LP64__
  mach_msg_type_number_t count = VM_REGION_BASIC_INFO_COUNT_64;
  vm_region_basic_info_data_64_t info;
  kern_return_t info_ret = vm_region_64(
      task, &address, &size, VM_REGION_BASIC_INFO_64, (vm_region_info_64_t)&info, &count, &object);
#else
  mach_msg_type_number_t count = VM_REGION_BASIC_INFO_COUNT;
  vm_region_basic_info_data_t info;
  kern_return_t info_ret = vm_region(task, &address, &size, VM_REGION_BASIC_INFO, (vm_region_info_t)&info, &count, &object);
#endif
  if (info_ret == KERN_SUCCESS) {
    if (prot != NULL)
      *prot = info.protection;

    if (max_prot != NULL)
      *max_prot = info.max_protection;

    return 0;
  }

  return -1;
}
#endif

struct rebindings_entry {
  struct rebinding *rebindings;
  size_t rebindings_nel;
  struct rebindings_entry *next;
};

static struct rebindings_entry *_rebindings_head;

static int prepend_rebindings(struct rebindings_entry **rebindings_head,
                              struct rebinding rebindings[],
                              size_t nel) {
  struct rebindings_entry *new_entry = malloc(sizeof(struct rebindings_entry));
  if (!new_entry) {
    return -1;
  }
  new_entry->rebindings = malloc(sizeof(struct rebinding) * nel);
  if (!new_entry->rebindings) {
    free(new_entry);
    return -1;
  }
  memcpy(new_entry->rebindings, rebindings, sizeof(struct rebinding) * nel);
  new_entry->rebindings_nel = nel;
  new_entry->next = *rebindings_head;
  *rebindings_head = new_entry;
  return 0;
}

/**
 根据算好的符号表地址和偏移量，
 找到在符号表中用于指向共享库目标函数的指针，
 然后将该指针的值（即目标函数的地址）赋值给我们的 *replaced，
 最后修改该指针的值为我们的 replacement（新的函数地址）
 参考：https://juejin.cn/post/6844903789783154702
 */
static void perform_rebinding_with_section(struct rebindings_entry *rebindings,
                                           section_t *section,
                                           intptr_t slide,
                                           nlist_t *symtab,
                                           char *strtab,
                                           uint32_t *indirect_symtab) {
    
    /**
     懒加载符号表 + 非懒加载符号表 这两个section 在 间接符号表 indirect_symbol_table 中的偏移量 index  =  section.reserved1
     （ section.reserved1 就是这个 section在间接符号表中的 偏移量index ）
     section在间接符号表中对应的符号的地址  =  间接符号表的基地址  +  懒加载符号表 / 非懒加载符号表 这两个section 的 reserved1（reserved1指section在间接符号表中的偏移index）
     （其实：间接符号表中主要保存的信息是：指定section在symtab符号表中的位置index，这里的符号表是一个指向 nlist_t 结构体的数组，
     通过间接符号表，可以找到 nlist_t结构体，然后可以获取到 要查找的函数在 字符串表的位置index）
     
     在实际计算地址中用到了 Load Commands 中对应头信息的 Reserved1 的 value
     （section基地址 + 偏移量 value = section 在 Indirect Symbols 中对应的 offset）
     （懒加载符号表的 reserved1 这个偏移值  +  section 基地址  =  懒加载符号表 这个 section 在 间接符号表中的 偏移index）
     */
  uint32_t *indirect_symbol_indices = indirect_symtab + section->reserved1;
    
    /**
     获取 懒加载符号表 + 非懒加载符号表 这两个section 的 地址（section 地址 + ASLR）
     这里获取的就是 符号对应的外部函数的 实现地址数组，也就是外部函数实现的地址。
     这里是一个二维数组
     */
  void **indirect_symbol_bindings = (void **)((uintptr_t)slide + section->addr);
    
    // 遍历 懒加载符号表 + 非懒加载符号表 这两个section里面的 每一个 符号
    // 每个符号（外部函数）在间接符号表中 对应的是一个 地址（指针），所以遍历的时候以一个指针的长度做偏移
  for (uint i = 0; i < section->size / sizeof(void *); i++) {
      
      /**
       遍历 懒加载符号表 + 非懒加载符号表 这两个section里面的 每一个 符号，
       找到 每个符号 在 符号表中的 索引 index。
       间接符号表中 存储的 value 是 每个符号 在 符号表中的 index
       */
    uint32_t symtab_index = indirect_symbol_indices[i];
    if (symtab_index == INDIRECT_SYMBOL_ABS || symtab_index == INDIRECT_SYMBOL_LOCAL ||
        symtab_index == (INDIRECT_SYMBOL_LOCAL   | INDIRECT_SYMBOL_ABS)) {
      continue;
    }
      
      /**
       获取 懒加载符号表中每个符号，在符号表中对应的 符号信息
       符号表 就是一个 指向 nlist_t 结构体 的数组，
       数组中的每个元素就是 一个符号的信息（nlist_t 结构体）
       每个符号对应 一个 nlist_t 结构体（存储符号的信息）
       
       下面获取的就是 每个符号 在 字符串表中的 index 偏移值
       */
    uint32_t strtab_offset = symtab[symtab_index].n_un.n_strx;
      
      /**
       通过在 字符串表 string_table 中的偏移量index + 字符串表的基地址 ，
       获取 懒加载符号表中的 每个符号，对应的符号字符串（符号名）
       */
    char *symbol_name = strtab + strtab_offset;
      
      // 遍历最初的链表，逐一进行hook
    struct rebindings_entry *cur = rebindings;
    while (cur) {
      for (uint j = 0; j < cur->rebindings_nel; j++) {
          
          /**
           strlen(symbol_name) > 1
           因为函数名前面有一个_，所以一个函数名的长度至少是2。
           这里 strcmp就是判断 symbol_name[1] 与 rebindings 中对应的函数名是否相等，相等即为 目标hook函数
           */
        if (strlen(symbol_name) > 1 &&
            strcmp(&symbol_name[1], cur->rebindings[j].name) == 0) {
            
            // 判断replaced方法原来的函数地址不为null
            // 并且我方的实现函数地址 和 rebindings[j].replacement的方法不一致，避免重复交换和空指针
          if (cur->rebindings[j].replaced != NULL &&
              indirect_symbol_bindings[i] != cur->rebindings[j].replacement) {
              
              // 让rebindings[j].replaced 保存 indirect_symbol_bindings[i] 的函数地址
            *(cur->rebindings[j].replaced) = indirect_symbol_bindings[i];
          }
            
            // 将替换后的方法，给原来的方法，也就是替换内容为 自定义函数的地址
            kern_return_t err;
            
            /**
             * 1. Moved the vm protection modifying codes to here to reduce the
             *    changing scope.
             * 2. Adding VM_PROT_WRITE mode unconditionally because vm_region
             *    API on some iOS/Mac reports mismatch vm protection attributes.
             * -- Lianfu Hao Jun 16th, 2021
             **/
            err = vm_protect (mach_task_self (), (uintptr_t)indirect_symbol_bindings, section->size, 0, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
            if (err == KERN_SUCCESS) {
              /**
               * Once we failed to change the vm protection, we
               * MUST NOT continue the following write actions!
               * iOS 15 has corrected the const segments prot.
               * -- Lionfore Hao Jun 11th, 2021
               **/
              indirect_symbol_bindings[i] = cur->rebindings[j].replacement;
            }
            
          goto symbol_loop;
        }
      }
      cur = cur->next;
    }
  symbol_loop:;
  }
}


  
  /**
   1、内存布局说明：
   
   （1）segment & section
   
   segment是没有一个具体数据结构的，它是由 很多个数据结构相同的 section组成的
   紧跟在 segment_command 数据结构之后的是一个 section 数据结构的数组，
   section 的数量由 segment_command 的 nsects 字段确定。
   多个 section 组成一个 segment。
   
   每个 segment 定义了一个虚拟内存区域，动态链接器能够将其映射到进程的地址空间。
   （代码和数据就是不同的segment，segment由包含很多不同的section，比如懒加载符号表就是数据__DATA这个segment其中一个section）
   segment 和 section 的数量和布局则是由 load commands 和文件类型指定的。
   
   对于用户级完全链接的 Mach-O 文件，其最后一个 segment 是 LINKEDIT segment。
   该 segment 包含了符号链接的信息表，
   如：符号表、字符串表等，动态链接器基于这些信息将可执行程序或 Mach-O bundle 与其依赖的库进行链接。
   
   
   （2）Load Command -> cmd 加载命令的类型
   
   LC_SEGMENT：
   表示 segment_command 加载命令。
   将指定的 segment 映射到加载此文件的进程的地址空间中。
   此外，还定义了 segment 所包含的所有 sections。
   
   LC_SYMTAB：
   表示 symtab_command 加载命令。
   用于指定此文件的符号表。
   动态链接或静态链接此文件时都会调用符号表信息，调试器也使用符号表将符号映射到生成符号的原始代码文件。
   
   LC_DYSYMTAB：
   表示 dysymtab_command 加载命令。
   用于指定 动态链接器使用的额外符号表信息。
   
   LC_LOAD_DYLIB：
   表示 dylib_command 加载命令。
   用于定义此文件会链接的动态链接库的名称。
   
   LC_LOAD_DYLINKER：
   表示 dylinker_command 加载命令。
   用于指定 内核加载此文件所使用的动态链接器。

   
   
   
   
   2、内存结构：
   
   Header （machO的文件信息：加载命令的数量、命令所占字节数）
   （数据结构：mach_header_t）
   （ncmds ：指定 Load Commands 的数量）
   （sizeofcmds ：指定 Load Commands 所占据的字节数（这里的大小包括了所有的section的总大小））
   
   
   __DATA segment 的 Load Command ( __DATA segment 的加载命令)
   （数据结构：segment_command_t | symtab_command | dysymtab_command）
   （不同类型的Load Command数据结构具有共同的字段：
   cmd：加载命令类型
   cmdsize：加载命令大小（cmdsize包括对应segment下所有section结构体大小的总和））
   
   __DATA._la_symbol_pointer
   （ __DATA segment 的其中一个 section，一个segment的所有section都具有相同的数据结构类型）
   （数据结构：section_t）
   
   __DATA._Non_la_symbol_pointer
   （ __DATA segment 的其中一个 section）
   （数据结构：section_t）
   
   ...
   
   
   __TEXT segment 的 Load Command（ __TEXT segment 的加载命令）
   （数据结构：segment_command_t | symtab_command | dysymtab_command）
   
   __TEXT.section1
   
   __TEXT.section2
   
   ...
   
   
   
   __LINKEDIT segment 的 Load Command
   （ __LINKEDIT segment的加载命令）
   （数据结构：segment_command_t）
   （包含信息：）
   */

/**
 根据 fishhook 是如何根据字符串对应在符号表中的指针，
 找到其在共享库的函数实现 中的几个步骤，
 去找到目标符号对应指针所指向的函数实现地址：
 */
static void rebind_symbols_for_image(struct rebindings_entry *rebindings,
                                     const struct mach_header *header,
                                     intptr_t slide) {
    
    // 这个 dladdr 方法：就是在程序里面查找 header
  Dl_info info;
  if (dladdr(header, &info) == 0) {
    return;
  }

    // 定义几个变量，然后从 machO 里面去查找，并一一赋值
  segment_command_t *cur_seg_cmd;
  segment_command_t *linkedit_segment = NULL;
  struct symtab_command* symtab_cmd = NULL;
  struct dysymtab_command* dysymtab_cmd = NULL;

    // 跳过header，找 Load Commands（Load Commands 直接就跟在Header后面）
  uintptr_t cur = (uintptr_t)header + sizeof(mach_header_t);
    
    // 遍历 Load Commands
  for (uint i = 0; i < header->ncmds; i++, cur += cur_seg_cmd->cmdsize) {
    cur_seg_cmd = (segment_command_t *)cur;
    if (cur_seg_cmd->cmd == LC_SEGMENT_ARCH_DEPENDENT) {
      if (strcmp(cur_seg_cmd->segname, SEG_LINKEDIT) == 0) {
          
          /**
           segment_command 这个加载命令的基址：
           machO链接后的虚拟内存地址、这个segment相对machO文件的偏移，从而计算出程序的基址。
           将指定的 segment 映射到加载此文件的进程的地址空间中。此外，还定义了 segment 所包含的所有 sections。
           */
        linkedit_segment = cur_seg_cmd;
      }
    } else if (cur_seg_cmd->cmd == LC_SYMTAB) {
        
        /**
         symtab_command 这个加载命令的基址：
         符号表的信息 + 字符串表的信息。
         动态链接或静态链接此文件时都会调用符号表信息，调试器也使用符号表将符号映射到生成符号的原始代码文件。
         */
      symtab_cmd = (struct symtab_command*)cur_seg_cmd;
    } else if (cur_seg_cmd->cmd == LC_DYSYMTAB) {
        
        /**
         dysymtab_command 这个加载命令的基址：
         间接符号表的信息（也叫 动态符号表）
         用于指定 动态链接器使用的额外符号表信息。
         */
      dysymtab_cmd = (struct dysymtab_command*)cur_seg_cmd;
    }
  }

    // 刚才获取的，只要有一项为空，则直接返回
  if (!symtab_cmd || !dysymtab_cmd || !linkedit_segment ||
      !dysymtab_cmd->nindirectsyms) {
    return;
  }

  // Find base symbol/string table addresses
    /**
     链接时，程序的基址  =  linkedit_segment 的 虚拟内存地址  -  linkedit_segment 在 machO 文件的偏移  +  ASLR 地址空间布局随机
     */
  uintptr_t linkedit_base = (uintptr_t)slide + linkedit_segment->vmaddr - linkedit_segment->fileoff;
    
    /**
     符号表的地址  =  程序的基址  +  符号表 在 machO 文件的偏移
     获取的是一个指向 nlist_t 结构体的 数组
     */
  nlist_t *symtab = (nlist_t *)(linkedit_base + symtab_cmd->symoff);
    
    /**
     字符串表 的地址  =  程序的基址  +  字符串表 在 machO 文件中的偏移
     */
  char *strtab = (char *)(linkedit_base + symtab_cmd->stroff);

  // Get indirect symbol table (array of uint32_t indices into symbol table)
    /**
     间接符号表 的地址  =  程序的基址  +  间接符号表 在 machO 文件中的偏移
     */
  uint32_t *indirect_symtab = (uint32_t *)(linkedit_base + dysymtab_cmd->indirectsymoff);

    
    
  cur = (uintptr_t)header + sizeof(mach_header_t);
  for (uint i = 0; i < header->ncmds; i++, cur += cur_seg_cmd->cmdsize) {
    cur_seg_cmd = (segment_command_t *)cur;
      
      // 寻找 segment_command 这个加载命令，它指定的 segment 映射到 加载此文件的进程的地址空间中，还定义了segment所包含的所有sections
    if (cur_seg_cmd->cmd == LC_SEGMENT_ARCH_DEPENDENT) {
        
        // 寻找到 data 段（_DATA 这个 segment）
      if (strcmp(cur_seg_cmd->segname, SEG_DATA) != 0 &&
          strcmp(cur_seg_cmd->segname, SEG_DATA_CONST) != 0) {
        continue;
      }
        
        /**
         遍历 __DATA segment中的sections
         里面包含很多 section：比如 懒加载符号指针  、  非懒加载符号指针
         */
      for (uint j = 0; j < cur_seg_cmd->nsects; j++) {
        section_t *sect =
          (section_t *)(cur + sizeof(segment_command_t)) + j;
          
          // 懒加载符号表
        if ((sect->flags & SECTION_TYPE) == S_LAZY_SYMBOL_POINTERS) {
          perform_rebinding_with_section(rebindings, sect, slide, symtab, strtab, indirect_symtab);
        }
          
          // 非懒加载符号表
        if ((sect->flags & SECTION_TYPE) == S_NON_LAZY_SYMBOL_POINTERS) {
          perform_rebinding_with_section(rebindings, sect, slide, symtab, strtab, indirect_symtab);
        }
      }
    }
  }
}

/**
 当回调到 _rebind_symbols_for_image 时，
 第一个参数 会将存着待绑定函数信息的链表作为参数传入，用于符号查找和函数指针的交换，
 第二个参数 header是 当前 image 的头信息，
 第三个参数 slide是 ASLR 的偏移：
 */
static void _rebind_symbols_for_image(const struct mach_header *header,
                                      intptr_t slide) {
    rebind_symbols_for_image(_rebindings_head, header, slide);
}

int rebind_symbols_image(void *header,
                         intptr_t slide,
                         struct rebinding rebindings[],
                         size_t rebindings_nel) {
    struct rebindings_entry *rebindings_head = NULL;
    int retval = prepend_rebindings(&rebindings_head, rebindings, rebindings_nel);
    rebind_symbols_for_image(rebindings_head, header, slide);
    free(rebindings_head);
    return retval;
}

int rebind_symbols(struct rebinding rebindings[], size_t rebindings_nel) {
  int retval = prepend_rebindings(&_rebindings_head, rebindings, rebindings_nel);
  if (retval < 0) {
    return retval;
  }
  // If this was the first call, register callback for image additions (which is also invoked for
  // existing images, otherwise, just run on existing images
  /**
   根据_rebindings_head->next是否为空，判断是否第一次调用
   */
  if (!_rebindings_head->next) {
      /**
       第一次调用
       调用_dyld_register_func_for_add_image 注册监听方法。
       已经被 dyld 加载的 image 会立刻进入回调；
       之后被 dyld 加载的 image 会在dyld加载的时候触发回调，回调方法就是 _rebind_symbols_for_image
       */
    _dyld_register_func_for_add_image(_rebind_symbols_for_image);
  } else {
      // 遍历已经被 dyld 加载的 image，找到目标函数，逐一进行hook
    uint32_t c = _dyld_image_count();
    for (uint32_t i = 0; i < c; i++) {
      _rebind_symbols_for_image(_dyld_get_image_header(i), _dyld_get_image_vmaddr_slide(i));
    }
  }
  return retval;
}
