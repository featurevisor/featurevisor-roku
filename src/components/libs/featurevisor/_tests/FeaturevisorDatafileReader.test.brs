' @import /components/KopytkoTestSuite.brs from @dazn/kopytko-unit-testing-framework

function TestSuite__FeaturevisorDatafileReader() as Object
  ts = KopytkoTestSuite()
  ts.name = "FeaturevisorDatafileReader"

  it("should return requested entities", function (_ts as Object) as Object
    ' Given
    datafileJson = {
      schemaVersion: "1",
      revision: "1",
      attributes: [
        { key: "userId", type: "string", capture: true },
        { key: "country", type: "string" },
      ],
      segments: [
        {
          key: "netherlands",
          conditions: [
            { attribute: "country", operator: "equals", value: "nl" },
          ],
        },
        {
          key: "germany",
          conditions: FormatJson([
            { attribute: "country", operator: "equals", value: "de" },
          ]),
        },
      ],
      features: [
        {
          key: "test",
          bucketBy: "userId",
          variations: [
            { value: "control" },
            {
              value: "treatment",
              variables: [
                { key: "showSidebar", value: true },
              ],
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
      ],
    }

    ' When
    reader = FeaturevisorDatafileReader(datafileJson)

    ' Then
    return [
      expect(reader.getRevision()).toBe("1"),
      expect(reader.getSchemaVersion()).toBe("1"),
      expect(reader.getAllAttributes()).toEqual(datafileJson.attributes),
      expect(reader.getAttribute("userId")).toEqual(datafileJson.attributes[0]),
      expect(reader.getSegment("netherlands")).toEqual(datafileJson.segments[0]),
      expect(reader.getSegment("germany").conditions[0].value).toBe("de"),
      expect(reader.getSegment("belgium")).toBeInvalid(),
      expect(reader.getFeature("test")).toEqual(datafileJson.features[0]),
      expect(reader.getFeature("test2")).toBeInvalid(),
    ]
  end function)

  ' F9: v2 datafile with dict-based features and segments
  it("should return requested entities from v2 dict-based datafile", function (_ts as Object) as Object
    ' Given
    v2Datafile = {
      schemaVersion: "2",
      revision: "2",
      attributes: [
        { key: "userId", type: "string", capture: true },
      ],
      segments: {
        netherlands: {
          key: "netherlands",
          conditions: [{ attribute: "country", operator: "equals", value: "nl" }],
        },
      },
      features: {
        myFeature: {
          key: "myFeature",
          bucketBy: "userId",
          variablesSchema: {
            color: { key: "color", type: "string", defaultValue: "red" },
          },
          traffic: [
            {
              key: "1",
              segments: "*",
              percentage: 100000,
              allocation: [{ variation: "control", range: [0, 100000] }],
            },
          ],
        },
      },
    }

    ' When
    reader = FeaturevisorDatafileReader(v2Datafile)

    ' Then
    return [
      expect(reader.getRevision()).toBe("2"),
      expect(reader.getSchemaVersion()).toBe("2"),
      expect(reader.getSegment("netherlands")).toEqual(v2Datafile.segments.netherlands),
      expect(reader.getSegment("unknown")).toBeInvalid(),
      expect(reader.getFeature("myFeature")).toEqual(v2Datafile.features.myFeature),
      expect(reader.getFeature("unknown")).toBeInvalid(),
    ]
  end function)

  ' F9: getFeatureKeys() returns all feature keys
  it("should return all feature keys", function (_ts as Object) as Object
    ' Given
    v2Datafile = {
      schemaVersion: "2",
      revision: "1",
      attributes: [],
      segments: {},
      features: {
        featureA: { key: "featureA", bucketBy: "userId", traffic: [] },
        featureB: { key: "featureB", bucketBy: "userId", traffic: [] },
      },
    }

    ' When
    reader = FeaturevisorDatafileReader(v2Datafile)
    keys = reader.getFeatureKeys()

    ' Then
    return [
      expect(keys).toHaveLength(2),
      expect(keys).toContain("featureA"),
      expect(keys).toContain("featureB"),
    ]
  end function)

  it("should return variable keys for a feature (v1 array schema)", function (_ts as Object) as Object
    ' Given
    datafile = {
      schemaVersion: "1",
      revision: "1",
      attributes: [],
      segments: [],
      features: [
        {
          key: "test",
          bucketBy: "userId",
          variablesSchema: [
            { key: "color", type: "string", defaultValue: "red" },
            { key: "count", type: "integer", defaultValue: 0 },
          ],
          traffic: [],
        },
      ],
    }
    reader = FeaturevisorDatafileReader(datafile)

    ' When
    keys = reader.getVariableKeys("test")

    ' Then
    return [
      expect(keys).toHaveLength(2),
      expect(keys).toContain("color"),
      expect(keys).toContain("count"),
      expect(reader.getVariableKeys("missing")).toEqual([]),
    ]
  end function)

  it("should return variable keys for a feature (v2 dict schema)", function (_ts as Object) as Object
    ' Given
    datafile = {
      schemaVersion: "2",
      revision: "1",
      attributes: [],
      segments: {},
      features: {
        test: {
          key: "test",
          bucketBy: "userId",
          variablesSchema: {
            color: { type: "string", defaultValue: "red" },
            size: { type: "string", defaultValue: "medium" },
          },
          traffic: [],
        },
      },
    }
    reader = FeaturevisorDatafileReader(datafile)

    ' When
    keys = reader.getVariableKeys("test")

    ' Then
    return [
      expect(keys).toHaveLength(2),
      expect(keys).toContain("color"),
      expect(keys).toContain("size"),
    ]
  end function)

  it("should check hasVariations", function (_ts as Object) as Object
    ' Given
    datafile = {
      schemaVersion: "1",
      revision: "1",
      attributes: [],
      segments: [],
      features: [
        {
          key: "withVariations",
          bucketBy: "userId",
          variations: [{ value: "control" }, { value: "treatment" }],
          traffic: [],
        },
        {
          key: "noVariations",
          bucketBy: "userId",
          traffic: [],
        },
      ],
    }
    reader = FeaturevisorDatafileReader(datafile)

    ' Then
    return [
      expect(reader.hasVariations("withVariations")).toBeTrue(),
      expect(reader.hasVariations("noVariations")).toBeFalse(),
      expect(reader.hasVariations("missing")).toBeFalse(),
    ]
  end function)

  ' F9: v1 array-based datafile backward compatibility
  it("should still work with v1 array-based features and segments", function (_ts as Object) as Object
    ' Given
    v1Datafile = {
      schemaVersion: "1",
      revision: "1",
      attributes: [],
      segments: [
        { key: "segA", conditions: [{ attribute: "country", operator: "equals", value: "nl" }] },
      ],
      features: [
        { key: "featureA", bucketBy: "userId", traffic: [] },
      ],
    }

    ' When
    reader = FeaturevisorDatafileReader(v1Datafile)
    keys = reader.getFeatureKeys()

    ' Then
    return [
      expect(reader.getFeature("featureA")).toEqual(v1Datafile.features[0]),
      expect(reader.getSegment("segA")).toEqual(v1Datafile.segments[0]),
      expect(keys).toHaveLength(1),
      expect(keys).toContain("featureA"),
    ]
  end function)

  return ts
end function
