//
//  IMBNavigationController.h
//  iMedia
//
//  Created by Jörg Jacobsen on 29.04.15.
//
//

#import <Foundation/Foundation.h>

@class IMBNavigationController;

@protocol IMBNavigationLocation <NSObject>

///**
// Determines whether the receiver is to be replaced by other location when other location is pushed directly on top of it.
// */
//- (BOOL)replaceOnPushBy:(id)otherLocation;

@end

#pragma mark -

@protocol IMBNavigable <NSObject>

/**
 Does everything that needs to be done to establish location within the receiver.
 @return Whether receiver could go to location.
 */
- (BOOL)gotoLocation:(id<IMBNavigationLocation>)location;

/**
 @return The receiver's current location.
 */
- (id<IMBNavigationLocation>)currentLocation;

/**
 @return Whether location is valid in current context of receiver.
 */
- (BOOL)isValidLocation:(id<IMBNavigationLocation>)location;

@end

@protocol IMBNavigationControllerDelegate <NSObject>

@optional

/**
 Called immediately after a new back button was set up on navigation controller.
 */
- (void)didSetupBackButton:(NSControl *)newButton;

/**
 Called immediately after a new forward button was set up on navigation controller.
 */
- (void)didSetupForwardButton:(NSControl *)newButton;

/**
 Called after navigation controller reached bottom of navigation stack.
 */
- (void)didGoBackToOldestLocation;

/**
 Called after navigation controller reached top of navigation stack.
 */
- (void)didGoForwardToLatestLocation;


/**
 Called after navigation controller changed its current index into its navigation stack but neither reached bottom nor top of navigation stack.
 */
- (void)didGotoIntermediateLocation;

- (void)didChangeNavigationController:(IMBNavigationController *)navigationController;

@end

#pragma mark -

@interface IMBNavigationController : NSObject {
    __unsafe_unretained id<IMBNavigationControllerDelegate> _delegate;
    __unsafe_unretained id<IMBNavigable> _locationProvider;
    NSMutableArray *_navigationStack;
    NSInteger _currentIndex;
    BOOL _goingBackOrForward;
}

@property (nonatomic, unsafe_unretained) IBOutlet id<IMBNavigationControllerDelegate> delegate;
@property (nonatomic, unsafe_unretained) IBOutlet id<IMBNavigable> locationProvider;

@property (nonatomic) BOOL goingBackOrForward;

/**
 Designated Initializer.
 */
- (instancetype)initWithLocationProvider:(id<IMBNavigable>)locationProvider;

/**
 Sets appropriate target and action on back button and makes it known to delegate.
 */
- (void)setupBackButton:(NSControl *)button;

/**
 Sets appropriate target and action on forward button and makes it known to delegate.
 */
- (void)setupForwardButton:(NSControl *)button;

#pragma mark - Validation

- (void)validateLocations;

#pragma mark - Navigation

/**
 Invokes -gotoLocation on delegate with the previous location.
 */
- (IBAction)goBackward:(id)sender;

/**
 Invokes -gotoLocation on delegate with the previous to going back location.
 */
- (IBAction)goForward:(id)sender;

/**
 Pushes a location onto the history of locations stack. Removes all forward locations.
 */
- (void)pushLocation:(id)location;

/**
 Replaces the current location with the location provided.
 @discussion This can be useful if the state of the location changed since it was put onto the navigation stack. If the navigation stack is empty pushes location onto stack instead.
 */
- (void)updateCurrentLocationWithLocation:(id<IMBNavigationLocation>)location;

/**
 Clears the whole history of locations stack without going to any location.
 */
- (void)reset;

#pragma mark - Query State

- (BOOL)canGoBackward;

- (BOOL)canGoForward;

@end
