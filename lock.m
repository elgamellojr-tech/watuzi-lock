#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface DynamicBackgroundView : UIView
@end

@implementation DynamicBackgroundView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = NO; // Para que no interfiera con los toques
        [self startInfiniteAnimation];
        
        // SUSCRIPCIÓN CRÍTICA: Reiniciar cuando la app vuelve a primer plano
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(startInfiniteAnimation) 
                                                     name:UIApplicationWillEnterForegroundNotification 
                                                   object:nil];
    }
    return self;
}

- (void)startInfiniteAnimation {
    // 1. Limpieza total de animaciones colgadas
    [self.layer removeAllAnimations];

    // 2. Definir la animación (ejemplo de pulso o brillo)
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animation.fromValue = @(1.0);
    animation.toValue = @(0.4);
    animation.duration = 2.0; 
    animation.autoreverses = YES;
    animation.repeatCount = HUGE_VALF;
    
    // 3. LA CLAVE: Estas dos líneas evitan que iOS borre la animación al pausar
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;

    // 4. Aplicar
    [self.layer addAnimation:animation forKey:@"persistentLoop"];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

// --- HOOK DE INTEGRACIÓN ---

%hook WatusiLockViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    
    // Buscar si ya existe para no duplicar
    DynamicBackgroundView *existingBg = [self.view viewWithTag:888];
    
    if (!existingBg) {
        DynamicBackgroundView *dynamicBg = [[DynamicBackgroundView alloc] initWithFrame:self.view.bounds];
        dynamicBg.tag = 888;
        [self.view insertSubview:dynamicBg atIndex:0];
    } else {
        // Forzar reinicio si ya existe pero está parado
        [existingBg startInfiniteAnimation];
    }
}

%end
