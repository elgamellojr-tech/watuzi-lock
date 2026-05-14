#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

// --- VISTA DINÁMICA ---
@interface DynamicBackgroundView : UIView
@end

@implementation DynamicBackgroundView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = NO;
        self.tag = 888;
        [self startInfiniteAnimation];
        
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(startInfiniteAnimation) 
                                                     name:UIApplicationWillEnterForegroundNotification 
                                                   object:nil];
    }
    return self;
}

- (void)startInfiniteAnimation {
    [self.layer removeAllAnimations];

    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animation.fromValue = @(1.0);
    animation.toValue = @(0.4);
    animation.duration = 2.0; 
    animation.autoreverses = YES;
    animation.repeatCount = HUGE_VALF;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;

    [self.layer addAnimation:animation forKey:@"persistentLoop"];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    // Solución al warning de dealloc
    #if !__has_feature(objc_arc)
    [super dealloc];
    #endif
}

@end

// --- LÓGICA DE INYECCIÓN (SWIZZLING) ---

void swizzleMethod(Class class, SEL originalSelector, SEL swizzledSelector) {
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    method_exchangeImplementations(originalMethod, swizzledMethod);
}

@interface UIViewController (WatusiFix)
- (void)new_viewDidAppear:(BOOL)animated;
@end

@implementation UIViewController (WatusiFix)
- (void)new_viewDidAppear:(BOOL)animated {
    [self new_viewDidAppear:animated]; // Llama al original

    // Verificamos si estamos en la pantalla de bloqueo de Watusi
    if ([NSStringFromClass([self class]) isEqualToString:@"WatusiLockViewController"]) {
        DynamicBackgroundView *existingBg = [self.view viewWithTag:888];
        if (!existingBg) {
            DynamicBackgroundView *dynamicBg = [[DynamicBackgroundView alloc] initWithFrame:self.view.bounds];
            [self.view insertSubview:dynamicBg atIndex:0];
        } else {
            [existingBg startInfiniteAnimation];
        }
    }
}
@end

// Esto se ejecuta automáticamente al cargar la dylib
__attribute__((constructor))
static void initialize() {
    Class targetClass = NSClassFromString(@"WatusiLockViewController");
    if (targetClass) {
        swizzleMethod(targetClass, @selector(viewDidAppear:), @selector(new_viewDidAppear:));
    }
}
