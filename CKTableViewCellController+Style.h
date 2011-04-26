//
//  CKTableViewCellController+Style.h
//  CloudKit
//
//  Created by Sebastien Morel on 11-04-21.
//  Copyright 2011 WhereCloud Inc. All rights reserved.
//

#import "CKTableViewCellController.h"
#import "CKUIViewController+Style.h"

extern NSString* CKStyleCellType;
extern NSString* CKStyleAccessoryType;

@interface NSMutableDictionary (CKTableViewCellControllerStyle)

- (UITableViewCellStyle)cellStyle;
- (UITableViewCellAccessoryType)accessoryType;

@end

@interface CKTableViewCellController (CKStyle)

- (void)applyStyle:(UITableViewCell*)cell;
- (NSMutableDictionary*)controllerStyle;
- (UIView*)parentControllerView;

@end
