#import <UIKit/UIKit.h>

// --- INTERFACES ---
@interface WATabBarController : UITabBarController
@end

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

        // Efecto Blur (Desenfoque)
        _blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
        _blurView.frame = self.bounds;
        [self addSubview:_blurView];

        // Indicador de selección (el óvalo gris claro)
        _selectionIndicator = [[UIView alloc] initWithFrame:CGRectMake(5, 5, (frame.size.width/2) - 10, frame.size.height - 10)];
        _selectionIndicator.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.15];
        _selectionIndicator.layer.cornerRadius = _selectionIndicator.frame.size.height / 2;
        [self addSubview:_selectionIndicator];

        // Botón Chat
        _chatButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _chatButton.frame = CGRectMake(0, 0, frame.size.width/2, frame.size.height);
        [_chatButton setTitle:@"チャット" forState:UIControlStateNormal];
        [_chatButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _chatButton.titleLabel.font = [UIFont boldSystemFontOfSize:11];
        [self addSubview:_chatButton];

        // Botón Perfil (con Menú)
        _profileButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _profileButton.frame = CGRectMake(frame.size.width/2, 0, frame.size.width/2, frame.size.height);
        [_profileButton setTitle:@"自分" forState:UIControlStateNormal];
        [_profileButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _profileButton.titleLabel.font = [UIFont boldSystemFontOfSize:11];
        
        // --- AQUÍ LAS DEMÁS OPCIONES AL DARLE AL PERFIL ---
        UIAction *opcion1 = [UIAction actionWithTitle:@"Ajustes" image:[UIImage systemImageNamed:@"gear"] identifier:nil handler:^(__kindof UIAction *action) {
            // Acción para ajustes
        }];
        UIAction *opcion2 = [UIAction actionWithTitle:@"Estados" image:[UIImage systemImageNamed:@"circle.dashed"] identifier:nil handler:^(__kindof UIAction *action) {
            // Acción para estados
        }];
        UIAction *opcion3 = [UIAction actionWithTitle:@"Perfil" image:[UIImage systemImageNamed:@"person"] identifier:nil handler:^(__kindof UIAction *action) {
            // Acción para perfil
        }];

        _profileButton.menu = [UIMenu menuWithTitle:@"Opciones" children:@[opcion1, opcion2, opcion3]];
        _profileButton.showsMenuAsPrimaryAction = YES; // Abre el menú al tocar

        [self addSubview:_profileButton];
    }
    return self;
}
@end

// --- HOOKING ---
%hook WATabBarController

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    
    // Evitar duplicados
    if ([self.view viewWithTag:999]) return;

    // Crear la barra (280 ancho, 65 alto)
    CGFloat barWidth = 260;
    CGFloat barHeight = 65;
    MyCustomBar *customBar = [[MyCustomBar alloc] initWithFrame:CGRectMake(
        (self.view.frame.size.width - barWidth) / 2,
        self.view.frame.size.height - 100, // Altura desde el suelo
        barWidth,
        barHeight
    )];
    customBar.tag = 999;
    
    [self.view addSubview:customBar];
    
    // Ocultar la barra original de WhatsApp si lo deseas
    self.tabBar.hidden = YES;
}

%end
