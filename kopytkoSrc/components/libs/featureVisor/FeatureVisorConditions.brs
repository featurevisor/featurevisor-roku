' @import /components/ArrayUtils.brs from @dazn/kopytko-utils
' @import /components/getType.brs from @dazn/kopytko-utils
' @import /components/libs/compareVersions.brs from compare-versions-roku

function featureVisorAllConditionsAreMatched(condition as Object, context as Object) as Boolean
  functionScope = {}

  functionScope._arrayUtils = ArrayUtils()

  functionScope._allConditionsAreMatched = function (conditions as Object, context as Object) as Object
    if (conditions = Invalid) then return true

    if (getType(conditions) = "roArray")
      filtered = m._arrayUtils.filter(conditions, function (item as Object, context as Object) as Boolean
        return context.functionScope._allConditionsAreMatched(item, context.context)
      end function, { context: context, functionScope: m })

      return conditions.count() = filtered.count()
    end if

    if (conditions.doesExist("attribute")) then return m._conditionIsMatched(conditions, context)

    if (conditions.doesExist("and") AND getType(conditions["and"]) = "roArray")
      filtered = m._arrayUtils.filter(conditions["and"], function (item as Object, context as Object) as Boolean
        return context.functionScope._allConditionsAreMatched(item, context.context)
      end function, { context: context, functionScope: m })

      return conditions["and"].count() = filtered.count()
    end if

    if (conditions.doesExist("or") AND getType(conditions["or"]) = "roArray")
      anyItemFound = m._arrayUtils.find(conditions["or"], function (item as Object, context as Object) as Boolean
        return context.functionScope._allConditionsAreMatched(item, context.context)
      end function, { context: context, functionScope: m })

      return anyItemFound <> Invalid
    end if

    if (conditions.doesExist("not") AND getType(conditions["not"]) = "roArray")
      filtered = m._arrayUtils.filter(conditions["not"], function (_item as Object, context as Object) as Boolean
        return context.functionScope._allConditionsAreMatched({ "and": context.conditionsNot }, context.context)
      end function, { conditionsNot: conditions["not"], context: context, functionScope: m })

      return NOT (conditions["not"].count() = filtered.count())
    end if

    return false
  end function

  functionScope._conditionIsMatched = function (condition as Object, context as Object) as Boolean
    if (condition = Invalid) then return true
    if (condition.doesExist("operator") AND condition.doesExist("attribute") AND condition.doesExist("value"))
      if (condition["operator"] = "before" OR condition["operator"] = "after")
        if (getType(context[condition.attribute]) = "roString")
          dateInContext = m._toDateTime(context[condition.attribute])
        else
          dateInContext = context[condition.attribute]
        end if

        if (getType(condition.value) = "roString")
          dateInCondition = m._toDateTime(condition.value)
        else
          dateInCondition = condition.value
        end if
  
        if (condition["operator"] = "before")
          return dateInContext.asSeconds() < dateInCondition.asSeconds()
        end if
  
        return dateInContext.asSeconds() > dateInCondition.asSeconds()
      else if (getType(context[condition.attribute]) = "roString" AND getType(condition.value) = "roArray")
        if (condition["operator"] = "in")
          return m._arrayUtils.contains(condition.value, function (item as String, context as Object) as Boolean
            return item = context.compareValue
          end function, { compareValue: context[condition.attribute] })
        else if (condition["operator"] = "notIn")
          return NOT m._arrayUtils.contains(condition.value, function (item as String, context as Object) as Boolean
            return item = context.compareValue
          end function, { compareValue: context[condition.attribute] })
        end if
      else if (getType(context[condition.attribute]) = "roString" AND getType(condition.value) = "roString")
        if (condition["operator"] = "equals")
          return context[condition.attribute] = condition.value
        else if (condition["operator"] = "notEquals")
          return context[condition.attribute] <> condition.value
        else if (condition["operator"] = "contains")
          return context[condition.attribute].instr(0, condition.value) <> -1
        else if (condition["operator"] = "notContains")
          return context[condition.attribute].instr(0, condition.value) = -1
        else if (condition["operator"] = "startsWith")
          return condition.value = context[condition.attribute].left(condition.value.len())
        else if (condition["operator"] = "endsWith")
          return condition.value = context[condition.attribute].right(condition.value.len())
        else if (condition["operator"] = "semverEquals")
          return compareVersions(context[condition.attribute], condition.value) = 0
        else if (condition["operator"] = "semverNotEquals")
          return compareVersions(context[condition.attribute], condition.value) <> 0
        else if (condition["operator"] = "semverGreaterThan")
          return compareVersions(context[condition.attribute], condition.value) = 1
        else if (condition["operator"] = "semverGreaterThanOrEquals")
          return compareVersions(context[condition.attribute], condition.value) >= 0
        else if (condition["operator"] = "semverLessThan")
          return compareVersions(context[condition.attribute], condition.value) = -1
        else if (condition["operator"] = "semverLessThanOrEquals")
          return compareVersions(context[condition.attribute], condition.value) <= 0
        end if
      else if (m._isNumber(context[condition.attribute]) AND m._isNumber(condition.value))
        if (condition["operator"] = "equals")
          return context[condition.attribute] = condition.value
        else if (condition["operator"] = "notEquals")
          return context[condition.attribute] <> condition.value
        else if (condition["operator"] = "greaterThan")
          return context[condition.attribute] > condition.value
        else if (condition["operator"] = "greaterThanOrEquals")
          return context[condition.attribute] >= condition.value
        else if (condition["operator"] = "lessThan")
          return context[condition.attribute] < condition.value
        else if (condition["operator"] = "lessThanOrEquals")
          return context[condition.attribute] <= condition.value
        end if
      else if (getType(context[condition.attribute]) = "roBoolean" AND getType(condition.value) = "roBoolean")
        if (condition["operator"] = "equals")
          return context[condition.attribute] = condition.value
        else if (condition["operator"] = "notEquals")
          return context[condition.attribute] <> condition.value
        end if
      else if (getType(context[condition.attribute]) = "roInvalid" AND getType(condition.value) = "roInvalid")
        if (condition["operator"] = "equals")
          return true
        else if (condition["operator"] = "notEquals")
          return false
        end if
      end if
    end if

    return false
  end function

  functionScope._isNumber = function (value as Dynamic) as Boolean
    valueType = getType(value)

    return valueType = "roInt" OR valueType = "LongInteger" OR valueType = "roFloat" OR valueType = "Double"
  end function

  functionScope._toDateTime = function (value as String) as Object
    dateTime = CreateObject("roDateTime")
    dateTime.fromISO8601String(value)

    return dateTime
  end function

  return functionScope._allConditionsAreMatched(condition, context)
end function
