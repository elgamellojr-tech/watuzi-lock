#import <UIKit/UIKit.h>

// Declaramos las clases de WhatsApp para que el compilador no de error
@interface WAChatViewController : UIViewController
@end

@interface ProfileViewController : UIViewController
@property (nonatomic, strong) UIView *containerView;
@end

// --- LÓGICA DE LA INTERFAZ DEL PERFIL ---
@implementation ProfileViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    
    // Contenedor principal (estilo image_2.png)
    self.containerView = [[UIView alloc] initWithFrame:CGRectMake(20, 100, self.view.frame.size.width - 40, 520)];
    self.containerView.backgroundColor = [UIColor colorWithRed:0.08 green:0.08 blue:0.09 alpha:1.0];
    self.containerView.layer.cornerRadius = 25;
    self.containerView.clipsToBounds = YES;
    [self.view addSubview:self.containerView];
    
    // Banner superior
    UIView *banner = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.containerView.frame.size.width, 130)];
    banner.backgroundColor = [UIColor colorWithRed:0.6 green:0.0 blue:0.0 alpha:1.0]; // Color base rojo
    [self.containerView addSubview:banner];

    // Texto de Ejemplo: saint iOS
    UILabel *userLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 160, 200, 30)];
    userLabel.text = @"saint iOS";
    userLabel.textColor = [UIColor whiteColor];
    userLabel.font = [UIFont boldSystemFontOfSize:24];
    [self.containerView addSubview:userLabel];

    // Botón para cerrar
    UIButton *close = [[UIButton alloc] initWithFrame:CGRectMake(15, 15, 30, 30)];
    [close setTitle:@"✕" forState:UIControlStateNormal];
    [close setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.3]];
    close.layer.cornerRadius = 15;
    [close addTarget:self action:@selector(closeMe) forControlEvents:UIControlEventTouchUpInside];
    [self.containerView addSubview:close];
}
- (void)closeMe { [self dismissViewControllerAnimated:YES completion:nil]; }
@end


// --- HOOKS PARA TRANSPARENCIA (image_3.png) ---
%hook TLKTableView
- (void)layoutSubviews {
    %orig;
    self.backgroundColor = [UIColor clearColor];
    self.backgroundView = nil;
}
%end

%hook WAConversationCell
- (void)layoutSubviews {
    %orig;
    // Esto quita el fondo blanco/gris de cada chat en la lista
    self.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = [UIColor clearColor];
    
    // Si quieres que se vea un poco oscuro como en image_3.png:
    UIView *bg = [[UIView alloc] initWithFrame:self.bounds];
    bg.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2];
    self.backgroundView = bg;
}
%end

// --- BOTÓN EN EL CHAT PARA ABRIR PERFIL ---
%hook WAChatViewController
- (void)viewDidLoad {
    %orig;
    UIBarButtonItem *profileItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"person.crop.circle"] 
                                                                    style:UIBarButtonItemStylePlain 
                                                                   target:self 
                                                                   action:@selector(openProfileManual)];
    self.navigationItem.rightBarButtonItems = @[profileItem];
}

%new
- (void)openProfileManual {
    ProfileViewController *pvc = [[ProfileViewController alloc] init];
    pvc.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [self presentViewController:pvc animated:YES completion:nil];
}
%end
