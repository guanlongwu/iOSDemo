//
// Copyright (c) 2008-present, Meitu, Inc.
// All rights reserved.
//
// This source code is licensed under the license found in the LICENSE file in
// the root directory of this source tree.
//
// Created on: 2018/12/18
// Created by: EuanC
//


#import <Foundation/Foundation.h>
#import "MTHawkeyeSettingTableEntity.h"

NS_ASSUME_NONNULL_BEGIN

@interface MTHAllocationsSettingEntity : NSObject

+ (MTHawkeyeSettingSwitcherCellEntity *)loggerSwitcherCell;
+ (MTHawkeyeSettingSwitcherCellEntity *)includeSystemFrameSwitcherCell;
+ (MTHawkeyeSettingEditorCellEntity *)mallocReportThresholdEditorCell;
+ (MTHawkeyeSettingEditorCellEntity *)vmReportThresholdEditorCell;
+ (MTHawkeyeSettingEditorCellEntity *)reportCategoryElementCountThresholdEditorCell;

+ (MTHawkeyeSettingSwitcherCellEntity *)singleChunkMallocSwitcherCell;
+ (MTHawkeyeSettingEditorCellEntity *)chunkMallocThresholdEditorCell;

@end

NS_ASSUME_NONNULL_END
