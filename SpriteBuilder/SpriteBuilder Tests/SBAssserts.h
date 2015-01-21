/// \def SBAssertStringsEqual(a1, a2)
/// \brief Generates a failure when given strings are not equal, format output is provided
/// \param a1 a string to be compared with a2
/// \param a2 a string to be compared with a1
#define SBAssertStringsEqual(a1, a2) \
    XCTAssertTrue([a1 isEqualToString:a2], @"\"%@\" and \"%@\" are not equal strings", a1, a2)

#define SBAssertEqualStrings(a1, a2, format...) \
do { \
    @try { \
        id a1value = (a1); \
        id a2value = (a2); \
        if (a1value == a2value) continue; \
        if ([a1value isKindOfClass:[NSString class]] && \
        [a2value isKindOfClass:[NSString class]] && \
        [a1value compare:a2value options:0] == NSOrderedSame) continue; \
        _XCTRegisterFailure(self, _XCTFailureDescription(_XCTAssertion_EqualObjects, 0, @#a1, @#a2, a1value, a2value),format); \
    } \
    @catch (id exception) { \
        _XCTRegisterFailure(self, _XCTFailureDescription(_XCTAssertion_EqualObjects, 1, @#a1, @#a2, [exception reason]),format); \
    } \
} while(0)
