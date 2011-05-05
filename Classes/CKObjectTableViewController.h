//
//  RootViewController.h
//  FeedView
//
//  Created by Sebastien Morel on 11-03-16.
//  Copyright Wherecloud 2011. All rights reserved.
//

#import "CKTableViewController.h"
#import "CKObjectController.h"
#import "CKObjectViewControllerFactory.h"
#import "CKNSDictionary+TableViewAttributes.h"
#import "CKDocumentCollection.h"
#import <CloudKit/CKTableViewCellController.h>

@interface CKObjectTableViewController : CKTableViewController<CKObjectControllerDelegate,UISearchBarDelegate> {
	id _objectController;
	CKObjectViewControllerFactory* _controllerFactory;
	
	CKTableViewOrientation _orientation;
	BOOL _resizeOnKeyboardNotification;
	
	int _currentPage;
	int _numberOfPages;
	int _numberOfObjectsToprefetch;
	
	BOOL _scrolling;
	BOOL _editable;
	BOOL _searchEnabled;
	
	UITableViewRowAnimation _rowInsertAnimation;
	UITableViewRowAnimation _rowRemoveAnimation;
	
	//for editable tables
	UIBarButtonItem *editButton;
	UIBarButtonItem *doneButton;
	
	//internal
	NSMutableDictionary* _cellsToControllers;
	NSMutableDictionary* _cellsToIndexPath;
	NSMutableDictionary* _indexPathToCells;
	NSMutableDictionary* _controllersForIdentifier;
	NSMutableDictionary* _params;
	NSMutableArray* _weakCells;
	NSIndexPath* _indexPathToReachAfterRotation;
	NSMutableDictionary* _headerViewsForSections;
	
	id _delegate;
}

@property (nonatomic, retain) id objectController;
@property (nonatomic, assign) id delegate;
@property (nonatomic, retain) CKObjectViewControllerFactory* controllerFactory;

@property (nonatomic, assign) CKTableViewOrientation orientation;
@property (nonatomic, assign) UITableViewRowAnimation rowInsertAnimation;
@property (nonatomic, assign) UITableViewRowAnimation rowRemoveAnimation;
@property (nonatomic, assign) BOOL resizeOnKeyboardNotification;
@property (nonatomic, assign) int currentPage;
@property (nonatomic, assign) int numberOfPages;
@property (nonatomic, assign) int numberOfObjectsToprefetch;
@property (nonatomic, assign, readonly) BOOL scrolling;
@property (nonatomic, assign) BOOL editable;
@property (nonatomic, assign) BOOL searchEnabled;

@property (nonatomic, retain) UIBarButtonItem *editButton;
@property (nonatomic, retain) UIBarButtonItem *doneButton;

- (id)initWithCollection:(CKDocumentCollection*)collection mappings:(NSDictionary*)mappings;
- (id)initWithObjectController:(id)controller withControllerFactory:(CKObjectViewControllerFactory*)factory;

- (id)initWithCollection:(CKDocumentCollection*)collection mappings:(NSDictionary*)mappings withNibName:(NSString*)nib;
- (id)initWithObjectController:(id)controller withControllerFactory:(CKObjectViewControllerFactory*)factory  withNibName:(NSString*)nib;

- (void)fetchMoreIfNeededAtIndexPath:(NSIndexPath*)indexPath;
- (CKTableViewCellController*)controllerForRowAtIndexPath:(NSIndexPath *)indexPath;

@end


@protocol CKObjectTableViewControllerDelegate
- (void)objectTableViewController:(CKObjectTableViewController*)controller didSelectRowAtIndexPath:(NSIndexPath*)indexPath withObject:(id)object;
- (void)objectTableViewController:(CKObjectTableViewController*)controller didSearch:(NSString*)filter;
@end
