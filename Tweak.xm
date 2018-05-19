#import <SpringBoard/SpringBoard.h>
#import <CommonCrypto/CommonDigest.h>
#include <spawn.h>

#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height

@interface SBGrabberTongue : NSObject
{
  UIPanGestureRecognizer *_edgePullGestureRecognizer;
  UIView *_tongueContainer;
}
@end

//FluidSwitcher for SpringBoard/Apps swipe up
@interface SBFluidSwitcherGestureManager : NSObject
@property(retain, nonatomic) SBGrabberTongue *deckGrabberTongue; // @synthesize deckGrabberTongue=_deckGrabberTongue;
@end

//For swipe down from left of the notch and swipe up from the bottom of lockscreen
@interface SBCoverSheetPrimarySlidingViewController : UIViewController
@property (retain, nonatomic) SBGrabberTongue *grabberTongue;
-(CGPoint)_locationForGesture:(id)arg1;
-(id)dismissGestureRecognizer;
@end

@interface FBScene : NSObject
-(int)currentInterfaceOrientation;
@end

@interface SBApplication : NSObject
-(FBScene *)mainScene;
@end

@interface SBLockScreenViewControllerBase : UIViewController
-(BOOL)isAuthenticated;
@end

@interface SBLockScreenManager : NSObject
+(SBLockScreenManager *)sharedInstance;
-(SBLockScreenViewControllerBase *)lockScreenViewController;
@end

#define Home 1
#define ControlCenter 2
#define LockDevice 3
#define CoverSheet 4
#define ScreenShot 5

static int leftGesture = 1;
static int centerGesture = 1;
static int rightGesture = 1;

BOOL handleGesture(CGFloat x) {
  int gesture = (x <= kScreenWidth*1/3)? (gesture = leftGesture) : ((x <= kScreenWidth*2/3)? (gesture = centerGesture) : (gesture = rightGesture));
  BOOL didHandleGesture = YES;

  switch(gesture) {
    case Home :
      didHandleGesture = NO;
      break;
    case ControlCenter :
      //bring up CC;
      break;
    case LockDevice :
      //lock;
      break;
    case CoverSheet :
      //present CoverSheet;
      break;
    case ScreenShot :
      //take ScreenShot;
      break;
  }
  
  return didHandleGesture;
}

%hook SBCoverSheetPrimarySlidingViewController

-(void)grabberTongueBeganPulling:(id)arg1 withDistance:(double)arg2 andVelocity:(double)arg3 {

  //get the grabber and the location where gesture started.
  UIView *view = [self.grabberTongue valueForKey:@"_tongueContainer"];
  CGPoint point = [[self.grabberTongue valueForKey:@"_edgePullGestureRecognizer"] locationInView:view];

  if(![(SpringBoard *)[UIApplication sharedApplication] isLocked])
    if(!handleGesture(point.x)) %orig;
}

-(void)_handleDismissGesture:(id)arg1 {

  CGPoint point = [self _locationForGesture:[self dismissGestureRecognizer]];

  //authenticated = YES -> device is in normal swiped down CoverSheet or have no passcode
  //authenticated = NO -> device is in lockscreen with passcode locked
  if(![[[%c(SBLockScreenManager) sharedInstance] lockScreenViewController] isAuthenticated])
    if(!handleGesture(point.x)) %orig;
}

%end

%hook SBFluidSwitcherGestureManager

- (void)grabberTongueBeganPulling:(id)arg1 withDistance:(double)arg2 andVelocity:(double)arg3 {

  UIView *view = [self.deckGrabberTongue valueForKey:@"_tongueContainer"];
  CGPoint point = [[self.deckGrabberTongue valueForKey:@"_edgePullGestureRecognizer"] locationInView:view];

  if([(FBScene *)[(SBApplication *)[((SpringBoard *)[UIApplication sharedApplication]) _accessibilityFrontMostApplication] mainScene] currentInterfaceOrientation] != 1 || !handleGesture(point.x))
    %orig;

}
%end
