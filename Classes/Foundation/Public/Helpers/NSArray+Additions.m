//
//  NSArray+Additions.m
//
//  Created by Fred Brunel.
//  Copyright 2009 WhereCloud Inc. All rights reserved.
//

#import "NSArray+Additions.h"

@implementation NSArray (CKNSArrayAdditions)

- (id)first {
	return self.count > 0 ? [self objectAtIndex:0] : nil;
}

- (id)second {
	return self.count > 1 ? [self objectAtIndex:1] : nil;
}

- (id)last {
	return self.count > 0 ? [self lastObject] : nil;
}

- (NSArray *)rest {
	if (self.count == 0) return self;
	NSRange range;
	range.location = 1;
	range.length = self.count - 1;
	return [self subarrayWithRange:range];
}

- (NSArray *)reversedArray {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:[self count]];
    NSEnumerator *enumerator = [self reverseObjectEnumerator];
    for (id element in enumerator) {
        [array addObject:element];
    }
    return array;
}

- (NSArray *)shuffledArray {
	NSMutableArray *array = [NSMutableArray arrayWithCapacity:[self count]];
	NSMutableArray *copy = [self mutableCopy];

	while ([copy count] > 0) {
		NSUInteger index = arc4random() % [copy count];
		id object = [copy objectAtIndex:index];
		[array addObject:object];
		[copy removeObjectAtIndex:index];
	}
		
	[copy release];
	
	return array;
}

- (BOOL)containsString:(NSString *)string {
	for (NSObject *object in self) {
		if ([object isKindOfClass:[NSString class]]) {
			if ([(NSString *)object isEqualToString:string]) { return YES; }
		}
	}
	return NO;
}

- (BOOL)containsObjectWithPredicate:(NSPredicate *)predicate {
	for (NSObject *object in self) {
		if ([predicate evaluateWithObject:object] == TRUE) { return YES; }
	}
	return NO;
}

- (NSArray *)arrayWithValuesByMakingObjectsPerformSelector:(SEL)selector withObject:(id)object {
	NSMutableArray *result = [NSMutableArray array];
	for (id anObject in self) {
		id value = nil;
		if ([anObject respondsToSelector:selector]) {
			value = [anObject performSelector:selector withObject:object];
		}
		if (value == nil) {
			[result addObject:[NSNull null]];
		} else {
			[result addObject:value];
		}
	}
	return result;
}

@end