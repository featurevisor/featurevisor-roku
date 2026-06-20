' @import /components/ArrayUtils.brs from @dazn/kopytko-utils
' @import /components/getProperty.brs from @dazn/kopytko-utils
' @import /components/getType.brs from @dazn/kopytko-utils

function FeaturevisorDatafileReader(datafile as Object) as Object
  prototype = {}

  prototype._arrayUtils = ArrayUtils()

  prototype._attributes = []
  prototype._features = Invalid
  prototype._featuresAreArray = false
  prototype._revision = ""
  prototype._schemaVersion = ""
  prototype._segments = Invalid
  prototype._segmentsAreArray = false

  _constructor = function (context as Object, datafile as Object) as Object
    context._attributes = getProperty(datafile, ["attributes"], [])
    context._revision = getProperty(datafile, ["revision"], "")
    context._schemaVersion = getProperty(datafile, ["schemaVersion"], "")

    features = getProperty(datafile, ["features"], {})
    if (getType(features) = "roArray")
      context._features = features
      context._featuresAreArray = true
    else
      context._features = features
      context._featuresAreArray = false
    end if

    segments = getProperty(datafile, ["segments"], {})
    if (getType(segments) = "roArray")
      context._segments = segments
      context._segmentsAreArray = true
    else
      context._segments = segments
      context._segmentsAreArray = false
    end if

    return context
  end function

  prototype.getAllAttributes = function () as Object
    return m._attributes
  end function

  prototype.getAttribute = function (attributeKey as String) as Object
    return m._arrayUtils.find(m._attributes, { key: attributeKey })
  end function

  prototype.getFeature = function (featureKey as String) as Object
    if (m._features = Invalid) then return Invalid

    if (m._featuresAreArray)
      return m._arrayUtils.find(m._features, { key: featureKey })
    end if

    return m._features[featureKey]
  end function

  prototype.getFeatureKeys = function () as Object
    if (m._features = Invalid) then return []

    if (m._featuresAreArray)
      return m._arrayUtils.map(m._features, function (feature as Object, _context as Object) as String
        return feature.key
      end function, {})
    end if

    keys = []
    for each key in m._features
      keys.push(key)
    end for

    return keys
  end function

  prototype.getRevision = function () as String
    return m._revision
  end function

  prototype.getSchemaVersion = function () as String
    return m._schemaVersion
  end function

  prototype.getSegment = function (segmentKey as String) as Object
    if (m._segments = Invalid) then return Invalid

    segment = Invalid
    if (m._segmentsAreArray)
      segment = m._arrayUtils.find(m._segments, { key: segmentKey })
    else
      segment = m._segments[segmentKey]
    end if

    if (segment = Invalid) then return Invalid

    return m._parseJsonConditionsIfStringified(segment, "conditions")
  end function

  prototype._parseJsonConditionsIfStringified = function (record as Object, key as String) as Object
    if (getType(record[key]) = "roString" AND record[key] <> "*")
      try
        record[key] = ParseJson(record[key])
      catch error
        print "Featurevisor - Error parsing JSON: ";error
      end try
    end if

    return record
  end function

  return _constructor(prototype, datafile)
end function
