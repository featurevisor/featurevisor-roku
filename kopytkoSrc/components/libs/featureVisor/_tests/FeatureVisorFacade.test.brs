' @import /components/KopytkoTestSuite.brs from @dazn/kopytko-unit-testing-framework
' @import /components/promise/Promise.brs from @dazn/kopytko-utils
' @import /components/promise/PromiseReject.brs from @dazn/kopytko-utils
' @import /components/promise/PromiseResolve.brs from @dazn/kopytko-utils

function TestSuite__FeatureVisorFacade() as Object
  ts = KopytkoTestSuite()
  ts.name = "FeatureVisorFacade"

  beforeEach(sub (_ts as Object)
    m.__featureVisorFacade = FeatureVisorFacade()
  end sub)

  afterEach(sub (_ts as Object)
    m.__featureVisorFacade.clear()
    m.__featureVisorFacade = Invalid
  end sub)

  it("should call onReady when initialized", function (_ts as Object) as Object
    ' Given
    passedContext = { readyCount: 0 }

    ' When
    m.__featureVisorFacade.onReady(sub ()
      m.readyCount += 1
    end sub, passedContext)
    m.__featureVisorFacade.initialize({
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
      expect(m.__featureVisorFacade.isReady()).toBeTrue()
    ]
  end function)

  it("should call onActivation when activated feature", function (_ts as Object) as Object
    ' Given
    passedContext = { activated: false }

    ' When
    m.__featureVisorFacade.initialize({
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
    activatedVariation = m.__featureVisorFacade.activate("test", {
      userId: "123",
    })

    return [
      expect(passedContext.activated).toBeTrue(),
      expect(activatedVariation).toBe("control"),
    ]
  end function)

  return ts
end function
