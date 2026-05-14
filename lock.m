#import <UIKit/UIKit.h>

%hook WAMessageCell
- (void)layoutSubviews {
    %orig;
    
    // Hace que el fondo de las burbujas sea semi-transparente
    UIView *bubbleView = [self valueForKey:@"_bubbleView"];
    if (bubbleView) {
        bubbleView.alpha = 0.6; // Ajusta este valor (0.0 a 1.0) para la transparencia
        bubbleView.layer.cornerRadius = 15;
        bubbleView.clipsToBounds = YES;
    }
}
%end

%hook WAVectorImageCell
- (void)setBackgroundColor:(UIColor *)color {
    // Forzamos que el fondo de la celda sea transparente para que se vea la imagen de fondo
    %orig([UIColor clearColor]);
}
%end

%hook WABackgroundView
- (void)setImage:(UIImage *)image {
    // Asegura que la imagen de fondo (la de image.png) ocupe toda la pantalla
    %orig(image);
    self.contentMode = UIViewContentModeScaleAspectFill;
}
%end

%hook WAViewController
- (void)viewDidLoad {
    %orig;
    // Elimina colores sólidos que puedan tapar el fondo en el chat
    if ([NSStringFromClass([self class]) containsString:@"WAChatViewController"]) {
        self.view.backgroundColor = [UIColor clearColor];
    }
}
%end
