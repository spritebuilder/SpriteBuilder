/// \def SBAssertStringsEqual(a1, a2)
/// \brief Generates a failure when given strings are not equal, format output is provided
/// \param a1 a string to be compared with a2
/// \param a2 a string to be compared with a1
#define SBAssertStringsEqual(a1, a2) \
    XCTAssertTrue([a1 isEqualToString:a2], @"\"%@\" and \"%@\" are not equal strings", a1, a2)
