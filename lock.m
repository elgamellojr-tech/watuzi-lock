#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

@interface DynamicBackgroundView : UIView
@end

@implementation DynamicBackgroundView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = NO;
        self.tag = 888;
        self.backgroundColor = [UIColor clearColor];
        [self startInfiniteAnimation];
        
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(startInfiniteAnimation) 
                                                     name:UIApplicationDidBecomeActiveNotification 
                                                   object:nil];
    }
    return self;
}

- (void)startInfiniteAnimation {
    [self.layer removeAllAnimations];

    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animation.fromValue = @(1.0);
    animation.toValue = @(0.5);
    animation.duration = 2.5; 
    animation.autoreverses = YES;
    animation.repeatCount = HUGE_VALF;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;

    [self.layer addAnimation:animation forKey:@"keepMovingLoop"];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    // Esto quita el warning del dealloc
    #if !__has_feature(objc_arc)
    [super dealloc];
    #endif
}

@end

// --- INYECCIÓN EN WATUSI ---

static void (*orig_viewDidAppear)(UIViewController *, SEL, BOOL);

void hooked_viewDidAppear(UIViewController *self, SEL _cmd, BOOL animated) {
    orig_viewDidAppear(self, _cmd, animated);

    if ([NSStringFromClass([self class]) isEqualToString:@"WatusiLockViewController"]) {
        DynamicBackgroundView *bg = [self.view viewWithTag:888];
        if (!bg) {
            DynamicBackgroundView *dynamicBg = [[DynamicBackgroundView alloc] initWithFrame:self.view.bounds];
            [self.view insertSubview:dynamicBg atIndex:0];
        } else {
            [bg startInfiniteAnimation];
        }
    }
}

__attribute__((constructor))
static void init() {
    Class targetClass = NSClassFromString(@"WatusiLockViewController");
    if (targetClass) {
        Method origMethod = class_getInstanceMethod(targetClass, @selector(viewDidAppear:));
        orig_viewDidAppear = (void *)method_getImplementation(origMethod);
        method_setImplementation(origMethod, (IMP)hooked_viewDidAppear);
    }
}
