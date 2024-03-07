' @import /components/KopytkoTestSuite.brs from @dazn/kopytko-unit-testing-framework

function TestSuite__FeatureVisorDatafileReader() as Object
  ts = KopytkoTestSuite()
  ts.name = "FeatureVisorDatafileReader"

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
    reader = FeatureVisorDatafileReader(datafileJson)

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

  return ts
end function
