' @import /components/ArrayUtils.brs from @dazn/kopytko-utils
' @import /components/getType.brs from @dazn/kopytko-utils
' @import /components/libs/featurevisor/FeaturevisorConditions.brs

function featurevisorAllGroupSegmentsAreMatched(groupSegments as Dynamic, context as Object, datafileReader as Object) as Boolean
  _arrayUtils = ArrayUtils()

  if (getType(groupSegments) = "roString" AND groupSegments = "*") then return true

  if (getType(groupSegments) = "roString")
    segment = datafileReader.getSegment(groupSegments)

    if (segment <> Invalid)
      return featurevisorAllConditionsAreMatched(segment.conditions, context)
    end if

    return false
  end if

  if (getType(groupSegments) = "roAssociativeArray")
    if (groupSegments.doesExist("and") AND getType(groupSegments["and"]) = "roArray")
      filtered = _arrayUtils.filter(groupSegments["and"], function (groupSegment as Object, context as Object) as Boolean
        return featurevisorAllGroupSegmentsAreMatched(groupSegment, context.context, context.datafileReader)
      end function, { context: context, datafileReader: datafileReader })

      return groupSegments["and"].count() = filtered.count()
    end if

    if (groupSegments.doesExist("or") AND getType(groupSegments["or"]) = "roArray")
      matchingGroupSegment = _arrayUtils.find(groupSegments["or"], function (groupSegment as Object, context as Object) as Boolean
        return featurevisorAllGroupSegmentsAreMatched(groupSegment, context.context, context.datafileReader)
      end function, { context: context, datafileReader: datafileReader })

      return matchingGroupSegment <> Invalid
    end if

    if (groupSegments.doesExist("not") AND getType(groupSegments["not"]) = "roArray")
      filtered = _arrayUtils.filter(groupSegments["not"], function (groupSegment as Object, context as Object) as Boolean
        return featurevisorAllGroupSegmentsAreMatched(groupSegment, context.context, context.datafileReader)
      end function, { context: context, datafileReader: datafileReader })

      return NOT (groupSegments["not"].count() = filtered.count())
    end if
  end if

  if (getType(groupSegments) = "roArray")
    filtered = _arrayUtils.filter(groupSegments, function (groupSegment as Object, context as Object) as Boolean
      return featurevisorAllGroupSegmentsAreMatched(groupSegment, context.context, context.datafileReader)
    end function, { context: context, datafileReader: datafileReader })

    return groupSegments.count() = filtered.count()
  end if

  return false
end function
