/*
 * jni_md.h - Darwin / iOS 版 JNI 平台定义
 * 用途: XCL iOS 运行层编译 XclJVM.m 时使用
 */
#ifndef __JNI_MD_H__
#define __JNI_MD_H__

#define JNIEXPORT __attribute__((visibility("default")))
#define JNIIMPORT __attribute__((visibility("default")))
#define JNICALL

typedef int jint;
#ifdef _LP64
typedef long jlong;
#else
typedef long long jlong;
#endif
typedef signed char jbyte;

#endif /* __JNI_MD_H__ */