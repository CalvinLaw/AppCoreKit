//
//  CKBindedMapViewController.h
//  CloudKit
//
//  Created by Olivier Collet on 10-08-20.
//  Copyright 2010 WhereCloud Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "CKItemViewContainerController.h"
#import "CKObjectController.h"
#import "CKItemViewControllerFactory.h"
#import "CKCollection.h"

#import "CKMapAnnotationController.h"

#define MAP_ANNOTATION_LEFT_BUTTON	1
#define MAP_ANNOTATION_RIGHT_BUTTON	2


/** TODO
 */
typedef enum CKBindedMapViewControllerZoomStrategy{
    CKBindedMapViewControllerZoomStrategyManual,
	CKBindedMapViewControllerZoomStrategyEnclosing,
	CKBindedMapViewControllerZoomStrategySmart
}CKBindedMapViewControllerZoomStrategy;


typedef enum CKBindedMapViewControllerSelectionStrategy{
    CKBindedMapViewControllerSelectionStrategyManual,
    CKBindedMapViewControllerSelectionStrategyAutoSelectAloneAnnotations
}CKBindedMapViewControllerSelectionStrategy;

@class CKBindedMapViewController;
typedef void(^CKBindedMapViewControllerSelectionBlock)(CKBindedMapViewController* controller, CKMapAnnotationController* annotationController);


/** TODO
 */
@interface CKBindedMapViewController : CKItemViewContainerController <MKMapViewDelegate> {
	CLLocationCoordinate2D _centerCoordinate;
	MKMapView *_mapView;
	
	CKBindedMapViewControllerZoomStrategy _zoomStrategy;
    BOOL _includeUserLocationWhenZooming;
	CGFloat _smartZoomDefaultRadius;
	NSInteger _smartZoomMinimumNumberOfAnnotations;
	
	id _annotationToSelect;
	id _nearestAnnotation;
}

@property (nonatomic, retain) IBOutlet MKMapView *mapView;
@property (nonatomic, assign, readwrite) NSArray *annotations;
@property (nonatomic, assign) CLLocationCoordinate2D centerCoordinate;

@property (nonatomic, assign) CKBindedMapViewControllerZoomStrategy zoomStrategy;
@property (nonatomic, assign) CKBindedMapViewControllerSelectionStrategy selectionStrategy;
@property (nonatomic, assign) CGFloat smartZoomDefaultRadius;
@property (nonatomic, assign) NSInteger smartZoomMinimumNumberOfAnnotations;
@property (nonatomic, assign) BOOL includeUserLocationWhenZooming;
@property (nonatomic, retain) id annotationToSelect;

@property (nonatomic, copy) CKBindedMapViewControllerSelectionBlock selectionBlock;
@property (nonatomic, copy) CKBindedMapViewControllerSelectionBlock deselectionBlock;


- (id)initWithAnnotations:(NSArray *)annotations atCoordinate:(CLLocationCoordinate2D)centerCoordinate;

- (void)panToCenterCoordinate:(CLLocationCoordinate2D)coordinate animated:(BOOL)animated;
- (void)zoomToCenterCoordinate:(CLLocationCoordinate2D)coordinate radius:(CGFloat)radius animated:(BOOL)animated;

/** 
 Zooms to a default radius of 500m
 @param coordinate The center coordinate
 @param animated Animates the zoom
 @see zoomToCenterCoordinate:radius:animated:
 */
- (void)zoomToCenterCoordinate:(CLLocationCoordinate2D)coordinate animated:(BOOL)animated;
- (void)zoomToRegionEnclosingAnnotations:(NSArray *)annotations animated:(BOOL)animated;
- (void)smartZoomWithAnnotations:(NSArray *)annotations animated:(BOOL)animated;
- (void)zoomOnAnnotations:(NSArray *)annotations withStrategy:(CKBindedMapViewControllerZoomStrategy)strategy animated:(BOOL)animated;

- (BOOL)reloadData;

@end