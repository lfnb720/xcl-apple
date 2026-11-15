//
//  XclJVM.m
//  XCL iOS 运行层: 在 App 内创建 Java 虚拟机并执行 main
//
//  原理: dlopen 随包的 libjvm.dylib (OpenJDK 8 Zero, arm64/iOS),
//        取 JNI_CreateJavaVM, 传入 classpath / 堆大小等选项,
//        再 FindClass + CallStaticVoidMethod 执行入口类。
//  注意: iOS 不允许 JIT, 因此只能用 Zero 解释器版; 速度慢但能跑。
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#include <dlfcn.h>
#include <jni.h>
#include <string.h>
#include <stdio.h>

typedef jint (*CreateJavaVMFn)(JavaVM**, void**, void*);

static JavaVM* g_vm = NULL;
static JNIEnv* g_env = NULL;   // 创建时保存, 避免再次 GetEnv 失败
static char g_lastError[1024] = "";

/// 在 jreHome 目录里定位 libjvm.dylib (兼容几种常见布局)
static NSString* findLibJvm(NSString* jreHome)
{
    NSArray<NSString*>* candidates = @[
        @"lib/server/libjvm.dylib",
        @"lib/client/libjvm.dylib",
        @"lib/libjvm.dylib",
        @"lib/aarch64/libjvm.dylib",
        @"lib/server/libjvm.so",
    ];
    for (NSString* rel in candidates) {
        NSString* p = [jreHome stringByAppendingPathComponent:rel];
        if ([[NSFileManager defaultManager] fileExistsAtPath:p]) return p;
    }
    return nil;
}

/// 创建 JVM; 成功返回 1, 失败返回 0 并把原因写入 g_lastError
static int createJVM(NSString* jreHome, NSArray<NSString*>* options)
{
    if (g_vm != NULL) return 1;

    NSString* libPath = findLibJvm(jreHome);
    if (libPath == nil) {
        snprintf(g_lastError, sizeof(g_lastError), "找不到 libjvm.dylib (%s)", jreHome.UTF8String);
        return 0;
    }

    void* handle = dlopen(libPath.UTF8String, RTLD_NOW | RTLD_GLOBAL);
    if (handle == NULL) {
        snprintf(g_lastError, sizeof(g_lastError), "dlopen 失败: %s", dlerror());
        return 0;
    }
    CreateJavaVMFn create = (CreateJavaVMFn) dlsym(handle, "JNI_CreateJavaVM");
    if (create == NULL) {
        snprintf(g_lastError, sizeof(g_lastError), "缺少 JNI_CreateJavaVM");
        return 0;
    }

    NSUInteger n = options.count > 32 ? 32 : options.count;
    JavaVMOption opts[32];
    memset(opts, 0, sizeof(opts));
    char** storage = (char**)calloc(n + 1, sizeof(char*));
    for (NSUInteger i = 0; i < n; ++i) {
        storage[i] = strdup([options[i] UTF8String]);
        opts[i].optionString = storage[i];
    }

    JavaVMInitArgs args;
    memset(&args, 0, sizeof(args));
    args.version = JNI_VERSION_1_8;
    args.nOptions = (jint)n;
    args.options = opts;
    args.ignoreUnrecognized = JNI_TRUE;

    JNIEnv* env = NULL;
    jint rc = create(&g_vm, (void**)&env, &args);
    for (NSUInteger i = 0; i < n; ++i) free(storage[i]);
    free(storage);

    if (rc == JNI_OK && g_vm != NULL) g_env = env;
    if (rc != JNI_OK || g_vm == NULL) {
        snprintf(g_lastError, sizeof(g_lastError), "JNI_CreateJavaVM 失败 rc=%d", (int)rc);
        g_vm = NULL;
        return 0;
    }
    return 1;
}

/// 执行某个类的 main(String[]); 返回 "ok" 或错误
static NSString* runMain(NSString* mainClass, NSArray<NSString*>* args)
{
    if (g_vm == NULL) return @"JVM 未创建";
    // env 属于线程: 每次调用都要确认当前线程是否已附着到 JVM
    JNIEnv* env = NULL;
    BOOL attached = NO;
    jint gres = (*g_vm)->GetEnv(g_vm, (void**)&env, JNI_VERSION_1_8);
    if (gres == JNI_EDETACHED || env == NULL) {
        if ((*g_vm)->AttachCurrentThread(g_vm, (void**)&env, NULL) != JNI_OK || env == NULL) {
            return @"JVM 线程附着失败";
        }
        attached = YES;
    }
    // JNI 的 FindClass 需要斜杠分隔 (com/xcl/smoke/Smoke), 不能直接用点
    NSString* slashName = [mainClass stringByReplacingOccurrencesOfString:@"." withString:@"/"];
    jclass cls = (*env)->FindClass(env, slashName.UTF8String);
    if (cls == NULL) {
        (*env)->ExceptionDescribe(env);
        (*env)->ExceptionClear(env);
        // 附带 classpath 与 jar 存在性, 便于定位
        NSString* cp = @"(unknown)";
        jstring cpStr = NULL;
        jclass sysCls = (*env)->FindClass(env, "java/lang/System");
        if (sysCls != NULL) {
            jmethodID getProp = (*env)->GetStaticMethodID(env, sysCls, "getProperty",
                                                          "(Ljava/lang/String;)Ljava/lang/String;");
            if (getProp != NULL) {
                jstring key = (*env)->NewStringUTF(env, "java.class.path");
                cpStr = (jstring)(*env)->CallStaticObjectMethod(env, sysCls, getProp, key);
                if (cpStr != NULL) {
                    const char* c = (*env)->GetStringUTFChars(env, cpStr, NULL);
                    if (c != NULL) { cp = [NSString stringWithUTF8String:c]; (*env)->ReleaseStringUTFChars(env, cpStr, c); }
                }
                (*env)->DeleteLocalRef(env, key);
                (*env)->ExceptionClear(env);
            }
        }
        return [NSString stringWithFormat:@"找不到类: %@ (斜杠形式: %@)\nclasspath=%@", mainClass, slashName, cp];
    }
    jmethodID mid = (*env)->GetStaticMethodID(env, cls, "main", "([Ljava/lang/String;)V");
    if (mid == NULL) return @"找不到 main(String[])";

    jclass strCls = (*env)->FindClass(env, "java/lang/String");
    jobjectArray arr = (*env)->NewObjectArray(env, (jsize)args.count, strCls, NULL);
    for (NSUInteger i = 0; i < args.count; ++i) {
        jstring s = (*env)->NewStringUTF(env, [args[i] UTF8String]);
        (*env)->SetObjectArrayElement(env, arr, (jsize)i, s);
        (*env)->DeleteLocalRef(env, s);
    }
    (*env)->CallStaticVoidMethod(env, cls, mid, arr);
    jboolean hadException = (*env)->ExceptionCheck(env);
    if (hadException) {
        (*env)->ExceptionDescribe(env);
        (*env)->ExceptionClear(env);
    }
    if (attached) (*g_vm)->DetachCurrentThread(g_vm);
    if (hadException) return @"main 执行抛出异常";
    return @"ok";
}

#pragma mark - C 接口给 Swift 调用

const char* xcl_jvm_create(const char* jreHome, const char* optionsJoined)
{
    @autoreleasepool {
        NSString* home = [NSString stringWithUTF8String:jreHome ? jreHome : ""];
        NSMutableArray<NSString*>* opts = [NSMutableArray array];
        NSString* joined = [NSString stringWithUTF8String:optionsJoined ? optionsJoined : ""];
        for (NSString* s in [joined componentsSeparatedByString:@"\n"]) {
            if (s.length > 0) [opts addObject:s];
        }
        if (!createJVM(home, opts)) return g_lastError;
        return "ok";
    }
}

const char* xcl_jvm_run_main(const char* mainClass, const char* argsJoined)
{
    @autoreleasepool {
        NSString* mc = [NSString stringWithUTF8String:mainClass ? mainClass : ""];
        NSString* joined = [NSString stringWithUTF8String:argsJoined ? argsJoined : ""];
        NSArray<NSString*>* args = joined.length > 0
            ? [joined componentsSeparatedByString:@"\n"]
            : @[];
        NSString* r = runMain(mc, args);
        static char out[1024];
        snprintf(out, sizeof(out), "%s", r.UTF8String);
        return out;
    }
}

int xcl_jvm_ready(void)
{
    return g_vm != NULL ? 1 : 0;
}
