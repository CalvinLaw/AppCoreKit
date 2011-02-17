//
//  CKFeedSource.m
//  CloudKit
//
//  Created by Fred Brunel on 11-01-14.
//  Copyright 2011 WhereCloud Inc. All rights reserved.
//

#import "CKFeedSource.h"

@interface CKFeedSource ()
@property (nonatomic, retain, readwrite) id<CKDocument> document;
@property (nonatomic, retain, readwrite) NSString *objectsKey;
@end

@implementation CKFeedSource

@synthesize delegate = _delegate;
@synthesize currentIndex = _currentIndex;
@synthesize limit = _limit;
@synthesize hasMore = _hasMore;
@synthesize isFetching = _isFetching;

@synthesize document = _document;
@synthesize objectsKey = _objectsKey;
#pragma mark Initialization

- (id)initWithDocument:(id<CKDocument>)theDocument forKey:(NSString*)key{
	if (self = [super init]) {
		self.document = theDocument;
		self.objectsKey = key;
		[self reset];
		_currentIndex = [self.items count];
	}
	return self;
}

- (id)init {
	if (self = [super init]) {
		[self reset];
	}
	return self;
}

- (void)dealloc {
	_delegate = nil;
	self.document = nil;
	self.objectsKey = nil;
	[super dealloc];
}

#pragma mark Public API

- (BOOL)fetchNextItems:(NSUInteger)batchSize {
	return NO;
}

- (void)cancelFetch {
	_fetching = NO;
	return;
}

- (void)reset {
	_currentIndex = 0;
	_hasMore = YES;
	_fetching = NO;
}

- (NSArray*)items{
	NSAssert(_document,@"Model is not assigned");
	return [_document objectsForKey:_objectsKey];
}

- (void)addObserver:(id)object{
	NSAssert(_document,@"Model is not assigned");
	[_document addObserver:object forKey:_objectsKey];
}

- (void)removeObserver:(id)object{
	NSAssert(_document,@"Model is not assigned");
	[_document removeObserver:object forKey:_objectsKey];	
}

#pragma mark KVO

- (void)addItems:(NSArray *)theItems {
	NSArray *newItems = theItems;
	
	if ((_limit > 0) && (_currentIndex + theItems.count) > _limit) {
		newItems = [theItems subarrayWithRange:NSMakeRange(0, abs(_limit - _currentIndex))];
		_hasMore = NO;
	}
	
	NSAssert(_document,@"Model is not assigned");
	[_document addObjects:newItems forKey:_objectsKey];
}

@end
