//
// © 2024-present https://github.com/cengiz-pz
//
// GodotTestStubs.mm
//
// Weak link-time stubs for all Godot engine symbols needed by the plugin
// sources when compiled into the test bundle without libgodot.
//
// -- Strategy ----------------------------------------------------------------
// Godot 4.7 marks many symbols _FORCE_INLINE_ but the compiler does not
// always emit them into every object file — it only inlines at call-sites
// within the same TU. Plugin .o files compiled against the real libgodot
// depended on those symbols being present in the engine archive. Without it
// the linker cannot resolve them.
//
// We provide every needed symbol as __attribute__((weak)) bound to the exact
// mangled name via an asm label. Weak symbols lose to any strong definition
// (including an inlined one emitted by the compiler from the headers), so
// there is no ODR conflict. When the compiler did NOT inline a symbol the
// weak stub fills the gap.
//
// We deliberately do NOT #include any Godot headers. Including them would
// compile their _FORCE_INLINE_ bodies into this TU creating a second strong
// definition that conflicts with our weak stubs. We forward-declare the
// minimum types needed to write correct signatures.
//

#include <cstdlib>   // malloc / free
#include <cstdio>    // fprintf / fflush
#include <cstdint>   // int64_t
#include <cstring>   // memset

#import <Foundation/Foundation.h>

// -- Minimal type forwards ----------------------------------------------------

enum ErrorHandlerType {
    ERR_HANDLER_ERROR   = 0,
    ERR_HANDLER_WARNING = 1,
    ERR_HANDLER_SCRIPT  = 2,
    ERR_HANDLER_SHADER  = 3,
};

// Opaque stand-ins — sizes chosen to be ≥ the real types on arm64.
// We never construct these on the stack in the stubs; they are only used
// as pointer parameters so the exact size does not matter for ABI.
struct _StubStringName { void *_data; };
struct _StubVariant    { uint8_t _d[24]; };
struct _StubArray      { void *_p; };
struct _StubDict       { void *_p; };
struct _StubCallable   { uint8_t _d[16]; };
struct _StubString     { void *_cowdata; };

// -- Helper macro -------------------------------------------------------------
// Declare a weak function bound to a specific mangled name, then define it.
#define WEAK_STUB(ret, cname, mangled, params, body) \
    __attribute__((weak)) ret cname params __asm__(mangled); \
    __attribute__((weak)) ret cname params body

// -- Error-printing functions --------------------------------------------------

__attribute__((weak))
void err_print_error(const char *f, const char *file, int line,
        const char *err, const char *msg, bool ed, ErrorHandlerType t) {
    fprintf(stderr, "ERR [%s:%d %s]: %s — %s\n", file, line, f, err, msg ? msg : "");
}

__attribute__((weak))
void err_print_error(const char *f, const char *file, int line,
        const char *err, bool ed, ErrorHandlerType t) {
    fprintf(stderr, "ERR [%s:%d %s]: %s\n", file, line, f, err);
}

__attribute__((weak))
void err_print_index_error(const char *f, const char *file, int line,
        int64_t idx, int64_t sz, const char *, const char *err,
        const char *, bool, bool) {
    fprintf(stderr, "IDX ERR [%s:%d %s]: %lld/%lld — %s\n",
            file, line, f, (long long)idx, (long long)sz, err);
}

__attribute__((weak))
void err_flush_stdout() { fflush(stdout); }

// -- StringName ----------------------------------------------------------------

// StringName::StringName(StringName const&)
WEAK_STUB(void, _stub_SN_copy,
    "__ZN10StringNameC1ERKS_",
    (_StubStringName *self, const _StubStringName *),
    { self->_data = nullptr; })

// StringName::StringName(char const*, bool)
WEAK_STUB(void, _stub_SN_char,
    "__ZN10StringNameC1EPKcb",
    (_StubStringName *self, const char *, bool),
    { self->_data = nullptr; })

// StringName::~StringName()
WEAK_STUB(void, _stub_SN_dtor,
    "__ZN10StringNameD1Ev",
    (_StubStringName *self),
    {})

// StringName::unref()
WEAK_STUB(void, _stub_SN_unref,
    "__ZN10StringName5unrefEv",
    (_StubStringName *self),
    {})

// -- Variant constructors ------------------------------------------------------

// Variant::Variant(bool)
WEAK_STUB(void, _stub_V_bool,
    "__ZN7VariantC1Eb",
    (_StubVariant *self, bool),
    { memset(self, 0, sizeof(*self)); })

// Variant::Variant(int)
WEAK_STUB(void, _stub_V_int,
    "__ZN7VariantC1Ei",
    (_StubVariant *self, int),
    { memset(self, 0, sizeof(*self)); })

// Variant::Variant(long long)
WEAK_STUB(void, _stub_V_ll,
    "__ZN7VariantC1Ex",
    (_StubVariant *self, long long),
    { memset(self, 0, sizeof(*self)); })

// Variant::Variant(double)
WEAK_STUB(void, _stub_V_double,
    "__ZN7VariantC1Ed",
    (_StubVariant *self, double),
    { memset(self, 0, sizeof(*self)); })

// Variant::Variant(char const*)
WEAK_STUB(void, _stub_V_cstr,
    "__ZN7VariantC1EPKc",
    (_StubVariant *self, const char *),
    { memset(self, 0, sizeof(*self)); })

// Variant::~Variant()
WEAK_STUB(void, _stub_V_dtor,
    "__ZN7VariantD1Ev",
    (_StubVariant *self),
    {})

// Variant::_clear_internal()
WEAK_STUB(void, _stub_V_clear,
    "__ZN7Variant15_clear_internalEv",
    (_StubVariant *self),
    {})

// -- Array ---------------------------------------------------------------------

// Array::Array()
WEAK_STUB(void, _stub_Arr_ctor,
    "__ZN5ArrayC1Ev",
    (_StubArray *self),
    { self->_p = nullptr; })

// Array::~Array()
WEAK_STUB(void, _stub_Arr_dtor,
    "__ZN5ArrayD1Ev",
    (_StubArray *self),
    {})

// -- Dictionary ----------------------------------------------------------------

// Dictionary::Dictionary()
WEAK_STUB(void, _stub_Dict_ctor,
    "__ZN10DictionaryC1Ev",
    (_StubDict *self),
    { self->_p = nullptr; })

// Dictionary::~Dictionary()
WEAK_STUB(void, _stub_Dict_dtor,
    "__ZN10DictionaryD1Ev",
    (_StubDict *self),
    {})

// -- Callable ------------------------------------------------------------------

// Callable::~Callable()
WEAK_STUB(void, _stub_Call_dtor,
    "__ZN8CallableD1Ev",
    (_StubCallable *self),
    {})

// -- Memory --------------------------------------------------------------------

// void* Memory::alloc_static<false>(unsigned long, bool)
// __ZN6Memory12alloc_staticILb0EEEPvmb
WEAK_STUB(void *, _stub_alloc,
    "__ZN6Memory12alloc_staticILb0EEEPvmb",
    (unsigned long bytes, bool),
    { return ::malloc(bytes); })

// Memory::free_static(void*, bool)
// __ZN6Memory11free_staticEPvb
WEAK_STUB(void, _stub_free,
    "__ZN6Memory11free_staticEPvb",
    (void *p, bool),
    { ::free(p); })

// -- GDTApplicationDelegate ----------------------------------------------------
// deeplink_service.mm's static initialiser calls:
//   [GDTApplicationDelegate addService:[DeeplinkService shared]]
// In the test bundle there is no real Godot app delegate; stub it to a no-op.

@interface GDTApplicationDelegate : NSObject
+ (void)addService:(id)service;
@end

@implementation GDTApplicationDelegate
+ (void)addService:(id)service { (void)service; }
@end

