//
//  CKMapping2.m
//  CloudKit
//
//  Created by Sebastien Morel on 11-07-21.
//  Copyright 2011 Wherecloud. All rights reserved.
//

#import "CKMappingContext.h"
#import "CKNSValueTransformer+Additions.h"
#import "CKNSObject+Introspection.h"
#import "CKObjectProperty.h"
#import "CKDocumentCollection.h"
#import "CKCallback.h"
#import "JSONKit.h"
#import <objc/runtime.h>

NSString * const CKMappingErrorDomain = @"CKMappingErrorDomain";
NSString * const CKMappingErrorDetailsKey = @"CKMappingErrorDetailsKey";

//behaviour
NSString* CKMappingObjectKey = @"@object";
NSString* CKMappingClassKey = @"@class";
NSString* CKMappingMappingsKey = @"@mappings";
NSString* CKMappingReverseMappingsKey = @"@reverseMappings";
NSString* CKMappingtargetKeyPathKey = @"@keyPath";
NSString* CKMappingSelfKey = @"@self";

//defaults
NSString* CKMappingRequieredKey = @"@required";
NSString* CKMappingDefaultValueKey = @"@defaultValue";
NSString* CKMappingTransformSelectorKey = @"@transformSelector";
NSString* CKMappingTransformSelectorClassKey = @"@transformClass";
NSString* CKMappingTransformCallbackKey = @"@transformCallback";

//list managememt
NSString* CKMappingClearContainerKey = @"@clearContent";
NSString* CKMappingInsertAtBeginKey = @"@insertContentAtBegin";

//CKMappingManager

@interface CKMappingManager : CKCascadingTree {
}

+ (CKMappingManager*)defaultManager;

- (void)loadContentOfFileNamed:(NSString*)name;
- (BOOL)importContentOfFileNamed:(NSString*)name;


- (id)objectFromValue:(id)sourceObject withMappings:(NSMutableDictionary*)mappings reversed:(BOOL)reversed error:(NSError**)error;
- (id)objectFromValue:(id)sourceObject withMappingsIdentifier:(id)identifier reversed:(BOOL)reversed error:(NSError**)error;

- (NSMutableDictionary*)mappingsForObject:(id)object propertyName:(NSString*)propertyName;
- (NSMutableDictionary*)mappingsForIdentifier:(id)identifier;

@end

//NSMutableDictionary (CKMappingManager)

@interface NSMutableDictionary (CKMappingManager)

- (NSMutableDictionary*)mappingsForObject:(id)object propertyName:(NSString*)propertyName;

@end


@implementation NSMutableDictionary (CKStyleManager)

- (NSMutableDictionary*)mappingsForObject:(id)object propertyName:(NSString*)propertyName{
    return [self dictionaryForObject:object propertyName:propertyName];
}

@end

//NSObject (CKMapping2) 

@interface NSObject (CKMapping2) 

- (id)initWithObject:(id)sourceObject withMappings:(NSMutableDictionary*)mappings error:(NSError**)error;
- (void)setupWithObject:(id)sourceObject withMappings:(NSMutableDictionary*)mappings error:(NSError**)error;
- (void)setupWithObject:(id)sourceObject withMappings:(NSMutableDictionary*)mappings reversed:(BOOL)reversed error:(NSError**)error;

- (id)initWithObject:(id)sourceObject withMappingsIdentifier:(id)identifier error:(NSError**)error;
- (void)setupWithObject:(id)sourceObject withMappingsIdentifier:(id)identifier error:(NSError**)error;

+ (id)objectFromValue:(id)sourceObject withMappings:(NSMutableDictionary*)mappings reversed:(BOOL)reversed error:(NSError**)error;
+ (id)objectFromValue:(id)sourceObject withMappingsIdentifier:(id)identifier reversed:(BOOL)reversed error:(NSError**)error;

@end


@implementation NSObject (CKMapping2) 

//---------------------------------- Initialization -----------------------------
- (id)initWithObject:(id)sourceObject withMappingsIdentifier:(id)identifier error:(NSError**)error{
    self = [self initWithObject:sourceObject withMappings:[[CKMappingManager defaultManager]mappingsForIdentifier:identifier] error:error];
    return self;
}

- (void)setupWithObject:(id)sourceObject withMappingsIdentifier:(id)identifier error:(NSError**)error{
    [self setupWithObject:sourceObject withMappings:[[CKMappingManager defaultManager]mappingsForIdentifier:identifier] error:error];
}

- (id)initWithObject:(id)sourceObject withMappings:(NSMutableDictionary*)mappings error:(NSError**)error{
    self = [self init];
    [self setupWithObject:sourceObject withMappings:mappings error:error];
    return self;
}

+ (id)objectFromValue:(id)sourceObject withMappingsIdentifier:(id)identifier reversed:(BOOL)reversed error:(NSError**)error{
    return [[CKMappingManager defaultManager]objectFromValue:sourceObject withMappingsIdentifier:identifier reversed:reversed error:error];
}

// ----------------------  Dictionary parser -------------------------

//Search for @mappings key and resolve reference
- (NSMutableDictionary*)mappingsDefinition:(NSMutableDictionary*)dico{
    id mappingsDefinition = [dico objectForKey:CKMappingMappingsKey];
    if([mappingsDefinition isKindOfClass:[NSString class]]){
        return [dico dictionaryForKey:mappingsDefinition];
    }
    else if([mappingsDefinition isKindOfClass:[NSDictionary class]]){
        return mappingsDefinition;
    }
    return nil;
}

- (NSMutableDictionary*)objectDefinition:(NSMutableDictionary*)dico{
    id objectDefinition = [dico objectForKey:CKMappingObjectKey];
    if(objectDefinition && [objectDefinition isKindOfClass:[NSDictionary class]]){
        return objectDefinition;
    }
    return nil;
}

- (BOOL)boolValueForKey:(NSString*)key inDictionary:(NSMutableDictionary*)dico{
    BOOL bo = NO;
    id object = [dico objectForKey:key];
    if(object){
        bo = [NSValueTransformer convertBoolFromObject:object];
    }
    return bo;
}

- (BOOL)isRequired:(NSMutableDictionary*)dico{
    return [self boolValueForKey:CKMappingRequieredKey inDictionary:dico];
}

- (BOOL)needsToBeCleared:(NSMutableDictionary*)dico{
    return [self boolValueForKey:CKMappingClearContainerKey inDictionary:dico];
}

- (BOOL)insertAtBegin:(NSMutableDictionary*)dico{
    return [self boolValueForKey:CKMappingInsertAtBeginKey inDictionary:dico];
}

- (BOOL)reverseMappings:(NSMutableDictionary*)dico{
    return [self boolValueForKey:CKMappingReverseMappingsKey inDictionary:dico];
}

- (Class)objectClass:(NSMutableDictionary*)dico defaultClass:(Class)c{
    NSString* className = [dico objectForKey:CKMappingClassKey];
    if(!className){
        id subObjectMappings = [self mappingsDefinition:dico];
        if(subObjectMappings){
            className = [subObjectMappings objectForKey:CKMappingClassKey];
        }
    }
    return (className == nil) ? c : NSClassFromString(className);
}

- (Class)transformClass:(NSMutableDictionary*)dico defaultClass:(Class)c{
    NSString* className = [dico objectForKey:CKMappingTransformSelectorClassKey];
    return (className == nil) ? c : NSClassFromString(className);
}

- (SEL)transformSelector:(NSMutableDictionary*)dico{
     NSString* selectorName = [dico objectForKey:CKMappingTransformSelectorKey];
    return (selectorName == nil) ? nil : NSSelectorFromString(selectorName);
}

- (CKCallback*)transformCallback:(NSMutableDictionary*)dico{
    return [dico objectForKey:CKMappingTransformCallbackKey];
}

- (BOOL)isSelf:(NSString*)s{
    return [s isEqualToString:CKMappingSelfKey];
}

- (NSString*)keyPath:(NSMutableDictionary*)dico{
    return [dico objectForKey:CKMappingtargetKeyPathKey];
}

- (NSString*)defaultValue:(NSMutableDictionary*)dico{
    return [dico objectForKey:CKMappingDefaultValueKey];
}

//------------------------------- Mapping Engine ------------------------------

- (id)createObjectOfClass:(Class)c withObject:(id)source withMappings:(NSMutableDictionary*)mappings reversed:(BOOL)reversed error:(NSError**)error{
    if(*error)
        return nil;
    
    id object = [[[c alloc]init] autorelease];
    [object setupWithObject:source withMappings:mappings reversed:reversed error:error];
    return object;
}

+ (id)objectFromValue:(id)sourceObject withMappings:(NSMutableDictionary*)mappings reversed:(BOOL)reversed error:(NSError**)error{
    NSMutableDictionary* def = [self objectDefinition:mappings];
    id result = nil;
    if(def != nil){
        result = [self createObjectOfClass:[self objectClass:def defaultClass:nil] withObject:sourceObject withMappings:[self mappingsDefinition:def] reversed:(reversed || [self reverseMappings:def]) error:error];
    }
    else{
        NSString* className = [mappings objectForKey:CKMappingClassKey];
        if(className){
            Class c = NSClassFromString(className);
            result = [self createObjectOfClass:c withObject:sourceObject withMappings:mappings reversed:NO error:error];
        }
    }
    
    if(*error)
        return nil;

    return result;
}

- (void)setupWithObject:(id)sourceObject withMappings:(NSMutableDictionary*)mappings error:(NSError**)error{
    [self setupWithObject:sourceObject withMappings:mappings reversed:NO error:error];
}

- (void)setupPropertyWithKeyPath:(NSString*)keyPath fromValue:(id)other keyPath:(NSString*)otherKeyPath withOptions:(NSMutableDictionary*)options reversed:(BOOL)reversed error:(NSError**)error{
    if(*error)
        return;
        
    if([self isSelf:keyPath])
        keyPath = nil;
    if([self isSelf:otherKeyPath])
        otherKeyPath = nil;
    
    id value = other;
    if(otherKeyPath != nil && [otherKeyPath length] > 0){
        value = [other valueForKeyPath:otherKeyPath];
    }
    
    //Source value validation
    CKObjectProperty* property = [CKObjectProperty propertyWithObject:self keyPath:keyPath];//THIS WORKS NOT FOR DICTIONARIES AS TARGET ...
    if(value == nil || [value isKindOfClass:[NSNull class]]){
        if([self isRequired:options]){
            NSString* details = [NSString stringWithFormat:@"Missing requiered value with keyPath : '%@' in source value : %@",otherKeyPath,other];
            *error = [NSError errorWithDomain:CKMappingErrorDomain code:CKMappingErrorCodeMissingRequieredValue 
                                     userInfo:[NSDictionary dictionaryWithObjectsAndKeys:details,CKMappingErrorDetailsKey, nil]];
            return;
        }
        else{
            [NSValueTransformer transform:[self defaultValue:options] inProperty:property];
        }
    }
    //Source is ok => apply to target
    else{
        Class targetType = [property type];
        
        //property is a collection
        if([NSObject isKindOf:targetType parentType:[NSArray class]] || [NSObject isKindOf:targetType parentType:[CKDocumentCollection class]]){
            NSMutableDictionary* subObjectDefinition = [self objectDefinition:options];
            
            CKModelObjectPropertyMetaData* metaData = [property metaData];
            Class contentType = [self objectClass:subObjectDefinition defaultClass:[metaData contentType]];
           
            id subObjectMappings = [self mappingsDefinition:subObjectDefinition];
            if(!subObjectMappings && contentType != nil){
                subObjectMappings = [options dictionaryForClass:contentType];
            }
            else if((contentType == nil || contentType == [metaData contentType]) && subObjectMappings){
                NSString* className = [subObjectMappings objectForKey:CKMappingClassKey];
                if(className){
                    contentType = NSClassFromString(className);
                }
            }
            
            if(contentType == nil){
                NSString* details = [NSString stringWithFormat:@"Could not find any valid class to create an object in property : %@",property];
                NSString* details2 = [NSString stringWithFormat:@"The class could be defined in JSON object definition using '%@' or in property metaData",CKMappingClassKey];
                *error = [NSError errorWithDomain:CKMappingErrorDomain code:CKMappingErrorCodeInvalidObjectClass 
                                         userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%@\n%@",details,details2],CKMappingErrorDetailsKey, nil]];
                return;
            }
            
            if([self needsToBeCleared:options]){
                [property removeAllObjects];
            }
            
            NSArray* ar = nil;
            if([value isKindOfClass:[NSArray class]]){
                ar = value;
            }
            else if([value isKindOfClass:[CKDocumentCollection class]]){
                CKDocumentCollection* collection = (CKDocumentCollection*)value;
                ar = [collection allObjects];
            }
            
            NSArray* results = nil;
            if(subObjectMappings){
                NSMutableArray* createdObjects = [NSMutableArray array];
                for(id sourceSubObject in ar){
                    //create sub object
                    id targetSubObject = [[[contentType alloc]init]autorelease];
                    //map sub object
                    [targetSubObject setupWithObject:sourceSubObject withMappings:subObjectMappings reversed:([self reverseMappings:subObjectMappings] || reversed) error:error];
                    //adds sub object
                    [createdObjects addObject:targetSubObject];
                }
                results = createdObjects;
            }
            else{
                results = ar;
            }
            
            //feed the collection with results
            if([self insertAtBegin:options]){
                [property insertObjects:results atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,[results count])]];
            }
            else{
                [property insertObjects:results atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange([property count],[results count])]];
            }

        }
        //property is an object or a simple property
        else{
            SEL transformSelector = [self transformSelector:options];
            CKCallback* callback = [self transformCallback:options];
            if(callback){
                id transformedValue = [callback execute:value];
                [property setValue:transformedValue];
            }
            else if(transformSelector){
                Class transformSelectorClass = [self transformClass:options defaultClass:targetType];
                id transformedValue = [transformSelectorClass performSelector:transformSelector withObject:value];
                [property setValue:transformedValue];
            }
            else{
                NSMutableDictionary* subObjectDefinition = [self objectDefinition:options];
                Class contentType = [self objectClass:subObjectDefinition defaultClass:[property type]];
                                
                id subObjectMappings = [self mappingsDefinition:subObjectDefinition];
                if(!subObjectMappings && contentType){
                    subObjectMappings = [options dictionaryForClass:contentType];
                }
                else if((contentType == nil || contentType == [property type]) && subObjectMappings){
                    NSString* className = [subObjectMappings objectForKey:CKMappingClassKey];
                    if(className){
                        contentType = NSClassFromString(className);
                    }
                }
                                
                if(subObjectMappings && ![subObjectMappings isEmpty]){
                    id subObject = [property value];
                    if([subObject isKindOfClass:contentType]){
                        [subObject setupWithObject:value withMappings:subObjectMappings reversed:([self reverseMappings:subObjectMappings] || reversed) error:error];
                    }
                    else{
                        subObject = [[[contentType alloc]init]autorelease];
                        [subObject setupWithObject:value withMappings:subObjectMappings reversed:([self reverseMappings:subObjectMappings] || reversed) error:error];
                        [property setValue:subObject];
                    }
                }
                else{
                    [NSValueTransformer transform:value inProperty:property];
                }
            }
        }
    }
}

- (void)setupWithObject:(id)sourceObject withMappings:(NSMutableDictionary*)mappings reversed:(BOOL)reversed error:(NSError**)error{
    if(*error)
        return;
    
    if(mappings){
        for(NSString* targetKeyPath in [mappings allKeys]){
            if([mappings isReservedKeyWord:targetKeyPath]
               || [targetKeyPath isEqualToString:CKMappingClassKey]
               || [targetKeyPath isEqualToString:CKMappingObjectKey]
               || [targetKeyPath isEqualToString:CKMappingMappingsKey]
               || [targetKeyPath isEqualToString:CKMappingMappingsKey]
               || [targetKeyPath isEqualToString:CKMappingReverseMappingsKey]
               || [targetKeyPath isEqualToString:CKMappingtargetKeyPathKey]
               || [targetKeyPath isEqualToString:CKMappingRequieredKey]
               || [targetKeyPath isEqualToString:CKMappingDefaultValueKey]
               || [targetKeyPath isEqualToString:CKMappingTransformSelectorKey]
               || [targetKeyPath isEqualToString:CKMappingTransformSelectorClassKey]
               || [targetKeyPath isEqualToString:CKMappingTransformCallbackKey]
               || [targetKeyPath isEqualToString:CKMappingClearContainerKey]
               || [targetKeyPath isEqualToString:CKMappingInsertAtBeginKey]){
                continue;
            }
            
            id targetObject = [mappings objectForKey:targetKeyPath];
            if([targetObject isKindOfClass:[NSString class]]){
                if(reversed){
                    [self setupPropertyWithKeyPath:(NSString*)targetObject fromValue:sourceObject keyPath:targetKeyPath withOptions:nil reversed:reversed error:error];
                }
                else{
                    [self setupPropertyWithKeyPath:targetKeyPath fromValue:sourceObject keyPath:(NSString*)targetObject withOptions:nil reversed:reversed error:error];
                }
            }
            else if([targetObject isKindOfClass:[NSDictionary class]]){
                if(reversed){
                    [self setupPropertyWithKeyPath:[self keyPath:targetObject] fromValue:sourceObject keyPath:targetKeyPath withOptions:targetObject reversed:reversed error:error];
                }
                else{
                    [self setupPropertyWithKeyPath:targetKeyPath fromValue:sourceObject keyPath:[self keyPath:targetObject] withOptions:targetObject reversed:reversed error:error];
                }
            }
            
            if(*error)
                return;
        }
    }
}


@end

//CKMappingManager

static CKMappingManager* CKMappingManagerDefault = nil;

@implementation CKMappingManager

+ (CKMappingManager*)defaultManager{
	if(CKMappingManagerDefault == nil){
		CKMappingManagerDefault = [[CKMappingManager alloc]init];
	}
	return CKMappingManagerDefault;
}



- (NSMutableDictionary*)mappingsForObject:(id)object propertyName:(NSString*)propertyName{
	return [self dictionaryForObject:object propertyName:propertyName];
}

- (NSMutableDictionary*)mappingsForIdentifier:(id)identifier{
    if(identifier == nil)
        return nil;
    return [self dictionaryForKey:identifier];
}

- (void)loadContentOfFileNamed:(NSString*)name{
	NSString* path = [[NSBundle mainBundle]pathForResource:name ofType:@"mappings"];
	[self loadContentOfFile:path];
}

- (BOOL)importContentOfFileNamed:(NSString*)name{
	NSString* path = [[NSBundle mainBundle]pathForResource:name ofType:@"mappings"];
	return [self appendContentOfFile:path];
}

- (id)objectFromValue:(id)sourceObject withMappings:(NSMutableDictionary*)mappings reversed:(BOOL)reversed error:(NSError**)error{
    return [NSObject objectFromValue:sourceObject withMappings:mappings reversed:reversed error:error];
}

- (id)objectFromValue:(id)sourceObject withMappingsIdentifier:(id)identifier reversed:(BOOL)reversed error:(NSError**)error{
    return [NSObject objectFromValue:sourceObject withMappings:[self mappingsForIdentifier:identifier] reversed:reversed error:error];
}

@end


@interface CKMappingContext()
@property(nonatomic,retain)NSMutableDictionary* dictionary;
- (id)initWithDictionary:(NSMutableDictionary*)dictionary identifier:(id)theidentifier;
@end


@implementation CKMappingContext
@synthesize  dictionary = _dictionary;
@synthesize  identifier = _identifier;

- (id)initWithDictionary:(NSMutableDictionary*)thedictionary identifier:(id)theidentifier{
    self = [super init];
    self.dictionary = thedictionary;
    self.identifier = theidentifier;
    return self;
}

- (void)dealloc{
    [_dictionary release];
    _dictionary = nil;
    [_identifier release];
    _identifier = nil;
    [super dealloc];
}

+ (void)loadContentOfFileNamed:(NSString*)name{
    [[CKMappingManager defaultManager]loadContentOfFileNamed:name];
}

+ (CKMappingContext*)contextWithIdentifier:(id)identifier{
    NSMutableDictionary* dico = [[CKMappingManager defaultManager]mappingsForIdentifier:identifier];
    if(dico){
        return [[[CKMappingContext alloc]initWithDictionary:dico identifier:identifier]autorelease];
    }
    return [[[CKMappingContext alloc]initWithDictionary:[NSMutableDictionary dictionary] identifier:identifier]autorelease];
}

+ (void)clearMappingsContextWithIdentifier:(id)identifier{
    [[CKMappingManager defaultManager]removeDictionaryForKey:identifier];
}

- (BOOL)isEmpty{
    return [[self dictionary]isEmpty];
}

- (NSMutableDictionary*)arrayDefinitionWithMappings:(NSMutableDictionary*)mappings objectClass:(Class)type{
    NSMutableDictionary* dico = [NSMutableDictionary dictionary];
    [dico setObject:@"NSMutableArray" forKey:CKMappingClassKey];
    NSMutableDictionary* selfDefinition = [NSMutableDictionary dictionary];
    [selfDefinition setObject:CKMappingSelfKey forKey:CKMappingtargetKeyPathKey];
    NSMutableDictionary* objectDefinition = [NSMutableDictionary dictionary];
    if(type){
        [objectDefinition setObject:[type description] forKey:CKMappingClassKey];
    }
    [objectDefinition setObject:mappings forKey:CKMappingMappingsKey];
    [selfDefinition setObject:objectDefinition forKey:CKMappingObjectKey];
    [dico setObject:selfDefinition forKey:CKMappingSelfKey];
    return dico;
}

//ARRAYS

- (NSArray*)objectsFromValue:(id)value ofClass:(Class)type error:(NSError**)error{
    return (NSArray*)[self objectsFromValue:value ofClass:type reversed:NO error:error];
}

- (NSArray*)objectsFromValue:(id)value ofClass:(Class)type reversed:(BOOL)reversed error:(NSError**)error{
    if(![value isKindOfClass:[NSArray class]] && ![value isKindOfClass:[CKDocumentCollection class]]){
        *error = [NSError errorWithDomain:CKMappingErrorDomain code:CKMappingErrorCodeInvalidSourceData 
                                 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"'value' must be a NSArray or a CKDocumentCollection",CKMappingErrorDetailsKey, nil]];
        return nil;
    }
    return [NSObject objectFromValue:value withMappings:[self arrayDefinitionWithMappings:[self dictionary] objectClass:type] reversed:reversed error:error];
}

- (NSArray*)objectsFromValue:(id)value error:(NSError**)error{
    return [self objectsFromValue:(id)value ofClass:nil error:error];
}

- (NSArray*)objectsFromValue:(id)value reversed:(BOOL)reversed error:(NSError**)error{
    return [self objectsFromValue:(id)value ofClass:nil reversed:reversed error:error];
}

//OBJECT
- (id)objectFromValue:(id)value error:(NSError**)error{
    return [self objectFromValue:value reversed:NO error:error];
}

- (id)objectFromValue:(id)value reversed:(BOOL)reversed error:(NSError**)error{
    /*if(![value isKindOfClass:[NSDictionary class]]){
        *error = [NSError errorWithDomain:CKMappingErrorDomain code:CKMappingErrorCodeInvalidSourceData 
                                 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"'value' must be a NSDictionary",CKMappingErrorDetailsKey, nil]];
        return nil;
    }*/
    return [[CKMappingManager defaultManager]objectFromValue:value withMappings:[self dictionary] reversed:reversed error:error];
}

- (id)objectFromValue:(id)value ofClass:(Class)type error:(NSError**)error{
    return [self objectFromValue:value ofClass:type reversed:NO error:error];
}

- (id)objectFromValue:(id)value ofClass:(Class)type reversed:(BOOL)reversed error:(NSError**)error{
    if(![value isKindOfClass:[NSDictionary class]]){
        *error = [NSError errorWithDomain:CKMappingErrorDomain code:CKMappingErrorCodeInvalidSourceData 
                                 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"'value' must be a NSDictionary",CKMappingErrorDetailsKey, nil]];
        return nil;
    }
    id object = [[[type alloc]init] autorelease];
    [self mapValue:value toObject:object reversed:reversed error:error];
    return object;
}

//INSTANCE
- (id)mapValue:(id)value toObject:(id)object error:(NSError**)error{
    return [self mapValue:value toObject:object reversed:NO error:error];
}

- (id)mapValue:(id)value toObject:(id)object reversed:(BOOL)reversed error:(NSError**)error{
    [object setupWithObject:value withMappings:[self dictionary] reversed:reversed error:error];
    return object;
}


//SETUP
- (void)setObjectClass:(Class)type{
    NSMutableDictionary* dictionary = [self  dictionary];
    [dictionary setObject:[type description] forKey:CKMappingClassKey];
}

- (void)setKeyPath:(NSString*)keyPath fromKeyPath:(NSString*)sourceKeyPath{
    NSMutableDictionary* dictionary = [self  dictionary];
    [dictionary setObject:sourceKeyPath forKey:keyPath];
}

- (void)setKeyPath:(NSString*)keyPath fromKeyPath:(NSString*)sourceKeyPath transformBlock:(id(^)(id source))transformBlock{
    NSMutableDictionary* dictionary = [self  dictionary];
    NSMutableDictionary* mapping = [NSMutableDictionary dictionary];
    [mapping setObject:sourceKeyPath forKey:CKMappingtargetKeyPathKey];
    [mapping setObject:[CKCallback callbackWithBlock:transformBlock] forKey:CKMappingTransformCallbackKey];
    [dictionary setObject:mapping forKey:keyPath];
}

- (void)setKeyPath:(NSString*)keyPath fromKeyPath:(NSString*)sourceKeyPath transformTarget:(id)target action:(SEL)action{
    NSMutableDictionary* dictionary = [self  dictionary];
    NSMutableDictionary* mapping = [NSMutableDictionary dictionary];
    [mapping setObject:sourceKeyPath forKey:CKMappingtargetKeyPathKey];
    [mapping setObject:[CKCallback callbackWithTarget:target action:action] forKey:CKMappingTransformCallbackKey];
    [dictionary setObject:mapping forKey:keyPath];
}

- (void)setKeyPath:(NSString*)keyPath fromKeyPath:(NSString*)sourceKeyPath defaultValue:(id)value{
    NSMutableDictionary* dictionary = [self  dictionary];
    NSMutableDictionary* mapping = [NSMutableDictionary dictionary];
    [mapping setObject:sourceKeyPath forKey:CKMappingtargetKeyPathKey];
    [mapping setObject:value forKey:CKMappingDefaultValueKey];
    [dictionary setObject:mapping forKey:keyPath];
}

- (void)setKeyPath:(NSString*)keyPath fromKeyPath:(NSString*)sourceKeyPath defaultValue:(id)value transformBlock:(id(^)(id source))transformBlock{
    NSMutableDictionary* dictionary = [self dictionary];
    NSMutableDictionary* mapping = [NSMutableDictionary dictionary];
    [mapping setObject:sourceKeyPath forKey:CKMappingtargetKeyPathKey];
    [mapping setObject:[CKCallback callbackWithBlock:transformBlock] forKey:CKMappingTransformCallbackKey];
    [mapping setObject:value forKey:CKMappingDefaultValueKey];
    [dictionary setObject:mapping forKey:keyPath];
}

- (void)setKeyPath:(NSString*)keyPath fromKeyPath:(NSString*)sourceKeyPath defaultValue:(id)value transformTarget:(id)target action:(SEL)action{
    NSMutableDictionary* dictionary = [self  dictionary];
    NSMutableDictionary* mapping = [NSMutableDictionary dictionary];
    [mapping setObject:sourceKeyPath forKey:CKMappingtargetKeyPathKey];
    [mapping setObject:[CKCallback callbackWithTarget:target action:action] forKey:CKMappingTransformCallbackKey];
    [mapping setObject:value forKey:CKMappingDefaultValueKey];
    [dictionary setObject:mapping forKey:keyPath];
}

- (void)setKeyPath:(NSString*)keyPath fromKeyPath:(NSString*)sourceKeyPath requiered:(BOOL)requiered{
    NSMutableDictionary* dictionary = [self  dictionary];
    NSMutableDictionary* mapping = [NSMutableDictionary dictionary];
    [mapping setObject:sourceKeyPath forKey:CKMappingtargetKeyPathKey];
    [mapping setObject:[NSNumber numberWithBool:requiered] forKey:CKMappingRequieredKey];
    [dictionary setObject:mapping forKey:keyPath];
}

- (void)setKeyPath:(NSString*)keyPath fromKeyPath:(NSString*)sourceKeyPath requiered:(BOOL)requiered transformBlock:(id(^)(id source))transformBlock{
    NSMutableDictionary* dictionary = [self dictionary];
    NSMutableDictionary* mapping = [NSMutableDictionary dictionary];
    [mapping setObject:sourceKeyPath forKey:CKMappingtargetKeyPathKey];
    [mapping setObject:[CKCallback callbackWithBlock:transformBlock] forKey:CKMappingTransformCallbackKey];
    [mapping setObject:[NSNumber numberWithBool:requiered] forKey:CKMappingRequieredKey];
    [dictionary setObject:mapping forKey:keyPath];
}

- (void)setKeyPath:(NSString*)keyPath fromKeyPath:(NSString*)sourceKeyPath requiered:(BOOL)requiered transformTarget:(id)target action:(SEL)action{
    NSMutableDictionary* dictionary = [self  dictionary];
    NSMutableDictionary* mapping = [NSMutableDictionary dictionary];
    [mapping setObject:sourceKeyPath forKey:CKMappingtargetKeyPathKey];
    [mapping setObject:[CKCallback callbackWithTarget:target action:action] forKey:CKMappingTransformCallbackKey];
    [mapping setObject:[NSNumber numberWithBool:requiered] forKey:CKMappingRequieredKey];
    [dictionary setObject:mapping forKey:keyPath];
}

- (void)setKeyPath:(NSString*)keyPath fromKeyPath:(NSString*)sourceKeyPath objectClass:(Class)objectClass withMappingsContextIdentifier:(id)contextIdentifier{
    NSMutableDictionary* dictionary = [self  dictionary];
    NSMutableDictionary* mapping = [NSMutableDictionary dictionary];
    [mapping setObject:sourceKeyPath forKey:CKMappingtargetKeyPathKey];
    NSMutableDictionary* objectDefinition = [NSMutableDictionary dictionary];
    [mapping setObject:objectDefinition forKey:CKMappingObjectKey];
    [objectDefinition setObject:[objectClass description] forKey:CKMappingClassKey];
    [objectDefinition setObject:contextIdentifier forKey:CKMappingMappingsKey];
    [dictionary setObject:mapping forKey:keyPath];
}

- (void)setKeyPath:(NSString*)keyPath fromKeyPath:(NSString*)sourceKeyPath requiered:(BOOL)requiered objectClass:(Class)objectClass withMappingsContextIdentifier:(id)contextIdentifier{
    NSMutableDictionary* dictionary = [self  dictionary];
    NSMutableDictionary* mapping = [NSMutableDictionary dictionary];
    [mapping setObject:sourceKeyPath forKey:CKMappingtargetKeyPathKey];
    [mapping setObject:[NSNumber numberWithBool:requiered] forKey:CKMappingRequieredKey];
    NSMutableDictionary* objectDefinition = [NSMutableDictionary dictionary];
    [mapping setObject:objectDefinition forKey:CKMappingObjectKey];
    [objectDefinition setObject:[objectClass description] forKey:CKMappingClassKey];
    [objectDefinition setObject:contextIdentifier forKey:CKMappingMappingsKey];
    [dictionary setObject:mapping forKey:keyPath];
}

- (void)setKeyPath:(NSString*)keyPath fromKeyPath:(NSString*)sourceKeyPath  withMappingsContextIdentifier:(id)contextIdentifier{
    NSMutableDictionary* dictionary = [self  dictionary];
    NSMutableDictionary* mapping = [NSMutableDictionary dictionary];
    [mapping setObject:sourceKeyPath forKey:CKMappingtargetKeyPathKey];
    NSMutableDictionary* objectDefinition = [NSMutableDictionary dictionary];
    [mapping setObject:objectDefinition forKey:CKMappingObjectKey];
    [objectDefinition setObject:contextIdentifier forKey:CKMappingMappingsKey];
    [dictionary setObject:mapping forKey:keyPath];
}

- (void)setKeyPath:(NSString*)keyPath fromKeyPath:(NSString*)sourceKeyPath requiered:(BOOL)requiered  withMappingsContextIdentifier:(id)contextIdentifier{
    NSMutableDictionary* dictionary = [self  dictionary];
    NSMutableDictionary* mapping = [NSMutableDictionary dictionary];
    [mapping setObject:sourceKeyPath forKey:CKMappingtargetKeyPathKey];
    [mapping setObject:[NSNumber numberWithBool:requiered] forKey:CKMappingRequieredKey];
    NSMutableDictionary* objectDefinition = [NSMutableDictionary dictionary];
    [mapping setObject:objectDefinition forKey:CKMappingObjectKey];
    [objectDefinition setObject:contextIdentifier forKey:CKMappingMappingsKey];
    [dictionary setObject:mapping forKey:keyPath];
}

@end