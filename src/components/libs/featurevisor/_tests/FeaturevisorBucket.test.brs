' @import /components/KopytkoTestSuite.brs from @dazn/kopytko-unit-testing-framework

function TestSuite__FeaturevisorBucket() as Object
  ts = KopytkoTestSuite()
  ts.name = "FeaturevisorBucket"

  beforeEach(sub (_ts as Object)
    m.__MAX_BUCKETED_NUMBER = 100000
  end sub)

  itEach([
    "foo", "bar", "baz", "123adshlk348-93asdlk",
  ], "should return a number between 0 and 100000 for {0}", function (_ts as Object, value as String) as Object
    ' When
    result = featurevisorGetBucketedNumber(value)

    ' Then
    return [
      expect(result >= 0).toBeTrue(),
      expect(result <= m.__MAX_BUCKETED_NUMBER).toBeTrue(),
    ]
  end function)

  itEach([
    { value: "foo", expected: 20602 },
    { value: "bar", expected: 89144 },
    { value: "123.foo", expected: 3151 },
    { value: "123.bar", expected: 9710 },
    { value: "123.456.foo", expected: 14432 },
    { value: "123.456.bar", expected: 1982 },
  ], "should return ${expected} number for ${value}", function (_ts as Object, params as Object) as String
    ' When
    result = featurevisorGetBucketedNumber(params.value)

    ' Then
    return expect(result).toBe(params.expected)
  end function)

  return ts
end function
