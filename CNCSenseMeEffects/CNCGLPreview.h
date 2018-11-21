//
//  CNCGLPreview.h
//  senseMe_Demo
//
//  Created by 82008223 on 2017/12/15.
//  Copyright © 2017年 82008223. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/ES2/glext.h>

@interface CNCGLPreview : UIView

@property (nonatomic , strong) EAGLContext *glContext;

- (instancetype)initWithFrame:(CGRect)frame context:(EAGLContext *)context;

- (void)renderTexture:(GLuint)texture;

@end
