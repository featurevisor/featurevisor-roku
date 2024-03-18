' @import /components/_testUtils/fakeClock.brs from @dazn/kopytko-unit-testing-framework
' @import /components/KopytkoTestSuite.brs from @dazn/kopytko-unit-testing-framework
' @import /components/promise/Promise.brs from @dazn/kopytko-utils
' @import /components/promise/PromiseReject.brs from @dazn/kopytko-utils
' @import /components/promise/PromiseResolve.brs from @dazn/kopytko-utils
' @mock /components/http/request/createRequest.brs from @dazn/kopytko-framework
' @mock /components/rokuComponents/Timer.brs from @dazn/kopytko-utils

function TestSuite__FeaturevisorInstance() as Object
  ts = KopytkoTestSuite()
  ts.name = "FeaturevisorInstance"

  beforeEach(sub (_ts as Object)
    mockFunction("createRequest").returnValue(Promise())

    m.__onActivation = sub (_data as Object) : end sub
    m.__onReady = sub () : end sub
    m.__onRefresh = sub () : end sub
    m.__onUpdate = sub () : end sub

    m.top.observeFieldScoped("activated", "__callback_onActivation")
    m.top.observeFieldScoped("ready", "__callback_onReady")
    m.top.observeFieldScoped("refreshed", "__callback_onRefresh")
    m.top.observeFieldScoped("updated", "__callback_onUpdate")

    m.__clock = fakeClock(m)
  end sub)

  afterEach(sub (_ts as Object)
    stopRefreshing()
    clear()
    m.top.unobserveFieldScoped("activated")
    m.top.unobserveFieldScoped("ready")
    m.top.unobserveFieldScoped("refreshed")
    m.top.unobserveFieldScoped("updated")
  end sub)

  it("should configure plain bucketBy", function (_ts as Object) as Object
    ' Give
    datafile = {
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
    }

    ' When
    initialize({ datafile: datafile })

    ' Then
    return [
      expect(isEnabled("test", { userId: "123" })).toBeTrue(),
      expect(getVariation("test", { userId: "123" })).toBe("control"),
    ]
  end function)

  it("should configure and bucketBy", function (_ts as Object) as String
    ' Give
    datafile = {
      schemaVersion: "1",
      revision: "1.0",
      features: [
        {
          key: "test",
          bucketBy: ["userId", "organizationId"],
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
    }

    ' When
    initialize({ datafile: datafile })

    ' Then
    return expect(getVariation("test", { userId: "123", organizationId: "456" })).toBe("control")
  end function)

  it("should configure or bucketBy", function (_ts as Object) as Object
    ' Give
    datafile = {
      schemaVersion: "1",
      revision: "1.0",
      features: [
        {
          key: "test",
          bucketBy: { "or": ["userId", "deviceId"] },
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
    }

    ' When
    initialize({ datafile: datafile })

    return [
      expect(isEnabled("test", { userId: "123", deviceId: "456" })).toBeTrue(),
      expect(getVariation("test", { userId: "123", deviceId: "456" })).toBe("control"),
      expect(getVariation("test", { deviceId: "456" })).toBe("control"),
    ]
  end function)

  it("should update ready when initialized", function (_ts as Object) as String
    ' Given
    m.__ready = false
    m.__onReady = sub ()
      m.__ready = true
    end sub
    datafile = {
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
    }

    ' When
    initialize({ datafile: datafile })

    ' Then
    return expect(m.__ready).toBeTrue()
  end function)

  it("should fetch datafile when initialized with datafileUrl", function (_ts as Object) as String
    ' When
    initialize({ datafileUrl: "http://localhost:3000/datafile.json" })

    ' Then
    return expect("createRequest").toHaveBeenCalledTimes(1)
  end function)

  it("should refresh datafile and update refreshed and updated when refreshed", function (_ts as Object) as Object
    ' Given
    m.__refreshed = false
    m.__refreshedCount = 0
    m.__revision = 1
    m.__updated = false
    m.__updatedCount = 0
    ' Update revision on refresh callback,
    ' so the onRefresh will be called one more time than onUpdate.
    m.__onRefresh = sub ()
      m.__revision += 1
      m.__refreshed = true
      m.__refreshedCount += 1
    end sub
    m.__onUpdate = sub ()
      m.__updated = true
      m.__updatedCount += 1
    end sub
    mockFunction("createRequest").implementation(function (_params as Object, context as Object) as Object
      return PromiseResolve({
        schemaVersion: "1",
        revision: context.__revision.toStr(),
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
      })
    end function)

    initialize({
      datafileUrl: "http://localhost:3000/datafile.json",
      refreshInterval: 1,
    })

    ' When
    m.__clock.tick(3.5)

    ' Then
    return [
      expect("createRequest").toHaveBeenCalledTimes(4),
      expect(m.__refreshed).toBeTrue(),
      expect(m.__updated).toBeTrue(),
      expect(m.__refreshedCount).toBe(3),
      expect(m.__updatedCount).toBe(2),
    ]
  end function)

  it("should update activated when feature is activated", function (_ts as Object) as Object
    ' Given
    m.__activated = false
    m.__onActivation = sub ()
      m.__activated = true
    end sub
    datafile = {
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
    }

    ' When
    initialize({ datafile: datafile })

    ' Then
    activatedVariation = activate("test", { userId: "123" })

    return [
      expect(m.__activated).toBeTrue(),
      expect(activatedVariation).toBe("control"),
    ]
  end function)

  it("should initialize with sticky features", function (_ts as Object) as Object
    ' Given
    m.__promise = Promise()
    datafile = {
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
                { variation: "control", range: [0, 0] },
                { variation: "treatment", range: [0, 100000] },
              ],
            },
          ],
        },
      ],
      attributes: [],
      segments: [],
    }
    mockFunction("createRequest").returnValue(m.__promise)

    ' When
    initialize({
      datafileUrl: "http://localhost:3000/datafile.json",
      stickyFeatures: {
        test: {
          enabled: true,
          variation: "control",
          variables: {
            color: "red",
          },
        },
      },
    })

    ' Then
    expected = [
      expect(getVariation("test", { userId: "123" })).toBe("control"),
      expect(getVariable("test", "color", { userId: "123" })).toBe("red"),
    ]

    m.__promise.resolve(datafile)

    expected.push(expect(getVariation("test", { userId: "123" })).toBe("control"))

    setStickyFeatures({})

    expected.push(expect(getVariation("test", { userId: "123" })).toBe("treatment"))

    return expected
  end function)

  it("should initialize with initial features", function (_ts as Object) as Object
    ' Given
    m.__promise = Promise()
    datafile = {
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
                { variation: "control", range: [0, 0] },
                { variation: "treatment", range: [0, 100000] },
              ],
            },
          ],
        },
      ],
      attributes: [],
      segments: [],
    }
    mockFunction("createRequest").returnValue(m.__promise)

    ' When
    initialize({
      initialFeatures: {
        test: {
          enabled: true,
          variation: "control",
          variables: {
            color: "red",
          },
        },
      },
      datafileUrl: "http://localhost:3000/datafile.json",
    })

    expected = [
      expect(getVariation("test", { userId: "123" })).toBe("control"),
      expect(getVariable("test", "color", { userId: "123" })).toBe("red"),
    ]

    m.__promise.resolve(datafile)

    ' Then
    expected.push(expect(getVariation("test", { userId: "123" })).toBe("treatment"))

    return expected
  end function)

  itEach([
    {
      datafile: {
        schemaVersion: "1",
        revision: "1.0",
        features: [
          {
            key: "requiredKey",
            bucketBy: "userId",
            traffic: [
              {
                key: "1",
                segments: "*",
                percentage: 0, ' disabled
                allocation: [],
              },
            ],
          },
          {
            key: "myKey",
            bucketBy: "userId",
            required: ["requiredKey"],
            traffic: [
              {
                key: "1",
                segments: "*",
                percentage: 100000,
                allocation: [],
              },
            ],
          },
        ],
        attributes: [],
        segments: [],
      },
      expected: false,
    },
    {
      datafile: {
        schemaVersion: "1",
        revision: "1.0",
        features: [
          {
            key: "requiredKey",
            bucketBy: "userId",
            traffic: [
              {
                key: "1",
                segments: "*",
                percentage: 100000, ' enabled
                allocation: [],
              },
            ],
          },
          {
            key: "myKey",
            bucketBy: "userId",
            required: ["requiredKey"],
            traffic: [
              {
                key: "1",
                segments: "*",
                percentage: 100000,
                allocation: [],
              },
            ],
          },
        ],
        attributes: [],
        segments: [],
      },
      expected: true,
    },
  ], "should honour simple required features", function (_ts as Object, params as Object) as String
    ' When
    initialize({ datafile: params.datafile })

    ' Then
    return expect(isEnabled("myKey")).toBe(params.expected)
  end function)

  itEach([
    {
      datafile: {
        schemaVersion: "1",
        revision: "1.0",
        features: [
          {
            key: "requiredKey",
            bucketBy: "userId",
            variations: [{ value: "control" }, { value: "treatment" }],
            traffic: [
              {
                key: "1",
                segments: "*",
                percentage: 100000,
                allocation: [
                  { variation: "control", range: [0, 0] },
                  { variation: "treatment", range: [0, 100000] },
                ],
              },
            ],
          },
          {
            key: "myKey",
            bucketBy: "userId",
            required: [
              {
                key: "requiredKey",
                variation: "control", ' different variation
              },
            ],
            traffic: [
              {
                key: "1",
                segments: "*",
                percentage: 100000,
                allocation: [],
              },
            ],
          },
        ],
        attributes: [],
        segments: [],
      },
      expected: false,
    },
    {
      datafile: {
        schemaVersion: "1",
        revision: "1.0",
        features: [
          {
            key: "requiredKey",
            bucketBy: "userId",
            variations: [{ value: "control" }, { value: "treatment" }],
            traffic: [
              {
                key: "1",
                segments: "*",
                percentage: 100000,
                allocation: [
                  { variation: "control", range: [0, 0] },
                  { variation: "treatment", range: [0, 100000] },
                ],
              },
            ],
          },
          {
            key: "myKey",
            bucketBy: "userId",
            required: [
              {
                key: "requiredKey",
                variation: "treatment", ' desired variation
              },
            ],
            traffic: [
              {
                key: "1",
                segments: "*",
                percentage: 100000,
                allocation: [],
              },
            ],
          },
        ],
        attributes: [],
        segments: [],
      },
      expected: true,
    },
  ], "should honour required features with variation", function (_ts as Object, params as Object) as String
    ' When
    initialize({ datafile: params.datafile })

    ' Then
    return expect(isEnabled("myKey")).toBe(params.expected)
  end function)

  it("should check if enabled for overridden flags from rules", function (_ts as Object) as Object
    ' Given
    datafile = {
      schemaVersion: "1",
      revision: "1.0",
      features: [
        {
          key: "test",
          bucketBy: "userId",
          traffic: [
            {
              key: "2",
              segments: ["netherlands"],
              percentage: 100000,
              enabled: false,
              allocation: [],
            },
            {
              key: "1",
              segments: "*",
              percentage: 100000,
              allocation: [],
            },
          ],
        },
      ],
      attributes: [],
      segments: [
        {
          key: "netherlands",
          conditions: FormatJson([
            {
              attribute: "country",
              operator: "equals",
              value: "nl",
            },
          ]),
        },
      ],
    }

    ' When
    initialize({ datafile: datafile })

    return [
      expect(isEnabled("test", { userId: "user-123", country: "de" })).toBeTrue()
      expect(isEnabled("test", { userId: "user-123", country: "nl" })).toBeFalse()
    ]
  end function)

  itEach([
    { bucketValue: 10000, expected: true },
    { bucketValue: 40000, expected: true },
    { bucketValue: 60000, expected: false },
    { bucketValue: 80000, expected: false },
  ], "should check if enabled for mutually exclusive features", function (_ts as Object, params as Object) as Object
    ' Given
    datafile = {
      schemaVersion: "1",
      revision: "1.0",
      features: [
        {
          key: "mutex",
          bucketBy: "userId",
          ranges: [[0, 50000]],
          traffic: [{ key: "1", segments: "*", percentage: 50000, allocation: [] }],
        },
      ],
      attributes: [],
      segments: [],
    }

    ' When
    initialize({
      configureAndInterceptStaticContext: { bucketValue: params.bucketValue },
      configureBucketValue: function (_feature as Object, _finalContext as Object, _bucketValue as Integer) as Integer
        return m.bucketValue
      end function,
      datafile: datafile,
    })

    ' Then
    return [
      expect(isEnabled("mutex", { userId: "123" })).toBe(params.expected),
      expect(isEnabled("trest", { userId: "123" })).toBeFalse(),
    ]
  end function)

  it("should get variation", function (_ts as Object) as Object
    ' Given
    datafile = {
      schemaVersion: "1",
      revision: "1.0",
      features: [
        {
          key: "test",
          bucketBy: "userId",
          variations: [{ value: "control" }, { value: "treatment" }],
          force: [
            {
              conditions: [{ attribute: "userId", operator: "equals", value: "user-gb" }],
              enabled: false,
            },
            {
              segments: ["netherlands"],
              enabled: false,
            },
          ],
          traffic: [
            {
              key: "1",
              segments: "*",
              percentage: 100000,
              allocation: [
                { variation: "control", range: [0, 0] },
                { variation: "treatment", range: [0, 100000] },
              ],
            },
          ],
        },
        {
          key: "testWithNoVariation",
          bucketBy: "userId",
          traffic: [
            {
              key: "1",
              segments: "*",
              percentage: 100000,
              allocation: [],
            },
          ],
        },
      ],
      attributes: [],
      segments: [
        {
          key: "netherlands",
          conditions: FormatJson([
            {
              attribute: "country",
              operator: "equals",
              value: "nl",
            },
          ]),
        },
      ],
    }

    ' When
    initialize({ datafile: datafile })

    ' Then
    expectedContext = { userId: "123" }

    return [
      expect(getVariation("test", expectedContext)).toBe("treatment"),
      expect(getVariation("test", { userId: "user-ch" })).toBe("treatment"),
      ' non existing
      expect(getVariation("nonExistingFeature", expectedContext)).toBeInvalid(),
      ' disabled
      expect(getVariation("test", { userId: "user-gb" })).toBeInvalid(),
      expect(getVariation("test", { userId: "123", country: "nl" })).toBeInvalid(),
      ' no variation
      expect(getVariation("testWithNoVariation", expectedContext)).toBeInvalid(),
    ]
  end function)

  it("should get variable", function (_ts as Object) as Object
    ' Given
    datafile = {
      schemaVersion: "1",
      revision: "1.0",
      features: [
        {
          key: "test",
          bucketBy: "userId",
          variablesSchema: [
            {
              key: "color",
              type: "string",
              defaultValue: "red",
            },
            {
              key: "showSidebar",
              type: "boolean",
              defaultValue: false,
            },
            {
              key: "sidebarTitle",
              type: "string",
              defaultValue: "sidebar title",
            },
            {
              key: "count",
              type: "integer",
              defaultValue: 0,
            },
            {
              key: "price",
              type: "double",
              defaultValue: 9.99,
            },
            {
              key: "paymentMethods",
              type: "array",
              defaultValue: ["paypal", "creditcard"],
            },
            {
              key: "flatConfig",
              type: "object",
              defaultValue: {
                key: "value",
              },
            },
            {
              key: "nestedConfig",
              type: "json",
              defaultValue: FormatJson({
                key: {
                  nested: "value",
                },
              }),
            },
          ],
          variations: [
            { value: "control" },
            {
              value: "treatment",
              variables: [
                {
                  key: "showSidebar",
                  value: true,
                  overrides: [
                    {
                      segments: ["netherlands"],
                      value: false,
                    },
                    {
                      conditions: [
                        {
                          attribute: "country",
                          operator: "equals",
                          value: "de",
                        },
                      ],
                      value: false,
                    },
                  ],
                },
                {
                  key: "sidebarTitle",
                  value: "sidebar title from variation",
                  overrides: [
                    {
                      segments: ["netherlands"],
                      value: "Dutch title",
                    },
                    {
                      conditions: [
                        {
                          attribute: "country",
                          operator: "equals",
                          value: "de",
                        },
                      ],
                      value: "German title",
                    },
                  ],
                },
              ],
            },
          ],
          force: [
            {
              conditions: [{ attribute: "userId", operator: "equals", value: "user-ch" }],
              enabled: true,
              variation: "control",
              variables: {
                color: "red and white",
              },
            },
            {
              conditions: [{ attribute: "userId", operator: "equals", value: "user-gb" }],
              enabled: false,
            },
            {
              conditions: [{ attribute: "userId", operator: "equals", value: "user-forced-variation" }],
              enabled: true,
              variation: "treatment",
            },
          ],
          traffic: [
            ' belgium
            {
              key: "2",
              segments: ["belgium"],
              percentage: 100000,
              allocation: [
                { variation: "control", range: [0, 0] },
                {
                  variation: "treatment",
                  range: [0, 100000],
                },
              ],
              variation: "control",
              variables: {
                color: "black",
              },
            },
            ' everyone
            {
              key: "1",
              segments: "*",
              percentage: 100000,
              allocation: [
                { variation: "control", range: [0, 0] },
                {
                  variation: "treatment",
                  range: [0, 100000],
                },
              ],
            },
          ],
        },
      ],
      attributes: [
        { key: "userId", type: "string", capture: true },
        { key: "country", type: "string" },
      ],
      segments: [
        {
          key: "netherlands",
          conditions: FormatJson([
            {
              attribute: "country",
              operator: "equals",
              value: "nl",
            },
          ]),
        },
        {
          key: "belgium",
          conditions: FormatJson([
            {
              attribute: "country",
              operator: "equals",
              value: "be",
            },
          ]),
        },
      ],
    }

    ' When
    initialize({ datafile: datafile })

    ' Then
    return [
      expect(getVariation("test", { userId: "123" })).toBe("treatment"),
      expect(getVariation("test", { userId: "123", country: "be" })).toBe("control"),
      expect(getVariation("test", { userId: "user-ch" })).toBe("control"),
      expect(getVariable("test", "color", { userId: "123" })).toBe("red"),
      expect(getVariableString("test", "color", { userId: "123" })).toBe("red"),
      expect(getVariable("test", "color", { userId: "123", country: "be" })).toBe("black"),
      expect(getVariable("test", "color", { userId: "user-ch" })).toBe("red and white"),
      expect(getVariable("test", "showSidebar", { userId: "123" })).toBeTrue(),
      expect(getVariableBoolean("test", "showSidebar", { userId: "123" })).toBeTrue(),
      expect(getVariableBoolean("test", "showSidebar", { userId: "123", country: "nl" })).toBeFalse(),
      expect(getVariableBoolean("test", "showSidebar", { userId: "123", country: "de" })).toBeFalse(),
      expect(getVariableString("test", "sidebarTitle", { userId: "user-forced-variation", country: "de" })).toBe("German title"),
      expect(getVariableString("test", "sidebarTitle", { userId: "user-forced-variation", country: "nl" })).toBe("Dutch title"),
      expect(getVariableString("test", "sidebarTitle", { userId: "user-forced-variation", country: "be" })).toBe("sidebar title from variation"),
      expect(getVariable("test", "count", { userId: "123" })).toBe(0),
      expect(getVariableInteger("test", "count", { userId: "123" })).toBe(0),
      expect(getVariable("test", "price", { userId: "123" })).toBe(9.99),
      expect(getVariableDouble("test", "price", { userId: "123" })).toBe(9.99),
      expect(getVariable("test", "paymentMethods", { userId: "123" })).toEqual(["paypal", "creditcard"]),
      expect(getVariableArray("test", "paymentMethods", { userId: "123" })).toEqual(["paypal", "creditcard"]),
      expect(getVariable("test", "flatConfig", { userId: "123" })).toEqual({ key: "value" }),
      expect(getVariableObject("test", "flatConfig", { userId: "123" })).toEqual({ key: "value" }),
      expect(getVariable("test", "nestedConfig", { userId: "123" })).toEqual({ key: { nested: "value" } }),
      expect(getVariableJSON("test", "nestedConfig", { userId: "123" })).toEqual({ key: { nested: "value" } }),
      ' non existing
      expect(getVariable("test", "nonExisting", { userId: "123" })).toBeInvalid(),
      expect(getVariable("nonExistingFeature", "nonExisting", { userId: "123" })).toBeInvalid(),
      ' disabled
      expect(getVariable("test", "color", { userId: "user-gb" })).toBeInvalid(),
    ]
  end function)

  it("should get variables without any variations", function (_ts as Object) as Object
    ' Given
    datafile = {
      schemaVersion: "1",
      revision: "1.0",
      attributes: [
        { key: "userId", type: "string", capture: true },
        { key: "country", type: "string" },
      ],
      segments: [
        {
          key: "netherlands",
          conditions: FormatJson([
            {
              attribute: "country",
              operator: "equals",
              value: "nl",
            },
          ]),
        },
      ],
      features: [
        {
          key: "test",
          bucketBy: "userId",
          variablesSchema: [
            {
              key: "color",
              type: "string",
              defaultValue: "red",
            },
          ],
          traffic: [
            {
              key: "1",
              segments: "netherlands",
              percentage: 100000,
              variables: {
                color: "orange",
              },
              allocation: [],
            },
            {
              key: "2",
              segments: "*",
              percentage: 100000,
              allocation: [],
            },
          ],
        },
      ],
    }

    ' When
    initialize({ datafile: datafile })

    ' Then
    return [
      ' test default value
      expect(getVariable("test", "color", { userId: "123" })).toBe("red"),
      ' test override
      expect(getVariable("test", "color", { userId: "123", country: "nl" })).toBe("orange"),
    ]
  end function)

  it("should check if enabled for individually named segments", function (_ts as Object) as Object
    ' Given
    datafile = {
      schemaVersion: "1",
      revision: "1.0",
      features: [
        {
          key: "test",
          bucketBy: "userId",
          traffic: [
            { key: "1", segments: "netherlands", percentage: 100000, allocation: [] },
            {
              key: "2",
              segments: FormatJson(["iphone", "unitedStates"]),
              percentage: 100000,
              allocation: [],
            },
          ],
        },
      ],
      attributes: [],
      segments: [
        {
          key: "netherlands",
          conditions: FormatJson([
            {
              attribute: "country",
              operator: "equals",
              value: "nl",
            },
          ]),
        },
        {
          key: "iphone",
          conditions: FormatJson([
            {
              attribute: "device",
              operator: "equals",
              value: "iphone",
            },
          ]),
        },
        {
          key: "unitedStates",
          conditions: FormatJson([
            {
              attribute: "country",
              operator: "equals",
              value: "us",
            },
          ]),
        },
      ],
    }

    ' When
    initialize({ datafile: datafile })

    ' Then
    return [
      expect(isEnabled("test")).toBeFalse(),
      expect(isEnabled("test", { userId: "123" })).toBeFalse(),
      expect(isEnabled("test", { userId: "123", country: "de" })).toBeFalse(),
      expect(isEnabled("test", { userId: "123", country: "us" })).toBeFalse(),
      expect(isEnabled("test", { userId: "123", country: "nl" })).toBeTrue(),
      expect(isEnabled("test", { userId: "123", country: "us", device: "iphone" })).toBeTrue(),
    ]
  end function)

  it("should not fail because of improperly formatted sem version", function (_ts as Object) as Object
    ' Given
    datafile = {
      schemaVersion: "1",
      revision: "1.0",
      features: [
        {
          key: "test",
          bucketBy: "userId",
          traffic: [
            { key: "0", segments: ["desktop", "version_gt5"], percentage: 100000 },
            { key: "1", segments: "mobile", percentage: 100000 },
            { key: "2", segments: "*", percentage: 0 },
          ],
        },
      ],
      attributes: [],
      segments: [
        {
          key: "desktop",
          conditions: FormatJson([{ attribute: "deviceType", operator: "equals", value: "desktop" }]),
        },
        {
          key: "mobile",
          conditions: FormatJson([{ attribute: "deviceType", operator: "equals", value: "mobile" }]),
        },
        {
          key: "version_gt5",
          conditions: FormatJson([{ attribute: "version", operator: "semverGreaterThan", value: "5.0" }]),
        },
      ],
    }

    ' When
    initialize({ datafile: datafile })

    ' Then
    return [
      expect(isEnabled("test", { deviceType: "desktop", version: "1.2.3" })).toBeFalse(),
      expect(isEnabled("test", { deviceType: "desktop", version: "5.5.0" })).toBeTrue(),
      expect(isEnabled("test", { deviceType: "mobile", version: "1.2.3" })).toBeTrue(),
      expect(isEnabled("test", { deviceType: "mobile", version: "7.0.A101.99gbm.lg" })).toBeTrue(),
      expect(isEnabled("test", { deviceType: "tablet", version: "5.5.A101.99gbm.lg" })).toBeFalse(),
    ]
  end function)

  return ts
end function

sub __callback_onActivation()
  m.__onActivation()
end sub

sub __callback_onReady()
  m.__onReady()
end sub

sub __callback_onRefresh()
  m.__onRefresh()
end sub

sub __callback_onUpdate()
  m.__onUpdate()
end sub
