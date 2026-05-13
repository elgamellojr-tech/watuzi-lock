// --- HOOK ESTILO WHATSAPP VERIFIED (VISUAL) ---
@interface UILabel (DomidiosWA)
@end

@implementation UILabel (DomidiosWA)
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Method original = class_getInstanceMethod([self class], @selector(setText:));
        Method swizzled = class_getInstanceMethod([self class], @selector(domidios_setWAText:));
        method_exchangeImplementations(original, swizzled);
    });
}

- (void)domidios_setWAText:(NSString *)text {
    // Solo aplicamos si está activo, hay texto y no es un label vacío o extremadamente largo (mensajes)
    if (isVerifiedActive && text.length > 0 && text.length < 30) {
        
        // Color azul oficial de la insignia de WhatsApp
        UIColor *waBlue = [UIColor colorWithRed:0.00 green:0.51 blue:0.90 alpha:1.0];
        
        // Creamos el texto base
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ ", text]];
        
        // Símbolo de verificación oficial (Heavy Check Mark o Check Mark Circled)
        // Usamos el carácter Unicode \u2714 que es el más fiel visualmente
        NSDictionary *attributes = @{
            NSForegroundColorAttributeName: waBlue,
            NSFontAttributeName: [UIFont boldSystemFontOfSize:self.font.pointSize]
        };
        
        NSAttributedString *badge = [[NSAttributedString alloc] initWithString:@"\u2714" attributes:attributes];
        [attributedString appendAttributedString:badge];
        
        // Aplicamos como AttributedText para que el color azul sea independiente del nombre
        self.attributedText = attributedString;
        
        // Llamada original técnica (vía swizzling) para no romper el ciclo de vida del layout
        [self domidios_setWAText:text]; 
    } else {
        [self domidios_setWAText:text];
    }
}
@end
