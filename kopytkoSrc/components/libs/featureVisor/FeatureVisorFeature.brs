' @import /components/ArrayUtils.brs from @dazn/kopytko-utils
' @import /components/getType.brs from @dazn/kopytko-utils
' @import /components/libs/featureVisor/FeatureVisorConditions.brs
' @import /components/libs/featureVisor/FeatureVisorSegments.brs

function featureVisorParseFromStringifiedSegments(value as Dynamic) as Dynamic
  if (getType(value) = "roString" AND (value.instr("{") <> -1 OR value.instr("[") <> -1)) then return ParseJson(value)

  return value
end function

function featureVisorGetMatchedTraffic(traffic as Object, context as Object, datafileReader as Object) as Object
  if (getType(traffic) = "roArray")
    return ArrayUtils().find(traffic, function (trafficItem as Object, context as Object) as Boolean
      conditions = featureVisorParseFromStringifiedSegments(trafficItem.segments)

      return featureVisorAllGroupSegmentsAreMatched(conditions, context.context, context.datafileReader)
    end function, { context: context, datafileReader: datafileReader })
  end if

  return Invalid
end function

function featureVisorGetMatchedTrafficAndAllocation(traffic as Object, context as Object, bucketValue as Integer, datafileReader as Object) as Object
  matchedTraffic = featureVisorGetMatchedTraffic(traffic, context, datafileReader)

  if (matchedTraffic = Invalid)
    return {
      matchedTraffic: Invalid,
      matchedAllocation: Invalid,
    }
  end if

  matchedAllocation = ArrayUtils().find(matchedTraffic.allocation, function (allocation as Object, context as Object) as Boolean
    return allocation.range <> Invalid AND allocation.range[0] <= context.bucketValue AND allocation.range[1] >= context.bucketValue
  end function, { bucketValue: bucketValue })

  return {
    matchedTraffic: matchedTraffic,
    matchedAllocation: matchedAllocation,
  }
end function

function featureVisorFindForceFromFeature(feature as Object, context as Object, datafileReader as Object) as Object
  if (feature.force = Invalid) then return Invalid

  return ArrayUtils().find(feature.force, function (feaure as Object, context as Object) as Boolean
    if (feaure.conditions <> Invalid)
      return featureVisorAllConditionsAreMatched(feaure.conditions, context.context)
    end if

    if (feaure.segments <> Invalid)
      return featureVisorAllGroupSegmentsAreMatched(feaure.segments, context.context, context.datafileReader)
    end if

    return false
  end function, { context: context, datafileReader: datafileReader })
end function
