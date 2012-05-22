//
//  CKMapAnnotationController.h
//  CloudKit
//
//  Created by Sebastien Morel on 11-05-25.
//  Copyright 2011 WhereCloud Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "CKItemViewController.h"
#import "CKUIViewController.h"

/** TODO
 */
typedef enum CKMapAnnotationStyle{
	CKMapAnnotationCustom,
	CKMapAnnotationPin
}CKMapAnnotationStyle;

@class CKMapAnnotationController;

@interface CKAnnotationView : MKAnnotationView
@property(nonatomic,retain)CKUIViewController* calloutViewController;
@property(nonatomic,assign)CKMapAnnotationController* annotationController;

- (MKMapView*)mapView;

@end


/** TODO
 */
@interface CKMapAnnotationController : CKItemViewController {
	CKMapAnnotationStyle _style;
}

@property (nonatomic,assign) CKMapAnnotationStyle style;
@property (nonatomic, retain) CKCallback* deselectionCallback;

- (MKAnnotationView*)loadAnnotationView;
- (MKAnnotationView*)viewWithStyle:(CKMapAnnotationStyle)style;

- (void)didDeselect;

@end


#import "CKMapAnnotationController+CKBlockBasedInterface.h"