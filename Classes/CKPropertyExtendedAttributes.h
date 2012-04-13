//
//  CKPropertyExtendedAttributes.h
//  CloudKit
//
//  Created by Sebastien Morel on 11-08-12.
//  Copyright 2011 Wherecloud. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CKNSValueTransformer+NativeTypes.h"//for CKEnumDescriptor
#import "CKNSObject+CKRuntime.h"

/** Extended Attributes is a way to extend how an object's property will react with several behaviours of the ClouKit like serialization, creation, data migration, property grid display, and conversions.
 
 by defining a selector - (void) yourPropertyExtendedAttributes:(CKPropertyExtendedAttributes*)attributes in your classes, you will be able to customize how yourProperty will react in all the cases described previously.
 
 Concerning the property grid representation, there several ways to customize the representation of your property : enumDescriptor, valuesAndLabels,propertyCellControllerClass or nothing.
 
 propertyCellControllerClass will get used as the top priority. after, we'll use enumDescriptor or valuesAndLabels that should be used independently depending whether your represent an enum property or something else. and finally, property grids will automatically choose a controller class depending on the property type automatically.
 */
@interface CKPropertyExtendedAttributes : NSObject{
}

/** 
 Specify options that could be used by various behaviours in app or in the cloudkit.
 */
@property (nonatomic, retain) NSMutableDictionary* attributes;

+ (CKPropertyExtendedAttributes*)extendedAttributesForObject:(id)object property:(CKClassPropertyDescriptor*)property;

@end
