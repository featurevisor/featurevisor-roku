' @import /components/KopytkoTestSuite.brs from @dazn/kopytko-unit-testing-framework
' @import /components/ArrayUtils.brs from @dazn/kopytko-utils
' @import /components/libs/featurevisor/FeaturevisorDatafileReader.brs

function TestSuite__FeaturevisorSegments() as Object
  ts = KopytkoTestSuite()
  ts.name = "FeaturevisorSegments"

  beforeEach(sub (_ts as Object)
    datafileContent = {
      schemaVersion: "1.0",
      revision: "1",
      features: [],
      attributes: [],
      segments: [
        {
          key: "mobileUsers",
          conditions: [
            { attribute: "deviceType", operator: "equals", value: "mobile" },
          ],
        },
        {
          key: "desktopUsers",
          conditions: [
            { attribute: "deviceType", operator: "equals", value: "desktop" },
          ],
        },
        {
          key: "chromeBrowser",
          conditions: [
            { attribute: "browser", operator: "equals", value: "chrome" },
          ],
        },
        {
          key: "firefoxBrowser",
          conditions: [
            { attribute: "browser", operator: "equals", value: "firefox" },
          ],
        },
        {
          key: "netherlands",
          conditions: [
            { attribute: "country", operator: "equals", value: "nl" },
          ],
        },
        {
          key: "germany",
          conditions: [
            { attribute: "country", operator: "equals", value: "de" },
          ],
        },
        {
          key: "version_5.5",
          conditions: [
            {
              "or": [
                { attribute: "version", operator: "equals", value: "5.5" },
                { attribute: "version", operator: "equals", value: 5.5 },
              ],
            },
          ],
        },
      ],
    }

    m.__arrayUtils = ArrayUtils()
    m.__datafileReader = FeaturevisorDatafileReader(datafileContent)
    m.__groups = [
      { key: "*", segments: "*" },
      { key: "dutchMobileUsers", segments: ["mobileUsers", "netherlands"] },
      { key: "dutchMobileUsers2", segments: { "and": ["mobileUsers", "netherlands"] } },
      { key: "dutchMobileOrDesktopUsers", segments: ["netherlands", { "or": ["mobileUsers", "desktopUsers"] }] },
      { key: "dutchMobileOrDesktopUsers2", segments: { "and": ["netherlands", { "or": ["mobileUsers", "desktopUsers"] }] } },
      { key: "germanMobileUsers", segments: [{ "and": ["mobileUsers", "germany"] }] },
      { key: "germanNonMobileUsers", segments: [{ "and": ["germany", { "not": ["mobileUsers"] }] }] },
      { key: "notVersion5.5", segments: [{ "not": ["version_5.5"] }] },
      { key: "improperSemver", segments: [{ "and": ["mobileUsers", { "not": ["version_5.5"] }] }] },
    ]
  end sub)

  it("should match everyone", function (_ts as Object) as Object
    ' Given
    group = m.__arrayUtils.find(m.__groups, { key: "*" })

    ' Then
    return [
      expect(featurevisorAllGroupSegmentsAreMatched(group.segments, {}, m.__datafileReader)).toBeTrue(),
      expect(featurevisorAllGroupSegmentsAreMatched(group.segments, { foo: "foo" }, m.__datafileReader)).toBeTrue(),
      expect(featurevisorAllGroupSegmentsAreMatched(group.segments, { foo: "bar" }, m.__datafileReader)).toBeTrue(),
    ]
  end function)

  it("should match dutchMobileUsers", function (_ts as Object) as Object
    ' Given
    group = m.__arrayUtils.find(m.__groups, { key: "dutchMobileUsers" })

    ' Then
    return [
      expect(featurevisorAllGroupSegmentsAreMatched(group.segments, {
        country: "nl",
        deviceType: "mobile",
      }, m.__datafileReader)).toBeTrue(),
      expect(featurevisorAllGroupSegmentsAreMatched(group.segments, {
        browser: "chrome",
        country: "nl",
        deviceType: "mobile",
      }, m.__datafileReader)).toBeTrue(),
      expect(featurevisorAllGroupSegmentsAreMatched(group.segments, {}, m.__datafileReader)).toBeFalse(),
      expect(featurevisorAllGroupSegmentsAreMatched(group.segments, {
        country: "de",
        deviceType: "mobile",
      }, m.__datafileReader)).toBeFalse(),
    ]
  end function)

  it("should match dutchMobileUsers2", function (_ts as Object) as Object
    ' Given
    group = m.__arrayUtils.find(m.__groups, { key: "dutchMobileUsers" })

    ' Then
    return [
      expect(featurevisorAllGroupSegmentsAreMatched(group.segments, {
        country: "nl",
        deviceType: "mobile",
      }, m.__datafileReader)).toBeTrue(),
      expect(featurevisorAllGroupSegmentsAreMatched(group.segments, {
        browser: "chrome",
        country: "nl",
        deviceType: "mobile",
      }, m.__datafileReader)).toBeTrue(),
      expect(featurevisorAllGroupSegmentsAreMatched(group.segments, {}, m.__datafileReader)).toBeFalse(),
      expect(featurevisorAllGroupSegmentsAreMatched(group.segments, {
        country: "de",
        deviceType: "mobile",
      }, m.__datafileReader)).toBeFalse(),
    ]
  end function)

  it("should match dutchMobileUsers2", function (_ts as Object) as Object
    ' Given
    group = m.__arrayUtils.find(m.__groups, { key: "dutchMobileUsers2" })

    ' Then
    return [
      expect(featurevisorAllGroupSegmentsAreMatched(group.segments, {
        country: "nl",
        deviceType: "mobile",
      }, m.__datafileReader)).toBeTrue(),
      expect(featurevisorAllGroupSegmentsAreMatched(group.segments, {
        browser: "chrome",
        country: "nl",
        deviceType: "mobile",
      }, m.__datafileReader)).toBeTrue(),
      expect(featurevisorAllGroupSegmentsAreMatched(group.segments, {}, m.__datafileReader)).toBeFalse(),
      expect(featurevisorAllGroupSegmentsAreMatched(group.segments, {
        country: "de",
        deviceType: "mobile",
      }, m.__datafileReader)).toBeFalse(),
    ]
  end function)

  it("should match dutchMobileOrDesktopUsers", function (_ts as Object) as Object
    ' Given
    group = m.__arrayUtils.find(m.__groups, { key: "dutchMobileOrDesktopUsers" })

    ' Then
    return [
      expect(featurevisorAllGroupSegmentsAreMatched(group.segments, {
        country: "nl",
        deviceType: "mobile",
      }, m.__datafileReader)).toBeTrue(),
      expect(featurevisorAllGroupSegmentsAreMatched(group.segments, {
        browser: "chrome",
        country: "nl",
        deviceType: "mobile",
      }, m.__datafileReader)).toBeTrue(),
      expect(featurevisorAllGroupSegmentsAreMatched(group.segments, {
        country: "nl",
        deviceType: "desktop",
      }, m.__datafileReader)).toBeTrue(),
      expect(featurevisorAllGroupSegmentsAreMatched(group.segments, {
        browser: "chrome",
        country: "nl",
        deviceType: "desktop",
      }, m.__datafileReader)).toBeTrue(),
      expect(featurevisorAllGroupSegmentsAreMatched(group.segments, {}, m.__datafileReader)).toBeFalse(),
      expect(featurevisorAllGroupSegmentsAreMatched(group.segments, {
        country: "de",
        deviceType: "mobile",
      }, m.__datafileReader)).toBeFalse(),
      expect(featurevisorAllGroupSegmentsAreMatched(group.segments, {
        country: "de",
        deviceType: "desktop",
      }, m.__datafileReader)).toBeFalse(),
    ]
  end function)

  it("should match dutchMobileOrDesktopUsers2", function (_ts as Object) as Object
    ' Given
    group = m.__arrayUtils.find(m.__groups, { key: "dutchMobileOrDesktopUsers2" })

    ' Then
    return [
      expect(featurevisorAllGroupSegmentsAreMatched(group.segments, {
        country: "nl",
        deviceType: "mobile",
      }, m.__datafileReader)).toBeTrue(),
      expect(featurevisorAllGroupSegmentsAreMatched(group.segments, {
        browser: "chrome",
        country: "nl",
        deviceType: "mobile",
      }, m.__datafileReader)).toBeTrue(),
      expect(featurevisorAllGroupSegmentsAreMatched(group.segments, {
        country: "nl",
        deviceType: "desktop",
      }, m.__datafileReader)).toBeTrue(),
      expect(featurevisorAllGroupSegmentsAreMatched(group.segments, {
        browser: "chrome",
        country: "nl",
        deviceType: "desktop",
      }, m.__datafileReader)).toBeTrue(),
      expect(featurevisorAllGroupSegmentsAreMatched(group.segments, {}, m.__datafileReader)).toBeFalse(),
      expect(featurevisorAllGroupSegmentsAreMatched(group.segments, {
        country: "de",
        deviceType: "mobile",
      }, m.__datafileReader)).toBeFalse(),
      expect(featurevisorAllGroupSegmentsAreMatched(group.segments, {
        country: "de",
        deviceType: "desktop",
      }, m.__datafileReader)).toBeFalse(),
    ]
  end function)

  it("should match germanMobileUsers", function (_ts as Object) as Object
    ' Given
    group = m.__arrayUtils.find(m.__groups, { key: "germanMobileUsers" })

    ' Then
    return [
      expect(featurevisorAllGroupSegmentsAreMatched(group.segments, {
        country: "de",
        deviceType: "mobile",
      }, m.__datafileReader)).toBeTrue(),
      expect(featurevisorAllGroupSegmentsAreMatched(group.segments, {
        browser: "chrome",
        country: "de",
        deviceType: "mobile",
      }, m.__datafileReader)).toBeTrue(),
      expect(featurevisorAllGroupSegmentsAreMatched(group.segments, {}, m.__datafileReader)).toBeFalse(),
      expect(featurevisorAllGroupSegmentsAreMatched(group.segments, {
        country: "nl",
        deviceType: "mobile",
      }, m.__datafileReader)).toBeFalse(),
    ]
  end function)

  it("should match germanNonMobileUsers", function (_ts as Object) as Object
    ' Given
    group = m.__arrayUtils.find(m.__groups, { key: "germanNonMobileUsers" })

    ' Then
    return [
      expect(featurevisorAllGroupSegmentsAreMatched(group.segments, {
        country: "de",
        deviceType: "desktop",
      }, m.__datafileReader)).toBeTrue(),
      expect(featurevisorAllGroupSegmentsAreMatched(group.segments, {
        browser: "chrome",
        country: "de",
        deviceType: "desktop",
      }, m.__datafileReader)).toBeTrue(),
      expect(featurevisorAllGroupSegmentsAreMatched(group.segments, {}, m.__datafileReader)).toBeFalse(),
      expect(featurevisorAllGroupSegmentsAreMatched(group.segments, {
        country: "nl",
        deviceType: "desktop",
      }, m.__datafileReader)).toBeFalse(),
    ]
  end function)

  it("should match notVersion5.5", function (_ts as Object) as Object
    ' Given
    group = m.__arrayUtils.find(m.__groups, { key: "notVersion5.5" })

    ' Then
    return [
      expect(featurevisorAllGroupSegmentsAreMatched(group.segments, {}, m.__datafileReader)).toBeTrue(),
      expect(featurevisorAllGroupSegmentsAreMatched(group.segments, { version: "5.6" }, m.__datafileReader)).toBeTrue(),
      expect(featurevisorAllGroupSegmentsAreMatched(group.segments, { version: 5.6 }, m.__datafileReader)).toBeTrue(),
      expect(featurevisorAllGroupSegmentsAreMatched(group.segments, { version: "5.7" }, m.__datafileReader)).toBeTrue(),
      expect(featurevisorAllGroupSegmentsAreMatched(group.segments, { version: 5.7 }, m.__datafileReader)).toBeTrue(),
      expect(featurevisorAllGroupSegmentsAreMatched(group.segments, { version: "5.5" }, m.__datafileReader)).toBeFalse(),
      expect(featurevisorAllGroupSegmentsAreMatched(group.segments, { version: 5.5 }, m.__datafileReader)).toBeFalse(),
    ]
  end function)

  it("should omit segment with improperly formatted sem version", function (_ts as Object) as Object
    ' Given
    group = m.__arrayUtils.find(m.__groups, { key: "improperSemver" })

    ' Then
    return [
      expect(featurevisorAllGroupSegmentsAreMatched(group.segments, {
        deviceType: "mobile",
        version: "asd",
      }, m.__datafileReader)).toBeTrue(),
      expect(featurevisorAllGroupSegmentsAreMatched(group.segments, {
        deviceType: "mobile",
        version: "5.5.A101.99gbm.lg",
      }, m.__datafileReader)).toBeTrue(),
      expect(featurevisorAllGroupSegmentsAreMatched(group.segments, {
        deviceType: "unknown",
        version: "5.5.A101.99gbm.lg",
      }, m.__datafileReader)).toBeFalse(),
    ]
  end function)

  return ts
end function
