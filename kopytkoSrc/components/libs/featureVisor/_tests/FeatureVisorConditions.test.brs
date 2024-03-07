' @import /components/KopytkoTestSuite.brs from @dazn/kopytko-unit-testing-framework

function TestSuite__FeatureVisorConditions() as Object
  ts = KopytkoTestSuite()
  ts.name = "FeatureVisorConditions"

  testCases = [
    {
      conditions: [{ attribute: "browser_type", operator: "equals", value: "chrome" }],
      operator: "equals",
      match: { browser_type: "chrome" },
      notMatch: { browser_type: "firefox" },
    },
    {
      conditions: [{ attribute: "browser_type", operator: "notEquals", value: "chrome" }],
      operator: "notEquals",
      match: { browser_type: "firefox" },
      notMatch: { browser_type: "chrome" },
    },
    {
      conditions: [{ attribute: "name", operator: "startsWith", value: "Hello" }],
      operator: "startsWith",
      match: { name: "Hello World" },
      notMatch: { name: "Hi World" },
    },
    {
      conditions: [{ attribute: "name", operator: "endsWith", value: "World" }],
      operator: "endsWith",
      match: { name: "Hello World" },
      notMatch: { name: "Hello Universe" },
    },
    {
      conditions: [{ attribute: "name", operator: "contains", value: "Hello" }],
      operator: "contains",
      match: { name: "Hello World" },
      notMatch: { name: "Hi World" },
    },
    {
      conditions: [{ attribute: "name", operator: "notContains", value: "Hello" }],
      operator: "notContains",
      match: { name: "Hi World" },
      notMatch: { name: "Hello World" },
    },
    {
      conditions: [{ attribute: "browser_type", operator: "in", value: ["chrome", "firefox"] }],
      operator: "in",
      match: { browser_type: "firefox" },
      notMatch: { browser_type: "edge" },
    },
    {
      conditions: [{ attribute: "browser_type", operator: "notIn", value: ["chrome", "firefox"] }],
      operator: "notIn",
      match: { browser_type: "edge" },
      notMatch: { browser_type: "firefox" },
    },
    {
      conditions: [{ attribute: "age", operator: "greaterThan", value: 18 }],
      operator: "greaterThan",
      match: { age: 19 },
      notMatch: { age: 17 },
    },
    {
      conditions: [{ attribute: "age", operator: "greaterThanOrEquals", value: 18 }],
      operator: "greaterThanOrEquals",
      match: { age: 18 },
      notMatch: { age: 17 },
    },
    {
      conditions: [{ attribute: "age", operator: "lessThan", value: 18 }],
      operator: "lessThan",
      match: { age: 17 },
      notMatch: { age: 19 },
    },
    {
      conditions: [{ attribute: "age", operator: "lessThanOrEquals", value: 18 }],
      operator: "lessThanOrEquals",
      match: { age: 18 },
      notMatch: { age: 19 },
    },
    {
      conditions: [{ attribute: "version", operator: "semverEquals", value: "1.0.0" }],
      operator: "semverEquals",
      match: { version: "1.0.0" },
      notMatch: { version: "2.0.0" },
    },
    {
      conditions: [{ attribute: "version", operator: "semverNotEquals", value: "1.0.0" }],
      operator: "semverNotEquals",
      match: { version: "2.0.0" },
      notMatch: { version: "1.0.0" },
    },
    {
      conditions: [{ attribute: "version", operator: "semverGreaterThan", value: "1.0.0" }],
      operator: "semverGreaterThan",
      match: { version: "2.0.0" },
      notMatch: { version: "0.9.0" },
    },
    {
      conditions: [{ attribute: "version", operator: "semverGreaterThanOrEquals", value: "1.0.0" }],
      operator: "semverGreaterThanOrEquals",
      match: { version: "1.0.0" },
      notMatch: { version: "0.9.0" },
    },
    {
      conditions: [{ attribute: "version", operator: "semverLessThan", value: "1.0.0" }],
      operator: "semverLessThan",
      match: { version: "0.9.0" },
      notMatch: { version: "1.1.0" },
    },
    {
      conditions: [{ attribute: "version", operator: "semverLessThanOrEquals", value: "1.0.0" }],
      operator: "semverLessThanOrEquals",
      match: { version: "1.0.0" },
      notMatch: { version: "1.1.0" },
    },
    {
      conditions: [{ attribute: "date", operator: "before", value: "2023-05-13T16:23:59Z" }],
      operator: "before",
      match: { date: "2023-05-12T00:00:00Z" },
      notMatch: { date: "2023-05-14T00:00:00Z" },
    },
    {
      conditions: [{ attribute: "date", operator: "after", value: "2023-05-13T16:23:59Z" }],
      operator: "after",
      match: { date: "2023-05-14T00:00:00Z" },
      notMatch: { date: "2023-05-12T00:00:00Z" },
    },
    {
      conditions: [{ attribute: "date", operator: "after", value: "2023-05-13T16:23:59Z" }],
      operator: "after",
      match: { date: "2023-05-14T00:00:00Z" },
      notMatch: { date: "2023-05-12T00:00:00Z" },
    },
  ]

  itEach(testCases, "should match for ${operator}", function (_ts as Object, params as Object) as String
    ' When
    result = featureVisorAllConditionsAreMatched(params.conditions, params.match)

    ' Then
    return expect(result).toBeTrue()
  end function)

  itEach(testCases, "should not match for ${operator}", function (_ts as Object, params as Object) as String
    ' When
    result = featureVisorAllConditionsAreMatched(params.conditions, params.notMatch)

    ' Then
    return expect(result).toBeFalse()
  end function)

  testEach([
    {
      conditions: { attribute: "browser_type", operator: "equals", value: "chrome" },
      context: { browser_type: "chrome" },
      name: "should match with exact single condition",
    },
    {
      conditions: [
        { attribute: "browser_type", operator: "equals", value: "chrome" },
      ],
      context: { browser_type: "chrome" },
      name: "should match with exact condition",
    },
    {
      conditions: [],
      context: { browser_type: "chrome" },
      name: "should match with empty conditions",
    },
    {
      conditions: [
        { attribute: "browser_type", operator: "equals", value: "chrome" },
      ],
      context: { browser_type: "chrome", browser_version: "1.0" },
      name: "should match with extra conditions that are not needed",
    },
    {
      conditions: [
        { attribute: "browser_type", operator: "equals", value: "chrome" },
        { attribute: "browser_version", operator: "equals", value: "1.0" },
      ],
      context: { browser_type: "chrome", browser_version: "1.0", foo: "bar" },
      name: "should match with multiple conditions",
    },
  ], "simple condition - ${name}", function (_ts as Object, params as Object) as String
    ' When
    result = featureVisorAllConditionsAreMatched(params.conditions, params.context)

    ' Then
    return expect(result).toBeTrue()
  end function)

  testEach([
    {
      conditions: [
        {
          "and": [
            { attribute: "browser_type", operator: "equals", value: "chrome" },
          ],
        },
      ],
      context: { browser_type: "chrome" },
      name: "should match with one condition inside AND",
    },
    {
      conditions: [
        {
          "and": [
            { attribute: "browser_type", operator: "equals", value: "chrome" },
            { attribute: "browser_version", operator: "equals", value: "1.0" },
          ],
        },
      ],
      context: { browser_type: "chrome", browser_version: "1.0" },
      name: "should match with multiple conditions inside AND",
    },
  ], "AND condition - ${name}", function (_ts as Object, params as Object) as String
    ' When
    result = featureVisorAllConditionsAreMatched(params.conditions, params.context)

    ' Then
    return expect(result).toBeTrue()
  end function)

  testEach([
    {
      conditions: [
        {
          "or": [
            { attribute: "browser_type", operator: "equals", value: "chrome" },
          ],
        },
      ],
      context: { browser_type: "chrome" },
      name: "should match with one OR condition",
    },
    {
      conditions: [
        {
          "or": [
            { attribute: "browser_type", operator: "equals", value: "chrome" },
            { attribute: "browser_version", operator: "equals", value: "1.0" },
          ],
        },
      ],
      context: { browser_version: "1.0" },
      name: "should match with multiple conditions inside OR",
    },
  ], "OR condition - ${name}", function (_ts as Object, params as Object) as String
    ' When
    result = featureVisorAllConditionsAreMatched(params.conditions, params.context)

    ' Then
    return expect(result).toBeTrue()
  end function)

  testEach([
    {
      conditions: [
        {
          "not": [
            { attribute: "browser_type", operator: "equals", value: "chrome" },
          ],
        },
      ],
      context: { browser_type: "firefox" },
      name: "should match with one NOT condition",
    },
    {
      conditions: [
        {
          "not": [
            { attribute: "browser_type", operator: "equals", value: "chrome" },
            { attribute: "browser_version", operator: "equals", value: "1.0" },
          ],
        },
      ],
      context: { browser_type: "chrome", browser_version: "2.0" },
      name: "should match with multiple conditions inside NOT",
    },
  ], "NOT condition - ${name}", function (_ts as Object, params as Object) as String
    ' When
    result = featureVisorAllConditionsAreMatched(params.conditions, params.context)

    ' Then
    return expect(result).toBeTrue()
  end function)

  testEach([
    {
      conditions: [
        {
          "and": [
            { attribute: "browser_type", operator: "equals", value: "chrome" },
            {
              "or": [
                { attribute: "browser_version", operator: "equals", value: "1.0" },
                { attribute: "browser_version", operator: "equals", value: "2.0" },
              ],
            },
          ],
        },
      ],
      context: { browser_type: "chrome", browser_version: "2.0" },
      name: "should match with OR inside AND",
    },
    {
      conditions: [
        { attribute: "country", operator: "equals", value: "nl" },
        {
          "and": [
            { attribute: "browser_type", operator: "equals", value: "chrome" },
            {
              "or": [
                { attribute: "browser_version", operator: "equals", value: "1.0" },
                { attribute: "browser_version", operator: "equals", value: "2.0" },
              ],
            },
          ],
        },
      ],
      context: { country: "nl", browser_type: "chrome", browser_version: "2.0" },
      name: "should match with plain conditions, followed by OR inside AND",
    },
    {
      conditions: [
        {
          "or": [
            { attribute: "browser_type", operator: "equals", value: "chrome" },
            {
              "and": [
                { attribute: "device_type", operator: "equals", value: "mobile" },
                { attribute: "orientation", operator: "equals", value: "portrait" },
              ],
            },
          ],
        },
      ],
      context: { browser_type: "firefox", device_type: "mobile", orientation: "portrait" },
      name: "should match with AND inside OR",
    },
    {
      conditions: [
        { attribute: "country", operator: "equals", value: "nl" },
        {
          "or": [
            { attribute: "browser_type", operator: "equals", value: "chrome" },
            {
              "and": [
                { attribute: "device_type", operator: "equals", value: "mobile" },
                { attribute: "orientation", operator: "equals", value: "portrait" },
              ],
            },
          ],
        },
      ],
      context: { country: "nl", browser_type: "firefox", device_type: "mobile", orientation: "portrait" },
      name: "should match with plain conditions, followed by AND inside OR",
    },
  ], "nested conditions - ${name}", function (_ts as Object, params as Object) as String
    ' When
    result = featureVisorAllConditionsAreMatched(params.conditions, params.context)

    ' Then
    return expect(result).toBeTrue()
  end function)

  return ts
end function
