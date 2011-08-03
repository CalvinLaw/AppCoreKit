//
//  CKNSDictionary+Styles.h
//  CloudKit
//
//  Created by Sebastien Morel on 11-04-20.
//  Copyright 2011 WhereCloud Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CKModelObject.h"


/** TODO
 */
extern NSString* CKStyleFormats;

/** TODO
 */
extern NSString* CKStyleParentStyle;

/** TODO
 */
extern NSString* CKStyleEmptyStyle;

/** TODO
 */
extern NSString* CKStyleInherits;

/** TODO
 */
extern NSString* CKStyleImport;


/** TODO
 */
@interface CKStyleFormat : NSObject{
}
@property(nonatomic,retain) NSString* format;
@property(nonatomic,assign) Class objectClass;
@property(nonatomic,retain) NSString* propertyName;
@property(nonatomic,retain) NSMutableArray* properties;

- (id)initFormatWithFormat:(NSString*)format;
- (NSString*)formatForObject:(id)object propertyName:(NSString*)propertyName className:(NSString*)className;
+ (NSString*)normalizeFormat:(NSString*)format;

@end


/** TODO
 */
@interface NSDictionary (CKKey)
- (BOOL)containsObjectForKey:(NSString*)key;
@end


/** TODO
 */
@interface NSMutableDictionary (CKStyle)

- (NSMutableDictionary*)styleForObject:(id)object propertyName:(NSString*)propertyName;

- (void)processImports;
- (void)initAfterLoading;
- (void)postInitAfterLoading;
- (void)setFormat:(CKStyleFormat*)format;
- (void)setStyle:(NSMutableDictionary*)style forKey:(NSString*)key;
- (NSMutableDictionary*)parentStyle;
- (BOOL)isEmpty;

@end