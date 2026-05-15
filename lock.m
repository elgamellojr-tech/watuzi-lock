#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <objc/runtime.h>

// --- VISTA PERSONALIZADA ---
@interface MyCustomBar : UIView
@property (nonatomic, weak) UITabBarController *parentController;
@property (nonatomic, strong) UIView *selectionIndicator;
@property (nonatomic, strong) UIButton *chatButton;
@property (nonatomic, strong) UIButton *profileButton;
@end

@implementation MyCustomBar

- (instancetype)initWithFrame:(CGRect)frame parent:(UITabBarController *)parent {
    self = [super initWithFrame:frame];
    if (self) {
        _parentController = parent;
        
        // Configuración de la vista principal
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
        self.layer.cornerRadius = frame.size.height / 2;
        self.layer.masksToBounds = YES;
        self.userInteractionEnabled = YES; // CRITICO: Habilitar interacción

        // Efecto Blur
        UIVisualEffectView *blur = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
        blur.frame = self.bounds;
        blur.userInteractionEnabled = NO; // El blur no debe capturar toques
        [self addSubview:blur];

        // Indicador de selección
        _selectionIndicator = [[UIView alloc] initWithFrame:CGRectMake(5, 5, (frame.size.width/2) - 10, frame.size.height - 10)];
        _selectionIndicator.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.15];
        _selectionIndicator.layer.cornerRadius = _selectionIndicator.frame.size.height / 2;
        _selectionIndicator.userInteractionEnabled = NO;
        [self addSubview:_selectionIndicator];

        // BOTÓN CHATS
        _chatButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _chatButton.frame = CGRectMake(0, 0, frame.size.width/2, frame.size.height);
        [_chatButton setTitle:@"Chats" forState:UIControlStateNormal];
        [_chatButton addTarget:self action:@selector(goToChats) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_chatButton];

        // BOTÓN PERFIL
        _profileButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _profileButton.frame = CGRectMake(frame.size.width/2, 0, frame.size.width/2, frame.size.height);
        [_profileButton setTitle:@"Perfil" forState:UIControlStateNormal];
        
        if (@available(iOS 14.0, *)) {
            UIAction *verEstado = [UIAction actionWithTitle:@"Ver Estados" image:nil identifier:nil handler:^(__kindof UIAction *action) {
                [self goToUpdates];
            }];
            UIAction *ajustes = [UIAction actionWithTitle:@"Ajustes" image:nil identifier:nil handler:^(__kindof UIAction *action) {
                [self goToSettings];
            }];
            _profileButton.menu = [UIMenu menuWithTitle:@"" children:@[verEstado, ajustes]];
            _profileButton.showsMenuAsPrimaryAction = YES;
        } else {
            // Si es iOS viejo, al menos que cambie de pestaña al tocar
            [_profileButton addTarget:self action:@selector(goToSettings) forControlEvents:UIControlEventTouchUpInside];
        }
        [self addSubview:_profileButton];
    }
    return self;
}

// --- ACCIONES MEJORADAS ---

- (void)goToChats {
    [UIView animateWithDuration:0.2 animations:^{
        self.selectionIndicator.frame = CGRectMake(5, 5, (self.frame.size.width/2)-10, self.frame.size.height-10);
    }];
    if (self.parentController) {
        [self.parentController setSelectedIndex:3]; // Pestaña Chats
    }
}

- (void)goToUpdates {
    if (self.parentController) {
        [self.parentController setSelectedIndex:0]; // Pestaña Novedades/Estados
    }
}

- (void)goToSettings {
    [UIView animateWithDuration:0.2 animations:^{
        self.selectionIndicator.frame = CGRectMake((self.frame.size.width/2)+5, 5, (self.frame.size.width/2)-10, self.frame.size.height-10);
    }];
    if (self.parentController) {
        [self.parentController setSelectedIndex:4]; // Pestaña Tú/Configuración
    }
}

@end

// --- HOOK ---
static void (*orig_viewDidLayout)(UIViewController *, SEL);

void hooked_viewDidLayout(UIViewController *self, SEL _cmd) {
    orig_viewDidLayout(self, _cmd);

    if (![NSStringFromClass([self class]) isEqualToString
