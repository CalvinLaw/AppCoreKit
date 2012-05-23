//
//  CKNSString+URIQuery.m
//
//  Created by Fred Brunel on 12/08/09.
//  Copyright 2009 WhereCloud Inc. All rights reserved.
//
//  by Jerry Krinock.
//

#import "CKNSString+URIQuery.h"

NSString * const CKSpecialURLCharacters = @"!*'();:@&=+$,/?%#[]";

@implementation NSString (CKNSStringURIQueryAdditions)

- (NSString*)encodePercentEscapesPerRFC2396 {
	return (NSString*)[(NSString*)CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)self, NULL, NULL, kCFStringEncodingUTF8) autorelease] ;
}

//

- (NSString*)encodePercentEscapesStrictlyPerRFC2396 {
	CFStringRef decodedString = (CFStringRef)[self decodeAllPercentEscapes] ;
	// The above may return NULL if url contains invalid escape sequences like %E8me, %E8fe, %E800 or %E811,
	// because CFURLCreateStringByReplacingPercentEscapes() isn't smart enough to ignore them.
	CFStringRef recodedString = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, decodedString, NULL, NULL, kCFStringEncodingUTF8);
	// And then, if decodedString is NULL, recodedString will be NULL too.
	// So, we recover from this rare but possible error by returning the original self
	// because it's "better than nothing".
	NSString* answer = (recodedString != NULL) ? [(NSString*)recodedString autorelease] : self ;
	// Note that if recodedString is NULL, we don't need to CFRelease() it.
	// Actually, CFRelease(NULL) causes a crash.  That's kind of stupid, Apple.
	return answer ;
}

//

- (NSString*)encodePercentEscapesPerRFC2396ButNot:(NSString*)butNot butAlso:(NSString*)butAlso {
	return (NSString*)[(NSString*)CFURLCreateStringByAddingPercentEscapes(
																		  NULL,
																		  (CFStringRef)self,
																		  (CFStringRef)butNot,
																		  (CFStringRef)butAlso,
																		  kCFStringEncodingUTF8
																		  ) autorelease] ;
}

//

+ (NSString *)stringWithQueryDictionary:(NSDictionary*)dictionary {
	NSMutableString* string = [NSMutableString string] ;
	NSUInteger countdown = [dictionary count] ;
	for (NSString* key in dictionary) {
		id value = [dictionary valueForKey:key];
		NSAssert(([value isKindOfClass:[NSString class]] || [value isKindOfClass:[NSArray class]]), @"Parameter type not supported: %@", [value class]);

		if ([value isKindOfClass:[NSString class]]) {
			[string appendFormat:@"%@=%@",
			 [key encodePercentEscapesPerRFC2396ButNot:nil butAlso:CKSpecialURLCharacters],
			 [[dictionary valueForKey:key] encodePercentEscapesPerRFC2396ButNot:nil butAlso:CKSpecialURLCharacters]
			 ];	
		}
		if ([value isKindOfClass:[NSArray class]]) {
			NSUInteger count = [value count];
			for (id arrayValue in value) {
				NSAssert([arrayValue isKindOfClass:[NSString class]], @"Array value not supported: %@", [arrayValue class]);
				[string appendFormat:@"%@=%@",
				 [key encodePercentEscapesPerRFC2396ButNot:nil butAlso:CKSpecialURLCharacters],
				 [arrayValue encodePercentEscapesPerRFC2396ButNot:nil butAlso:CKSpecialURLCharacters]
				 ];
				if (--count > 0) [string appendString:@"&"];
			}
		}

		countdown-- ;
		if (countdown > 0) {
			[string appendString:@"&"] ;
		}
	}
	return [NSString stringWithString:string] ;
}

//

- (NSString*)decodeAllPercentEscapes {
	// Unfortunately, CFURLCreateStringByReplacingPercentEscapes() seems to only replace %[NUMBER] escapes
	NSString* cfWay = (NSString*)[(NSString*)CFURLCreateStringByReplacingPercentEscapes(kCFAllocatorDefault, (CFStringRef)self, CFSTR("")) autorelease] ;
	NSString* cocoaWay = [self stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] ;
	if (![cfWay isEqualToString:cocoaWay]) {
		NSLog(@"[%@ %@]: CF and Cocoa different for %@", [self class], NSStringFromSelector(_cmd), self) ;
	}
	
	return cfWay ;
}

//

- (NSDictionary*)queryDictionaryUsingEncoding:(NSStringEncoding)encoding {
	NSCharacterSet* delimiterSet = [NSCharacterSet characterSetWithCharactersInString:@"&;"] ;
	NSMutableDictionary* pairs = [NSMutableDictionary dictionary] ;
	NSScanner* scanner = [[NSScanner alloc] initWithString:self] ;
	while (![scanner isAtEnd]) {
		NSString* pairString ;
		[scanner scanUpToCharactersFromSet:delimiterSet
								intoString:&pairString] ;
		[scanner scanCharactersFromSet:delimiterSet intoString:NULL] ;
		NSArray* kvPair = [pairString componentsSeparatedByString:@"="] ;
		if ([kvPair count] == 2) {
			NSString* key = [[kvPair objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:encoding] ;
			NSString* value = [[kvPair objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:encoding] ;
			[pairs setObject:value forKey:key] ;
		}
	}
	[scanner release];
	
	return [NSDictionary dictionaryWithDictionary:pairs] ;
}

@end
