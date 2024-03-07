' @import /components/ArrayUtils.brs from @dazn/kopytko-utils
' @import /components/getProperty.brs from @dazn/kopytko-utils
' @import /components/getType.brs from @dazn/kopytko-utils

function FeatureVisorDatafileReader(datafile as Object) as Object
  prototype = {}

  prototype._arrayUtils = ArrayUtils()

  prototype._attributes = []
  prototype._features = []
  prototype._revision = ""
  prototype._schemaVersion = ""
  prototype._segments = []

  _constructor = function (context as Object, datafile as Object) as Object
    context._attributes = getProperty(datafile, ["attributes"], [])
    context._features = getProperty(datafile, ["features"], [])
    context._revision = getProperty(datafile, ["revision"], "")
    context._schemaVersion = getProperty(datafile, ["schemaVersion"], "")
    context._segments = getProperty(datafile, ["segments"], [])

    return context
  end function

  prototype.getAllAttributes = function () as Object
    return m._attributes
  end function

  prototype.getAttribute = function (attributeKey as String) as Object
    return m._arrayUtils.find(m._attributes, { key: attributeKey })
  end function

  prototype.getFeature = function (featureKey as String) as Object
    return m._arrayUtils.find(m._features, { key: featureKey })
  end function

  prototype.getRevision = function () as String
    return m._revision
  end function

  prototype.getSchemaVersion = function () as String
    return m._schemaVersion
  end function

  prototype.getSegment = function (segmentKey as String) as Object
    segment = m._arrayUtils.find(m._segments, { key: segmentKey })

    if (segment = Invalid) then return Invalid

    return m._parseJsonConditionsIfStringified(segment, "conditions")
  end function

  prototype._parseJsonConditionsIfStringified = function (record as Object, key as String) as Object
    if (getType(record[key]) = "roString" AND record[key] <> "*")
      try
        record[key] = ParseJson(record[key])
      catch error
        print "FeatureVisor - Error parsing JSON: ";error
      end try
    end if
  
    return record
  end function

  return _constructor(prototype, datafile)
end function
