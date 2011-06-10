//
//  CKUIView+Style.m
//  CloudKit
//
//  Created by Sebastien Morel on 11-04-20.
//  Copyright 2011 WhereCloud Inc. All rights reserved.
//

#import "CKUIView+Style.h"
#import "CKStyles.h"
#import "CKStyleManager.h"
#import "CKStyle+Parsing.h"

#import "CKTableViewCellController+Style.h"
#import "CKUILabel+Style.h"
#import "CKUIImageView+Style.h"
#import "CKLocalization.h"

#import "CKTextView.h"
NSMutableSet* reserverKeyWords = nil;

NSString* CKStyleBackgroundColor = @"backgroundColor";
NSString* CKStyleBackgroundGradientColors = @"backgroundGradientColors";
NSString* CKStyleBackgroundGradientLocations = @"backgroundGradientLocations";
NSString* CKStyleBackgroundImage = @"backgroundImage";
NSString* CKStyleCornerStyle = @"cornerStyle";
NSString* CKStyleCornerSize = @"cornerSize";
NSString* CKStyleAlpha = @"alpha";
NSString* CKStyleBorderColor = @"borderColor";
NSString* CKStyleBorderWidth = @"borderWidth";
NSString* CKStyleBorderStyle = @"borderStyle";
NSString* CKStyleBackgroundImageContentMode = @"backgroundImageContentMode";


@implementation NSMutableDictionary (CKViewStyle)

- (UIColor*)backgroundColor{
	return [self colorForKey:CKStyleBackgroundColor];
}

- (NSArray*)backgroundGradientColors{
	return [self colorArrayForKey:CKStyleBackgroundGradientColors];
}

- (NSArray*)backgroundGradientLocations{
	return [self cgFloatArrayForKey:CKStyleBackgroundGradientLocations];
}

- (UIImage*)backgroundImage{
	return [self imageForKey:CKStyleBackgroundImage];
} 

- (UIViewContentMode)backgroundImageContentMode{
	return (UIViewContentMode)[self enumValueForKey:CKStyleBackgroundImageContentMode 
									 withDictionary:CKEnumDictionary(UIViewContentModeScaleToFill,
																	 UIViewContentModeScaleAspectFit,
																	 UIViewContentModeScaleAspectFill,
																	 UIViewContentModeRedraw,
																	 UIViewContentModeCenter,
																	 UIViewContentModeTop,
																	 UIViewContentModeBottom,
																	 UIViewContentModeLeft,
																	 UIViewContentModeRight,
																	 UIViewContentModeTopLeft,
																	 UIViewContentModeTopRight,
																	 UIViewContentModeBottomLeft,
																	 UIViewContentModeBottomRight)];
							   
}

- (CKViewCornerStyle)cornerStyle{
	return (CKViewCornerStyle)[self enumValueForKey:CKStyleCornerStyle 
									 withDictionary:CKEnumDictionary(CKViewCornerStyleDefault, 
																	 CKViewCornerStyleRounded,
																	 CKViewCornerStyleRoundedTop,
																	 CKViewCornerStyleRoundedBottom, 
																	 CKViewCornerStylePlain)];
}

- (CGFloat)cornerSize{
	return [self cgFloatForKey:CKStyleCornerSize];
}

- (CGFloat)alpha{
	return [self cgFloatForKey:CKStyleAlpha];
}

- (UIColor*)borderColor{
	return [self colorForKey:CKStyleBorderColor];
}

- (CGFloat)borderWidth{
	return [self cgFloatForKey:CKStyleBorderWidth];
}

- (CKViewBorderStyle)borderStyle{
	return (CKViewBorderStyle)[self enumValueForKey:CKStyleBorderStyle 
									 withDictionary:CKEnumDictionary(CKViewBorderStyleDefault,
																	 CKViewBorderStyleAll,
																	 CKViewBorderStyleNone)];
}

@end

@implementation UIView (CKStyle)

+ (CKGradientView*)gradientView:(UIView*)view{
	if([view isKindOfClass:[CKGradientView class]])
		return (CKGradientView*)view;
	
	for(UIView* subView in [view subviews]){
		if([subView isKindOfClass:[CKGradientView class]])
			return (CKGradientView*)subView;
	}
	return nil;
}

+ (BOOL)needSubView:(NSMutableDictionary*)style forView:(UIView*)view{
	if(style == nil || [style isEmpty] == YES)
		return NO;
	
	if([style containsObjectForKey:CKStyleBackgroundGradientColors]
	   || [style containsObjectForKey:CKStyleCornerStyle]
	   || [style containsObjectForKey:CKStyleBackgroundImage]
	   || [style containsObjectForKey:CKStyleBorderColor]){
		return YES;
	}
	return NO;
}

- (void)applyStyle:(NSMutableDictionary*)style{
	[self applyStyle:style propertyName:nil];
}

- (void)applyStyle:(NSMutableDictionary*)style propertyName:(NSString*)propertyName{
	NSMutableDictionary* myViewStyle = [style styleForObject:self propertyName:propertyName];
	[[self class] applyStyle:myViewStyle toView:self appliedStack:[NSMutableSet set] delegate:nil];
}

+ (BOOL)applyStyle:(NSMutableDictionary*)style toView:(UIView*)view propertyName:(NSString*)propertyName appliedStack:(NSMutableSet*)appliedStack{
	NSMutableDictionary* myViewStyle = [style styleForObject:view propertyName:propertyName];
	return [[view class] applyStyle:myViewStyle toView:view appliedStack:appliedStack  delegate:nil];
}

+ (void)updateReservedKeyWords:(NSMutableSet*)keyWords{
	[keyWords addObjectsFromArray:[NSArray arrayWithObjects:CKStyleBackgroundColor,CKStyleBackgroundGradientColors,CKStyleBackgroundGradientLocations,CKStyleBackgroundImageContentMode,
								   CKStyleBackgroundImage,CKStyleCornerStyle,CKStyleCornerSize,CKStyleAlpha,CKStyleBorderColor,CKStyleBorderWidth,CKStyleBorderStyle,nil]];
}

+ (BOOL)applyStyle:(NSMutableDictionary*)style toView:(UIView*)view appliedStack:(NSMutableSet*)appliedStack
                   delegate:(id)delegate {
	if(view == nil)
		return NO;
	
	NSMutableDictionary* myViewStyle = style;
	if([appliedStack containsObject:view] == NO){
		[appliedStack addObject:view];
		//Apply before adding background subView
		[view applySubViewsStyle:myViewStyle appliedStack:appliedStack delegate:delegate];
	
		if(myViewStyle){
			if([myViewStyle isEmpty] == NO){
				UIView* backgroundView = view;
				BOOL opaque = YES;
				
				CKRoundedCornerViewType roundedCornerType = CKRoundedCornerViewTypeNone;
				CKGradientViewBorderType viewBorderType = CKGradientViewBorderTypeNone;
				
				if([UIView needSubView:myViewStyle forView:view]){
					CKGradientView* gradientView = [UIView gradientView:view];
					if(gradientView == nil){
						gradientView = [[[CKGradientView alloc]initWithFrame:view.bounds]autorelease];
						gradientView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
						view.backgroundColor = [UIColor clearColor];
						[view insertSubview:gradientView atIndex:0];
					}
		
					backgroundView = gradientView;
				}
				
				//backgroundView.opaque = YES;
				
				if([backgroundView isKindOfClass:[CKGradientView class]]){
					CKGradientView* gradientView = (CKGradientView*)backgroundView;
					
					//Apply Background Image
					if([myViewStyle containsObjectForKey:CKStyleBackgroundImage]){
						gradientView.image = [myViewStyle backgroundImage];
						//opaque = NO;
					}
					
					if([myViewStyle containsObjectForKey:CKStyleBackgroundImageContentMode]){
						gradientView.imageContentMode = [myViewStyle backgroundImageContentMode];
					}
					
					//Apply Gradient
					if([myViewStyle containsObjectForKey:CKStyleBackgroundGradientColors]){
						NSArray* colors = [myViewStyle backgroundGradientColors];
						for(UIColor* color in colors){
							if(CGColorGetAlpha([color CGColor]) < 1){
								opaque = NO;
								break;
							}
						}
						gradientView.gradientColors = colors;
					}
					if([myViewStyle containsObjectForKey:CKStyleBackgroundGradientLocations]){
						gradientView.gradientColorLocations = [myViewStyle backgroundGradientLocations];
					}
					
					//Apply corners
					{
						CKViewCornerStyle cornerStyle = CKViewCornerStyleDefault;
						if([myViewStyle containsObjectForKey:CKStyleCornerStyle]){
							cornerStyle = [myViewStyle cornerStyle];
						}
						
						if(cornerStyle == CKViewCornerStyleDefault && delegate && [delegate respondsToSelector:@selector(view:cornerStyleWithStyle:)]){
							roundedCornerType = [delegate view:gradientView cornerStyleWithStyle:myViewStyle];
						}
						else{
							switch(cornerStyle){
								case CKViewCornerStyleRounded:{
									roundedCornerType = CKRoundedCornerViewTypeAll;
									break;
								}
								case CKViewCornerStyleRoundedTop:{
									roundedCornerType = CKRoundedCornerViewTypeTop;
									break;
								}
								case CKViewCornerStyleRoundedBottom:{
									roundedCornerType = CKRoundedCornerViewTypeBottom;
									break;
								}
							}
						}
						gradientView.corners = roundedCornerType;
					}
					
					//Apply BorderStyle
					{
						CKViewBorderStyle borderStyle = CKViewBorderStyleDefault;
						if([myViewStyle containsObjectForKey:CKStyleBorderStyle]){
							borderStyle = [myViewStyle borderStyle];
						}
						
						if(borderStyle == CKViewCornerStyleDefault && delegate && [delegate respondsToSelector:@selector(view:borderStyleWithStyle:)]){
							viewBorderType = [delegate view:gradientView borderStyleWithStyle:myViewStyle];
						}
						else{
							switch(borderStyle){
								case CKViewBorderStyleAll:{
									viewBorderType = CKGradientViewBorderTypeAll;
									break;
								}
								case CKViewBorderStyleNone:{
									viewBorderType = CKGradientViewBorderTypeNone;
									break;
								}
							}
						}
						gradientView.borderStyle = viewBorderType;
					}
					
					if([myViewStyle containsObjectForKey:CKStyleCornerSize]){
						gradientView.roundedCornerSize = [myViewStyle cornerSize];
					}	
					
					if([myViewStyle containsObjectForKey:CKStyleBorderColor]){
						gradientView.borderColor = [myViewStyle borderColor];
					}	
					
					if([myViewStyle containsObjectForKey:CKStyleBorderWidth]){
						gradientView.borderWidth = [myViewStyle borderWidth];
					}
					
					[gradientView setNeedsDisplay];
				}
				
				//Apply transparency
				if([myViewStyle containsObjectForKey:CKStyleAlpha]){
					backgroundView.alpha = [myViewStyle alpha];
				}
				
				//Apply color
				BOOL dontTouchBackgroundColor = NO;
				if([myViewStyle containsObjectForKey:CKStyleBackgroundColor] == YES){
					dontTouchBackgroundColor = YES;
					backgroundView.backgroundColor = [myViewStyle backgroundColor];
					CGFloat alpha = CGColorGetAlpha([backgroundView.backgroundColor CGColor]);
					opaque = opaque && (alpha >= 1);
				}
				
				if(dontTouchBackgroundColor == NO && (roundedCornerType != CKRoundedCornerViewTypeNone)){
					backgroundView.backgroundColor = [UIColor clearColor];
				}
				
				/*BOOL colorOpaque = (opaque == YES && (roundedCornerType == CKRoundedCornerViewTypeNone));
				if(dontTouchBackgroundColor == NO){
					//backgroundView.backgroundColor = [UIColor clearColor];
					backgroundView.backgroundColor = [UIColor redColor];
				}*/
			}
		}
		return YES;
	}
	return NO;
}


@end


@implementation NSObject (CKStyle)

+ (void)updateReservedKeyWords:(NSMutableSet*)keyWords{
	[keyWords addObjectsFromArray:[NSArray arrayWithObjects: CKStyleFormats,CKStyleParentStyle,CKStyleEmptyStyle,CKStyleInherits,CKStyleImport,nil]];
}

+ (void)applyStyleByIntrospection:(NSMutableDictionary*)style toObject:(id)object{
	if(reserverKeyWords == nil){
		reserverKeyWords = [[NSMutableSet set]retain];
	}
	
	[[self class]updateReservedKeyWords:reserverKeyWords];
	
	NSArray* allPropertyNames = [object allPropertyNames];
	for(NSString* key in [style allKeys]){
		if([reserverKeyWords containsObject:key] == NO
		   && [allPropertyNames containsObject:key] == YES){
			CKClassPropertyDescriptor* descriptor = [object propertyDescriptorForKeyPath:key];
			if(descriptor != nil && [NSObject isKindOf:descriptor.type parentType:[UIView class]] == NO){
				[style setObjectForKey:key inProperty:[CKObjectProperty propertyWithObject:object keyPath:key]];
			}
		}
	}
}

//FIXME : something not optimial here as we retrieve myViewStyle which is done also in applyStyle
- (void)applySubViewsStyle:(NSMutableDictionary*)style appliedStack:(NSMutableSet*)appliedStack delegate:(id)delegate{
	if(style == nil)
		return;
	
	
	//iterate on view properties to apply style using property names
	NSArray* properties = [self allViewsPropertyDescriptors];
	for(CKClassPropertyDescriptor* descriptor in properties){
		UIView* view = [self valueForKey:descriptor.name];

		UIView* referenceView = (view != nil) ? view : (([self isKindOfClass:[UIView class]] == YES) ? (UIView*)self : nil);
		CGRect frame = (referenceView != nil) ? referenceView.bounds : CGRectMake(0,0,100,100);
		
		NSMutableDictionary* myViewStyle = [style styleForObject:view propertyName:descriptor.name];
		//if(myViewStyle != nil && [myViewStyle isEmpty] == NO){
			BOOL shouldReplaceView = NO;
			if(delegate && [delegate respondsToSelector:@selector(object:shouldReplaceViewWithDescriptor:withStyle:)]){
				shouldReplaceView = [delegate object:self shouldReplaceViewWithDescriptor:descriptor withStyle:myViewStyle];
			}
			
			if(([UIView needSubView:myViewStyle forView:view] && view == nil) || (shouldReplaceView && (view == nil || [view isKindOfClass:[CKGradientView class]] == NO)) ){
				view = [[[CKGradientView alloc]initWithFrame:frame]autorelease];
				view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
				[self setValue:view forKey:descriptor.name];
			}
			
			if(view){
				[descriptor.type applyStyle:myViewStyle toView:view appliedStack:appliedStack delegate:delegate];
			}
		//}
	}
	
	if([self isKindOfClass:[UIView class]] == YES){
		UIView* selfView = (UIView*)self;
		for(UIView* view in [selfView subviews]){
			NSMutableDictionary* myViewStyle = [style styleForObject:view propertyName:nil];
			[[view class] applyStyle:myViewStyle toView:view appliedStack:appliedStack delegate:delegate];
		}
	}
	
	
	//if([appliedStack containsObject:self] == NO){
		[NSObject applyStyleByIntrospection:style toObject:self];
	//}
	[appliedStack addObject:self];
}


@end