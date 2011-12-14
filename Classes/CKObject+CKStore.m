//
//  CKNSObject+CKStore.m
//  StoreTest
//
//  Created by Sebastien Morel on 11-06-03.
//  Copyright 2011 WhereCloud Inc. All rights reserved.
//

#import "CKObject+CKStore.h"

#import "CKStoreDataSource.h"
#import "CKItem.h"
#import "CKStore.h"
#import "CKAttribute.h"
#import "CKDomain.h"
#import "CKDebug.h"
#import "CKObject.h"
#import "CKObjectProperty.h"
#import "CKNSValueTransformer+Additions.h"
#import "CKNSStringAdditions.h"
#import "CKWeakRef.h"

NSMutableDictionary* CKObjectManager = nil;

@interface CKObject (CKStoreAdditionPrivate)
- (NSDictionary*) attributesDictionaryForDomainNamed:(NSString*)domain alreadySaved:(NSMutableSet*)alreadySaved recursive:(BOOL)recursive;
@end

@implementation CKObject (CKStoreAddition)

- (NSDictionary*) attributesDictionaryForDomainNamed:(NSString*)domain{
	return [self attributesDictionaryForDomainNamed:domain alreadySaved:[NSMutableSet set] recursive:NO];
}

- (void)deleteFromDomainNamed:(NSString*)domain{
	NSAssert(!_loading, @"cannot delete an object while loading it !");
	
	CKItem* item = [CKObject itemWithObject:self inDomainNamed:domain];
	if(item){
		CKStore* store = [CKStore storeWithDomainName:domain];
		[store deleteItems:[NSArray arrayWithObject:item]];
	}
}

+ (CKItem *)createItemWithObject:(CKObject*)object inDomainNamed:(NSString*)domain alreadySaved:(NSMutableSet*)alreadySaved recursive:(BOOL)recursive{
	CKStore* store = [CKStore storeWithDomainName:domain];
	BOOL created;
	CKItem *item = [store fetchItemWithPredicate:[NSPredicate predicateWithFormat:@"(name == %@) AND (domain == %@)", object.objectName, domain]
								createIfNotFound:YES wasCreated:&created];
	if (created) {
		item.name = object.objectName;
		item.domain = store.domain;
		[store.domain addItemsObject:item];
	}
	NSDictionary* attributes = [object attributesDictionaryForDomainNamed:domain alreadySaved:alreadySaved recursive:recursive];
	[item updateAttributes:attributes];
	
	//CKDebugLog(@"Updating item <%p> withAttributes:%@",item,attributes);
	return item;
}

- (CKItem*)saveToDomainNamed:(NSString*)domain alreadySaved:(NSMutableSet*)alreadySaved recursive:(BOOL)recursive{
	if(_saving || _loading)
		return nil;
	
	_saving = YES;
	CKItem* item = nil;
	if(self.uniqueId == nil){
		self.uniqueId = [NSString stringWithNewUUID];
		[CKObject registerObject:self withUniqueId:self.uniqueId];
		item = [CKObject createItemWithObject:self inDomainNamed:domain alreadySaved:alreadySaved recursive:recursive];
	}
	else{
		item = [CKObject itemWithObject:self inDomainNamed:domain];
		if(item != nil){
			item.name = self.objectName;
			NSDictionary* attributes = [self attributesDictionaryForDomainNamed:domain alreadySaved:alreadySaved recursive:recursive];
			[item updateAttributes:attributes];
			//CKDebugLog(@"Updating item <%p> withAttributes:%@",item,attributes);
		}
		else{
			[CKObject registerObject:self withUniqueId:self.uniqueId];
			item = [CKObject createItemWithObject:self inDomainNamed:domain];
		}
	}		
	
	[alreadySaved addObject:self];
	_saving = NO;
	return item;
}

+ (CKItem *)createItemWithObject:(CKObject*)object inDomainNamed:(NSString*)domain {
	return [self createItemWithObject:object inDomainNamed:domain alreadySaved:[NSMutableSet set] recursive:NO];
}

- (CKItem*)saveToDomainNamed:(NSString*)domain{
	return [self saveToDomainNamed:domain recursive:NO];
}

- (CKItem*)saveToDomainNamed:(NSString*)domain recursive:(BOOL)recursive{
	return [self saveToDomainNamed:domain alreadySaved:[NSMutableSet set] recursive:recursive];
}

+ (CKItem*)itemWithObject:(CKObject*)object inDomainNamed:(NSString*)domain{
	return [CKObject itemWithObject:object inDomainNamed:domain createIfNotFound:NO];
}

+ (CKItem*)itemWithObject:(CKObject*)object inDomainNamed:(NSString*)domain createIfNotFound:(BOOL)createIfNotFound{
	CKItem* item = [CKObject itemWithUniqueId:object.uniqueId inDomainNamed:domain];
	if(item == nil && createIfNotFound){
		return [object saveToDomainNamed:domain];
	}
	return item;
}

+ (CKItem*)itemWithUniqueId:(NSString*)theUniqueId inDomainNamed:(NSString*)domain{
	CKStore* store = [CKStore storeWithDomainName:domain];
	NSArray *res = [store fetchAttributesWithFormat:[NSString stringWithFormat:@"(name == 'uniqueId' AND value == '%@')",theUniqueId] arguments:nil];
	if([res count] != 1){
		//CKDebugLog(@"Warning : %@ object(s) found in domain '%@' with uniqueId '%@'",(([res count]==0) ? @"no" : "Several"),domain,theUniqueId);
		return nil;
	}
	return [[res lastObject]item];	
}

+ (id)releaseObject:(CKWeakRef*)weakRef{
	//CKDebugLog(@"delete object <%p> of type <%@> with id %@",target,[target class],[target uniqueId]);
	[CKObjectManager removeObjectForKey:[weakRef.object uniqueId]];
	return nil;
}

+ (CKObject*)objectWithUniqueId:(NSString*)uniqueId{
	CKWeakRef* objectRef = [CKObjectManager objectForKey:uniqueId];
	id object = [objectRef object];
	if(objectRef != nil){
		//CKDebugLog(@"Found registered object <%p> of type <%@> with uniqueId : %@",object,[object class],uniqueId);
	}
	return object;
}

+ (CKObject*)loadObjectWithUniqueId:(NSString*)uniqueId{
	CKObject* obj = [self objectWithUniqueId:uniqueId];
	if(obj != nil)
		return obj;
	
	CKStore* store = [CKStore storeWithDomainName:@"whatever"];
	NSArray *res = [store fetchAttributesWithFormat:[NSString stringWithFormat:@"(name == 'uniqueId' AND value == '%@')",uniqueId] arguments:nil];
	if([res count] == 1){
		CKItem* item = (CKItem*)[[res lastObject]item];
		return [NSObject objectFromDictionary:[item propertyListRepresentation]];
	}
	return nil;
}

+ (void)registerObject:(CKObject*)object withUniqueId:(NSString*)uniqueId{
	if(uniqueId == nil){
		//CKDebugLog(@"Trying to register an object with no uniqueId : %@",object);
		return;
	}
	
	if(CKObjectManager == nil){
		CKObjectManager = [[NSMutableDictionary alloc]init];
	}
	
	CKWeakRef* objectRef = [CKWeakRef weakRefWithObject:object target:self action:@selector(releaseObject:)];
	[CKObjectManager setObject:objectRef forKey:uniqueId];
	
	//CKDebugLog(@"Register object <%p> of type <%@> with id %@",object,[object class],uniqueId);
}


+ (NSArray*)itemsWithClass:(Class)type withPropertiesAndValues:(NSDictionary*)attributes inDomainNamed:(NSString*)domain{
	CKStore* store = [CKStore storeWithDomainName:domain];
	NSMutableString* predicate = [NSMutableString stringWithFormat:@"(ANY attributes.name == '@class') AND (ANY attributes.value == '%@')",[type description]];
	for(NSString* propertyName in attributes){
		id value = [attributes objectForKey:propertyName];
		NSString* attributeStr = [NSValueTransformer transform:value toClass:[NSString class]];
		[predicate appendFormat:@"AND (ANY attributes.name == '%@') AND (ANY attributes.value == '%@')",propertyName,attributeStr];
	}
	return [store fetchItemsWithPredicateFormat:predicate arguments:nil];
}

@end


@implementation CKObject (CKStoreAdditionPrivate)

- (NSDictionary*) attributesDictionaryForDomainNamed:(NSString*)domain alreadySaved:(NSMutableSet*)alreadySaved recursive:(BOOL)recursive{
	NSAssert(alreadySaved != nil,@"has to be created to avoid recursive save ...");
	NSMutableDictionary* dico = [NSMutableDictionary dictionary];
	
	NSString* className = [[self class] description];
	[dico setObject:className forKey:@"@class"];
	
	NSArray* allProperties = [self allPropertyNames];
	for(NSString* propertyName in allProperties){
		CKObjectProperty* property = [CKObjectProperty propertyWithObject:self keyPath:propertyName];
		CKClassPropertyDescriptor* descriptor = [property descriptor];
		CKObjectPropertyMetaData* metaData = [property metaData];
		if( (metaData  && metaData.serializable == NO) || descriptor.isReadOnly == YES){}
		else{
			id propertyValue = [property value];
			if([propertyValue isKindOfClass:[CKDocumentCollection class]]
			   || [propertyValue isKindOfClass:[NSArray class]]
			   || [propertyValue isKindOfClass:[NSSet class]]){
				NSArray* allObjects = propertyValue;
				if([propertyValue isKindOfClass:[NSArray class]] == NO){
					allObjects = [propertyValue allObjects];
				}
				NSMutableArray* result = [NSMutableArray array];
				for(id subObject in allObjects){
					NSAssert([subObject isKindOfClass:[CKObject class]],@"Supports only auto serialization on CKObject");
					CKObject* model = (CKObject*)subObject;
					CKItem* item = nil;
					if(model.uniqueId != nil){
                        if([alreadySaved containsObject:model] || !recursive){
                            item = [CKObject itemWithUniqueId:model.uniqueId inDomainNamed:domain];
                        }
                        else{
                            item = [model saveToDomainNamed:domain alreadySaved:alreadySaved recursive:recursive];
                        }
					}else{
						item = [model saveToDomainNamed:domain alreadySaved:alreadySaved recursive:recursive];
					}
					[result addObject:item];
				}
				[dico setObject:result forKey:propertyName];
			}
			else if([propertyValue isKindOfClass:[CKObject class]]){
				CKObject* model = (CKObject*)propertyValue;
				
				NSMutableArray* result = [NSMutableArray array];
				CKItem* item = nil;
                if(model.uniqueId != nil){
                    if([alreadySaved containsObject:model] || !recursive){
                        item = [CKObject itemWithUniqueId:model.uniqueId inDomainNamed:domain];
                    }
                    else{
                        item = [model saveToDomainNamed:domain alreadySaved:alreadySaved recursive:recursive];
                    }
                }else{
                    item = [model saveToDomainNamed:domain alreadySaved:alreadySaved recursive:recursive];
                }
                
				[result addObject:item];
				[dico setObject:result forKey:propertyName];
			}
			else{
				id value = [NSValueTransformer transformProperty:property toClass:[NSString class]];
				if([value isKindOfClass:[NSString class]]){
					[dico setObject:value forKey:propertyName];
				}
			}
		}
	}
	
	return dico;
}

@end