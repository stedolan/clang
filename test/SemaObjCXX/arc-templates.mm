// RUN: %clang_cc1 -fobjc-nonfragile-abi -fobjc-runtime-has-weak -fsyntax-only -fobjc-arc -verify -fblocks %s

@interface A
@end

template<typename T, typename U>
struct is_same {
  static const bool value = false;
};

template<typename T>
struct is_same<T, T> {
  static const bool value = true;
};

// Instantiation for reference/pointer types that will get lifetime
// adjustments.
template<typename T>
struct X0 {
  typedef T* pointer; // okay: ends up being strong.
  typedef T& reference; // okay: ends up being strong
};

void test_X0() {
  X0<id> x0id;
  X0<A*> x0a;
  X0<__strong A*> x0sa;

  id __strong *ptr;
  id __strong val;
  X0<__strong id>::pointer &ptr_ref = ptr;
  X0<__strong id>::reference ref = val;
}

int check_infer_strong[is_same<id, __strong id>::value? 1 : -1];

// Check template argument deduction (e.g., for specialization) using
// lifetime qualifiers.
template<typename T>
struct is_pointer_strong {
  static const bool value = false;
};

template<typename T>
struct is_pointer_strong<__strong T*> {
  static const bool value = true;
};

int check_ptr_strong1[is_pointer_strong<__strong id*>::value? 1 : -1];
int check_ptr_strong2[is_pointer_strong<__weak id*>::value? -1 : 1];
int check_ptr_strong3[is_pointer_strong<__autoreleasing id*>::value? -1 : 1];
int check_ptr_strong4[is_pointer_strong<__unsafe_unretained id*>::value? -1 : 1];
int check_ptr_strong5[is_pointer_strong<id>::value? -1 : 1];

// Check substitution into lifetime-qualified dependent types.
template<typename T>
struct make_strong_pointer {
  typedef __strong T *type;
};

template<typename T>
struct make_strong_pointer<__weak T> {
  typedef __strong T *type;
};

template<typename T>
struct make_strong_pointer<__autoreleasing T> {
  typedef __strong T *type;
};

template<typename T>
struct make_strong_pointer<__unsafe_unretained T> {
  typedef __strong T *type;
};

// Adding qualifiers
int check_make_strong1[is_same<make_strong_pointer<id>::type, __strong id *>::value ? 1 : -1];
int check_make_strong2[is_same<make_strong_pointer<A*>::type, A* __strong *>::value ? 1 : -1];

// Adding redundant qualifiers
int check_make_strong3[is_same<make_strong_pointer<__strong id>::type, __strong id *>::value ? 1 : -1];
int check_make_strong4[is_same<make_strong_pointer<__strong A*>::type, A* __strong *>::value ? 1 : -1];

// Adding nonsensical qualifiers.
int check_make_strong5[is_same<make_strong_pointer<int>::type, int *>::value ? 1 : -1];
int check_make_strong6[is_same<make_strong_pointer<__weak id>::type, __strong id *>::value ? 1 : -1];

template<typename T>
struct make_weak {
  typedef __weak T type;
};

int check_make_weak0[is_same<make_weak<id>::type, __weak id>::value? 1 : -1];
int check_make_weak1[is_same<make_weak<__strong id>::type, __weak id>::value? 1 : -1];
int check_make_weak2[is_same<make_weak<__autoreleasing id>::type, __weak id>::value? 1 : -1];

template<typename T>
struct make_weak_fail {
  typedef T T_type;
  typedef __weak T_type type; // expected-error{{the type 'T_type' (aka '__weak id') already has retainment attributes set on it}} \
  // expected-error{{the type 'T_type' (aka '__strong id') already has retainment attributes set on it}}
};

int check_make_weak_fail0[is_same<make_weak_fail<__weak id>::type, __weak id>::value? 1 : -1]; // expected-note{{in instantiation of template class 'make_weak_fail<__weak id>' requested here}}

int check_make_weak_fail1[is_same<make_weak_fail<id>::type, __weak id>::value? -1 : 1]; // expected-note{{in instantiation of template class 'make_weak_fail<id>' requested here}}

// Check template argument deduction from function templates.
template<typename T> struct identity { };

template<typename T> identity<T> accept_strong_ptr(__strong T*);
template<typename T> identity<T> accept_strong_ref(__strong T&);

template<typename T> identity<T> accept_any_ptr(T*);
template<typename T> identity<T> accept_any_ref(T&);

void test_func_deduction_id() {
  __strong id *sip;
  __weak id *wip;
  __autoreleasing id *aip;
  __unsafe_unretained id *uip;

  identity<id> res1 = accept_strong_ptr(sip);
  identity<__strong id> res2 = accept_any_ptr(sip);

  __strong id si;
  __weak id wi;
  __autoreleasing id ai;
  __unsafe_unretained id ui;
  identity<id> res3 = accept_strong_ref(si);
  identity<__strong id> res4 = accept_any_ref(si);
  identity<__weak id> res5 = accept_any_ref(wi);
  identity<__autoreleasing id> res6 = accept_any_ref(ai);
  identity<__unsafe_unretained id> res7 = accept_any_ref(ui);
}

void test_func_deduction_A() {
  __strong A * *sip;
  __weak A * *wip;
  __autoreleasing A * *aip;
  __unsafe_unretained A * *uip;

  identity<A *> res1 = accept_strong_ptr(sip);
  identity<__strong A *> res2 = accept_any_ptr(sip);

  __strong A * si;
  __weak A * wi;
  __autoreleasing A * ai;
  __unsafe_unretained A * ui;
  identity<A *> res3 = accept_strong_ref(si);
  identity<__strong A *> res4 = accept_any_ref(si);
  identity<__weak A *> res5 = accept_any_ref(wi);
  identity<__autoreleasing A *> res6 = accept_any_ref(ai);
  identity<__unsafe_unretained A *> res7 = accept_any_ref(ui);
}

// Test partial ordering (qualified vs. non-qualified).
template<typename T>
struct classify_pointer_pointer {
  static const unsigned value = 0;
};

template<typename T>
struct classify_pointer_pointer<T*> {
  static const unsigned value = 1;
};

template<typename T>
struct classify_pointer_pointer<__strong T*> {
  static const unsigned value = 2;
};

template<typename T>
struct classify_pointer_pointer<__weak T*> {
  static const unsigned value = 3;
};

template<typename T>
struct classify_pointer_pointer<T&> {
  static const unsigned value = 4;
};

template<typename T>
struct classify_pointer_pointer<__strong T&> {
  static const unsigned value = 5;
};

template<typename T>
struct classify_pointer_pointer<__weak T&> {
  static const unsigned value = 6;
};

int classify_ptr1[classify_pointer_pointer<int>::value == 0? 1 : -1];
int classify_ptr2[classify_pointer_pointer<int *>::value == 1? 1 : -1];
int classify_ptr3[classify_pointer_pointer<id __strong *>::value == 2? 1 : -1];
int classify_ptr4[classify_pointer_pointer<id __weak *>::value == 3? 1 : -1];
int classify_ptr5[classify_pointer_pointer<int&>::value == 4? 1 : -1];
int classify_ptr6[classify_pointer_pointer<id __strong&>::value == 5? 1 : -1];
int classify_ptr7[classify_pointer_pointer<id __weak&>::value == 6? 1 : -1];
int classify_ptr8[classify_pointer_pointer<id __autoreleasing&>::value == 4? 1 : -1];
int classify_ptr9[classify_pointer_pointer<id __unsafe_unretained&>::value == 4? 1 : -1];
int classify_ptr10[classify_pointer_pointer<id __autoreleasing *>::value == 1? 1 : -1];
int classify_ptr11[classify_pointer_pointer<id __unsafe_unretained *>::value == 1? 1 : -1];
int classify_ptr12[classify_pointer_pointer<int *>::value == 1? 1 : -1];
int classify_ptr13[classify_pointer_pointer<A * __strong *>::value == 2? 1 : -1];
int classify_ptr14[classify_pointer_pointer<A * __weak *>::value == 3? 1 : -1];
int classify_ptr15[classify_pointer_pointer<int&>::value == 4? 1 : -1];
int classify_ptr16[classify_pointer_pointer<A * __strong&>::value == 5? 1 : -1];
int classify_ptr17[classify_pointer_pointer<A * __weak&>::value == 6? 1 : -1];
int classify_ptr18[classify_pointer_pointer<A * __autoreleasing&>::value == 4? 1 : -1];
int classify_ptr19[classify_pointer_pointer<A * __unsafe_unretained&>::value == 4? 1 : -1];
int classify_ptr20[classify_pointer_pointer<A * __autoreleasing *>::value == 1? 1 : -1];
int classify_ptr21[classify_pointer_pointer<A * __unsafe_unretained *>::value == 1? 1 : -1];

template<typename T> int& qual_vs_unqual_ptr(__strong T*);
template<typename T> double& qual_vs_unqual_ptr(__weak T*);
template<typename T> float& qual_vs_unqual_ptr(T*);
template<typename T> int& qual_vs_unqual_ref(__strong T&);
template<typename T> double& qual_vs_unqual_ref(__weak T&);
template<typename T> float& qual_vs_unqual_ref(T&);

void test_qual_vs_unqual_id() {
  __strong id *sip;
  __weak id *wip;
  __autoreleasing id *aip;
  __unsafe_unretained id *uip;

  int &ir1 = qual_vs_unqual_ptr(sip);
  double &dr1 = qual_vs_unqual_ptr(wip);
  float &fr1 = qual_vs_unqual_ptr(aip);
  float &fr2 = qual_vs_unqual_ptr(uip);

  int &ir2 = qual_vs_unqual_ref(*sip);
  double &dr2 = qual_vs_unqual_ref(*wip);
  float &fr3 = qual_vs_unqual_ref(*aip);
  float &fr4 = qual_vs_unqual_ref(*uip);
}

void test_qual_vs_unqual_a() {
  __strong A * *sap;
  __weak A * *wap;
  __autoreleasing A * *aap;
  __unsafe_unretained A * *uap;

  int &ir1 = qual_vs_unqual_ptr(sap);
  double &dr1 = qual_vs_unqual_ptr(wap);
  float &fr1 = qual_vs_unqual_ptr(aap);
  float &fr2 = qual_vs_unqual_ptr(uap);

  int &ir2 = qual_vs_unqual_ref(*sap);
  double &dr2 = qual_vs_unqual_ref(*wap);
  float &fr3 = qual_vs_unqual_ref(*aap);
  float &fr4 = qual_vs_unqual_ref(*uap);
}
