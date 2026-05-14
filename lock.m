#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

// --- VISTA DEL FONDO ANIMADO ---
@interface DynamicBackgroundView : UIView
@end

@implementation DynamicBackgroundView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = NO;
        self.tag = 888; // Identificador para no duplicar la vista
        self.backgroundColor = [UIColor clearColor];
        [self startInfiniteAnimation];
        
        // REINICIO AUTOMÁTICO: Si sales y entras a la app, esto reactiva el movimiento
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(startInfiniteAnimation) 
                                                     name:UIApplicationDidBecomeActiveNotification 
                                                   object:nil];
    }
    return self;
}

- (void)startInfiniteAnimation {
    // Limpiamos animaciones viejas para que no se congele
    [self.layer removeAllAnimations];

    // Animación de opacidad persistente (puedes cambiar 'opacity' por 'backgroundColor' si prefieres)
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animation.fromValue = @(1.0);
    animation.toValue = @(0.5);
    animation.duration = 2.5; 
    animation.autoreverses = YES;
    animation.repeatCount = HUGE_VALF; // Infinito
    
    // ESTO EVITA QUE SE PARE AL SALIR DE LA APP
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;

    [self.layer addAnimation:animation forKey:@"keepMovingLoop"];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

// --- INYECCIÓN AUTOMÁTICA EN WATUSI ---

static void (*orig_viewDidAppear)(UIViewController *, SEL, BOOL);

void hooked_viewDidAppear(UIViewController *self, SEL _cmd, BOOL animated) {
    // Ejecuta la función original de Watusi
    orig_viewDidAppear(self, _cmd, animated);

    // Solo actuar si es la pantalla de bloqueo
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

// ESTO SE EJECUTA SOLO AL CARGAR LA DYLIB
__attribute__((constructor))
static void init() {
    Class targetClass = NSClassFromString(@"WatusiLockViewController");
    if (targetClass) {
        Method origMethod = class_getInstanceMethod(targetClass, @selector(viewDidAppear:));
        orig_viewDidAppear = (void *)method_getImplementation(origMethod);
        method_setImplementation(origMethod, (IMP)hooked_viewDidAppear);
    }
}
