#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// --- VISTA PERSONALIZADA ---
@interface MyCustomBar : UIView
@property (nonatomic, strong) UIVisualEffectView *blurView;
@property (nonatomic, strong) UIView *selectionIndicator;
@property (nonatomic, strong) UIButton *chatButton;
@property (nonatomic, strong) UIButton *profileButton;
@end

@implementation MyCustomBar
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
        self.layer.cornerRadius = frame.size.height / 2;
        self.layer.masksToBounds = YES;

        _blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
        _blurView.frame = self.bounds;
        [self addSubview:_blurView];

        _selectionIndicator = [[UIView alloc] initWithFrame:CGRectMake(5, 5, (frame.size.width/2) - 10, frame.size.height - 10)];
        _selectionIndicator.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.15];
        _selectionIndicator.layer.cornerRadius = _selectionIndicator.frame.size.height / 2;
        [self addSubview:_selectionIndicator];

        _chatButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _chatButton.frame = CGRectMake(0, 0, frame.size.width/2, frame.size.height);
        [_chatButton setTitle:@"チャット" forState:UIControlStateNormal];
        [_chatButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _chatButton.titleLabel.font = [UIFont boldSystemFontOfSize:11];
        [self addSubview:_chatButton];

        _profileButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _profileButton.frame = CGRectMake(frame.size.width/2, 0, frame.size.width/2, frame.size.height);
        [_profileButton setTitle:@"自分" forState:UIControlStateNormal];
        [_profileButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _profileButton.titleLabel.font = [UIFont boldSystemFontOfSize:11];

        // Protección para evitar errores en versiones viejas de iOS
        if (@available(iOS 14.0, *)) {
            UIAction *opcion1 = [UIAction actionWithTitle:@"Ajustes" image:[UIImage systemImageNamed:@"gear"] identifier:nil handler:^(__kindof UIAction *action) {}];
            UIAction *opcion2 = [UIAction actionWithTitle:@"Estados" image:[UIImage systemImageNamed:@"circle.dashed"] identifier:nil handler:^(__kindof UIAction *action) {}];
            
            _profileButton.menu = [UIMenu menuWithTitle:@"Opciones" children:@[opcion1, opcion2]];
            _profileButton.showsMenuAsPrimaryAction = YES;
        }

        [self addSubview:_profileButton];
    }
    return self;
}
@end

// --- HOOKING MANUAL (Objective-C Puro) ---
static void (*orig_viewDidAppear)(UIViewController *, SEL, BOOL);

void hooked_viewDidAppear(UIViewController *self, SEL _cmd, BOOL animated) {
    orig_viewDidAppear(self, _cmd, animated);

    if ([self.view viewWithTag:999]) return;

    // Solo aplicar a la TabBar de WhatsApp
    if ([NSStringFromClass([self class]) isEqualToString:@"WATabBarController"]) {
        CGFloat barWidth = 260;
        CGFloat barHeight = 65;
        MyCustomBar *customBar = [[MyCustomBar alloc] initWithFrame:CGRectMake(
            (self.view.frame.size.width - barWidth) / 2,
            self.view.frame.size.height - 100,
            barWidth,
            barHeight
        )];
        customBar.tag = 999;
        [self.view addSubview:customBar];
        
        // Ocultar la original
        if ([self respondsToSelector:@selector(tabBar)]) {
            [(UITabBarController *)self tabBar].hidden = YES;
        }
    }
}

// Constructor para inyectar el código al cargar la dylib
__attribute__((constructor))
static void init() {
    Class targetClass = objc_getClass("WATabBarController");
    if (targetClass) {
        Method origMethod = class_getInstanceMethod(targetClass, @selector(viewDidAppear:));
        orig_viewDidAppear = (void *)method_getImplementation(origMethod);
        method_setImplementation(origMethod, (IMP)hooked_viewDidAppear);
    }
}
