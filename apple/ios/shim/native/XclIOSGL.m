//
//  XclIOSGL.m
//  iOS 图形层: EAGL + OpenGL ES 上下文 (供 Java 侧 IosGL 调用)
//
//  说明: 第一阶段做离屏 FBO 渲染 (不接显示), 目的是让 MC 的 LWJGL 调用有真实的 GL 上下文;
//        下一阶段再把 FBO 的纹理画到 MTKView / CAEAGLLayer 上呈现到屏幕.
//

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <QuartzCore/QuartzCore.h>
#import <jni.h>
#include <stdio.h>
#include <string.h>

static EAGLContext* g_ctx = NULL;
static GLuint g_fbo = 0;
static GLuint g_colorTex = 0;
static GLuint g_depthBuf = 0;
static int g_width = 0;
static int g_height = 0;
static char g_lastError[512] = "";

static BOOL ensureContext(void)
{
    if (g_ctx != NULL) return YES;
    g_ctx = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (g_ctx == nil) {
        snprintf(g_lastError, sizeof(g_lastError), "EAGLContext 创建失败");
        return NO;
    }
    if (![EAGLContext setCurrentContext:g_ctx]) {
        snprintf(g_lastError, sizeof(g_lastError), "setCurrentContext 失败");
        return NO;
    }
    return YES;
}

static BOOL ensureFBO(int w, int h)
{
    if (g_fbo != 0 && g_width == w && g_height == h) return YES;
    if (g_fbo != 0) {
        glDeleteFramebuffers(1, &g_fbo);
        glDeleteTextures(1, &g_colorTex);
        glDeleteRenderbuffers(1, &g_depthBuf);
        g_fbo = 0; g_colorTex = 0; g_depthBuf = 0;
    }
    glGenTextures(1, &g_colorTex);
    glBindTexture(GL_TEXTURE_2D, g_colorTex);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);

    glGenRenderbuffers(1, &g_depthBuf);
    glBindRenderbuffer(GL_RENDERBUFFER, g_depthBuf);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, w, h);

    glGenFramebuffers(1, &g_fbo);
    glBindFramebuffer(GL_FRAMEBUFFER, g_fbo);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, g_colorTex, 0);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, g_depthBuf);

    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        snprintf(g_lastError, sizeof(g_lastError), "FBO 不完整 0x%x", status);
        return NO;
    }
    g_width = w; g_height = h;
    return YES;
}

JNIEXPORT jstring JNICALL
Java_com_xcl_ios_IosGL_nativeCreate(JNIEnv* env, jclass c, jint w, jint h)
{
    (void) c;
    if (!ensureContext()) return (*env)->NewStringUTF(env, g_lastError);
    if (!ensureFBO(w > 0 ? w : 854, h > 0 ? h : 480)) return (*env)->NewStringUTF(env, g_lastError);
    glViewport(0, 0, g_width, g_height);
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    const char* ver = (const char*) glGetString(GL_VERSION);
    snprintf(g_lastError, sizeof(g_lastError), "ok %dx%d GL=%s", g_width, g_height, ver ? ver : "?");
    return (*env)->NewStringUTF(env, g_lastError);
}

JNIEXPORT void JNICALL Java_com_xcl_ios_IosGL_nativeDestroy(JNIEnv* env, jclass c)
{
    (void) env; (void) c;
    if (g_fbo != 0) { glDeleteFramebuffers(1, &g_fbo); g_fbo = 0; }
    if (g_colorTex != 0) { glDeleteTextures(1, &g_colorTex); g_colorTex = 0; }
    if (g_depthBuf != 0) { glDeleteRenderbuffers(1, &g_depthBuf); g_depthBuf = 0; }
    [EAGLContext setCurrentContext:nil];
}

JNIEXPORT void JNICALL Java_com_xcl_ios_IosGL_nativeSwap(JNIEnv* env, jclass c)
{
    (void) env; (void) c;
    if (g_ctx == NULL) return;
    [EAGLContext setCurrentContext:g_ctx];
    glFlush();
}

JNIEXPORT void JNICALL Java_com_xcl_ios_IosGL_nativeMakeCurrent(JNIEnv* env, jclass c)
{
    (void) env; (void) c;
    if (g_ctx != NULL) [EAGLContext setCurrentContext:g_ctx];
}

JNIEXPORT jint JNICALL Java_com_xcl_ios_IosGL_nativeWidth(JNIEnv* env, jclass c)
{ (void) env; (void) c; return g_width; }

JNIEXPORT jint JNICALL Java_com_xcl_ios_IosGL_nativeHeight(JNIEnv* env, jclass c)
{ (void) env; (void) c; return g_height; }

JNIEXPORT void JNICALL Java_com_xcl_ios_IosGL_nativeSetVSync(JNIEnv* env, jclass c, jboolean on)
{
    (void) env; (void) c; (void) on;
    // EAGL 的 vsync 由呈现层控制, 这里留空
}

JNIEXPORT jstring JNICALL Java_com_xcl_ios_IosGL_nativeGetString(JNIEnv* env, jclass c, jint name)
{
    (void) c;
    if (g_ctx == NULL) return (*env)->NewStringUTF(env, "");
    [EAGLContext setCurrentContext:g_ctx];
    const char* s = (const char*) glGetString((GLenum) name);
    return (*env)->NewStringUTF(env, s ? s : "");
}
