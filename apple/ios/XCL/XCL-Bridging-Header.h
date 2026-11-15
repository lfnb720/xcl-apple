//
//  XCL-Bridging-Header.h
//  让 Swift 能调用 XclJVM.m 里的 C 接口
//
#ifndef XCL_Bridging_Header_h
#define XCL_Bridging_Header_h

const char* xcl_jvm_create(const char* jreHome, const char* optionsJoined);
const char* xcl_jvm_run_main(const char* mainClass, const char* argsJoined);
int xcl_jvm_ready(void);

#endif /* XCL_Bridging_Header_h */
