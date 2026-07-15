' @import /components/KopytkoTestSuite.brs from @dazn/kopytko-unit-testing-framework

function TestSuite__FeaturevisorSDK() as Object
  ts = KopytkoTestSuite()
  ts.name = "FeaturevisorSDK"

  beforeEach(sub (_ts as Object)
    m.__featurevisorSDK = FeaturevisorSDK()
  end sub)

  afterEach(sub (_ts as Object)
    m.__featurevisorSDK.clear()
    m.__featurevisorSDK = Invalid
  end sub)

  it("should call onReady when initialized", function (_ts as Object) as Object
    ' Given
    passedContext = { readyCount: 0 }

    ' When
    m.__featurevisorSDK.onReady(sub ()
      m.readyCount += 1
    end sub, passedContext)
    m.__featurevisorSDK.createInstance({
      datafile: {
        schemaVersion: "1",
        revision: "1.0",
        features: [],
        attributes: [],
        segments: [],
      },
    })

    ' Then
    return [
      expect(passedContext.readyCount).toBe(1),
      expect(m.__featurevisorSDK.isReady()).toBeTrue(),
    ]
  end function)

  it("should call onActivation when activated feature", function (_ts as Object) as Object
    ' Given
    passedContext = { activated: false }

    ' When
    m.__featurevisorSDK.createInstance({
      onActivation: {
        callback: sub (_payload as Object)
          m.activated = true
        end sub,
        context: passedContext,
      },
      datafile: {
        schemaVersion: "1",
        revision: "1.0",
        features: [
          {
            key: "test",
            bucketBy: "userId",
            variations: [{ value: "control" }, { value: "treatment" }],
            traffic: [
              {
                key: "1",
                segments: "*",
                percentage: 100000,
                allocation: [
                  { variation: "control", range: [0, 100000] },
                  { variation: "treatment", range: [0, 0] },
                ],
              },
            ],
          },
        ],
        attributes: [],
        segments: [],
      },
    })

    ' Then
    activatedVariation = m.__featurevisorSDK.activate("test", {
      userId: "123",
    })

    return [
      expect(passedContext.activated).toBeTrue(),
      expect(activatedVariation).toBe("control"),
    ]
  end function)

  it("should create instance via createFeaturevisor", function (_ts as Object) as Object
    ' When
    m.__featurevisorSDK.createFeaturevisor({
      datafile: {
        schemaVersion: "1",
        revision: "1.0",
        features: [
          {
            key: "test",
            bucketBy: "userId",
            traffic: [{ key: "1", segments: "*", percentage: 100000, allocation: [] }],
          },
        ],
        attributes: [],
        segments: [],
      },
    })

    ' Then
    return [
      expect(m.__featurevisorSDK.isReady()).toBeTrue(),
      expect(m.__featurevisorSDK.isEnabled("test", { userId: "123" })).toBeTrue(),
    ]
  end function)

  it("should call onError when an error-level diagnostic is reported", function (_ts as Object) as Object
    ' Given
    passedContext = { diagnostic: Invalid }

    ' When
    m.__featurevisorSDK.createFeaturevisor({
      onError: {
        callback: sub (payload as Object)
          m.diagnostic = payload.diagnostic
        end sub,
        context: passedContext,
      },
      datafile: {
        schemaVersion: "1",
        revision: "1.0",
        features: [
          {
            key: "test",
            bucketBy: { bad: true },
            traffic: [{ key: "1", segments: "*", percentage: 100000, allocation: [] }],
          },
        ],
        attributes: [],
        segments: [],
      },
    })
    m.__featurevisorSDK.isEnabled("test", { userId: "123" })

    ' Then
    return [
      expect(passedContext.diagnostic).toBeValid(),
      expect(passedContext.diagnostic.code).toBe("invalid_bucket_by"),
    ]
  end function)

  it("should evaluate spawned child with child context over parent context", function (_ts as Object) as Object
    ' Given
    m.__featurevisorSDK.createInstance({
      datafile: __featurevisorSDKSpawnDatafile(),
      context: { country: "de" },
    })

    ' When
    child = m.__featurevisorSDK.spawn({ country: "nl" })

    ' Then
    return [
      expect(m.__featurevisorSDK.isEnabled("regional", { userId: "1" })).toBeFalse(),
      expect(child.isEnabled("regional", { userId: "1" })).toBeTrue(),
      expect(child.getContext().country).toBe("nl"),
      expect(child.getVariableString("varFeature", "color", { userId: "1" })).toBe("red"),
    ]
  end function)

  it("should replace parent sticky with child sticky in spawned child", function (_ts as Object) as Object
    ' Given
    m.__featurevisorSDK.createInstance({
      datafile: __featurevisorSDKSpawnDatafile(),
      stickyFeatures: { stickyFeature: { enabled: true } },
    })

    ' When
    childPlain = m.__featurevisorSDK.spawn({})
    childWithSticky = m.__featurevisorSDK.spawn({}, { sticky: { regional: { enabled: true } } })

    ' Then
    return [
      expect(m.__featurevisorSDK.isEnabled("stickyFeature")).toBeTrue(),
      expect(childPlain.isEnabled("stickyFeature")).toBeFalse(),
      expect(childWithSticky.isEnabled("regional", { userId: "1" })).toBeTrue(),
      expect(childWithSticky.isEnabled("stickyFeature")).toBeFalse(),
    ]
  end function)

  it("should handle child setContext and setSticky locally with callbacks", function (_ts as Object) as Object
    ' Given
    m.__featurevisorSDK.createInstance({
      datafile: __featurevisorSDKSpawnDatafile(),
      context: { country: "de" },
    })
    child = m.__featurevisorSDK.spawn({})
    capture = { contextPayload: Invalid, stickyPayload: Invalid }
    child.onContextChanged(sub (payload as Object)
      m.contextPayload = payload
    end sub, capture)
    child.onStickyChanged(sub (payload as Object)
      m.stickyPayload = payload
    end sub, capture)

    ' When
    child.setContext({ country: "nl" })
    child.setSticky({ stickyFeature: { enabled: true } })

    ' Then
    return [
      expect(capture.contextPayload.context.country).toBe("nl"),
      expect(capture.contextPayload.replaced).toBeFalse(),
      expect(capture.stickyPayload.features).toContain("stickyFeature"),
      expect(child.isEnabled("regional", { userId: "1" })).toBeTrue(),
      expect(child.isEnabled("stickyFeature")).toBeTrue(),
      expect(m.__featurevisorSDK.getContext().country).toBe("de"),
      expect(m.__featurevisorSDK.isEnabled("stickyFeature")).toBeFalse(),
    ]
  end function)

  it("should stop child callbacks after child close", function (_ts as Object) as String
    ' Given
    m.__featurevisorSDK.createInstance({ datafile: __featurevisorSDKSpawnDatafile() })
    child = m.__featurevisorSDK.spawn({})
    capture = { count: 0 }
    child.onContextChanged(sub (_payload as Object)
      m.count++
    end sub, capture)

    ' When
    child.setContext({ country: "nl" })
    child.close()
    child.setContext({ country: "de" })

    ' Then
    return expect(capture.count).toBe(1)
  end function)

  return ts
end function

function __featurevisorSDKSpawnDatafile() as Object
  return {
    schemaVersion: "1",
    revision: "1.0",
    features: [
      {
        key: "regional",
        bucketBy: "userId",
        traffic: [{ key: "1", segments: ["nl"], percentage: 100000, allocation: [] }],
      },
      {
        key: "stickyFeature",
        bucketBy: "userId",
        traffic: [{ key: "1", segments: "*", percentage: 0, allocation: [] }],
      },
      {
        key: "varFeature",
        bucketBy: "userId",
        variablesSchema: [{ key: "color", type: "string", defaultValue: "red" }],
        traffic: [{ key: "1", segments: "*", percentage: 100000, allocation: [] }],
      },
    ],
    attributes: [],
    segments: [
      { key: "nl", conditions: [{ attribute: "country", operator: "equals", value: "nl" }] },
    ],
  }
end function
