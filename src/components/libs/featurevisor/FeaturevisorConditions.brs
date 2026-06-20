' @import /components/ArrayUtils.brs from @dazn/kopytko-utils
' @import /components/getProperty.brs from @dazn/kopytko-utils
' @import /components/getType.brs from @dazn/kopytko-utils
' @import /components/libs/compareVersions.brs from compare-versions-roku

function featurevisorAllConditionsAreMatched(condition as Object, context as Object) as Boolean
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

    if (conditions.doesExist("attribute"))
      try
        return m._conditionIsMatched(conditions, context)
      catch _error
        return false
      end try
    end if

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

  functionScope._attributeExistsInContext = function (context as Object, path as String) as Boolean
    if (path.instr(0, ".") = -1) then return context.doesExist(path)

    parts = path.split(".")
    lastKey = parts.pop()
    parent = getProperty(context, parts)

    if (parent = Invalid OR getType(parent) <> "roAssociativeArray") then return false

    return parent.doesExist(lastKey)
  end function

  functionScope._conditionIsMatched = function (condition as Object, context as Object) as Boolean
    if (condition = Invalid) then return true
    if (condition.doesExist("operator") AND condition.doesExist("attribute") AND condition.doesExist("value"))
      attributeValue = getProperty(context, condition.attribute)

      if (condition["operator"] = "before" OR condition["operator"] = "after")
        if (getType(attributeValue) = "roString")
          dateInContext = m._toDateTime(attributeValue)
        else
          dateInContext = attributeValue
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
      else if (getType(condition.value) = "roArray" AND m._attributeExistsInContext(context, condition.attribute) AND (attributeValue = Invalid OR getType(attributeValue) = "roString" OR m._isNumber(attributeValue)))
        if (condition["operator"] = "in")
          return m._arrayUtils.contains(condition.value, function (item as String, context as Object) as Boolean
            return context.compareValue <> Invalid AND item.toStr() = context.compareValue.toStr()
          end function, { compareValue: attributeValue })
        else if (condition["operator"] = "notIn")
          return NOT m._arrayUtils.contains(condition.value, function (item as String, context as Object) as Boolean
            return context.compareValue <> Invalid AND item.toStr() = context.compareValue.toStr()
          end function, { compareValue: attributeValue })
        end if
      else if (getType(attributeValue) = "roArray")
        if (condition["operator"] = "includes")
          return m._arrayUtils.contains(attributeValue, function (item as Object, context as Object) as Boolean
            return item.toStr() = context.compareValue.toStr()
          end function, { compareValue: condition.value })
        else if (condition["operator"] = "notIncludes")
          return NOT m._arrayUtils.contains(attributeValue, function (item as Object, context as Object) as Boolean
            return item.toStr() = context.compareValue.toStr()
          end function, { compareValue: condition.value })
        end if
      else if (getType(attributeValue) = "roString" AND getType(condition.value) = "roString")
        if (condition["operator"] = "equals")
          return attributeValue = condition.value
        else if (condition["operator"] = "notEquals")
          return attributeValue <> condition.value
        else if (condition["operator"] = "contains")
          return attributeValue.instr(0, condition.value) <> -1
        else if (condition["operator"] = "notContains")
          return attributeValue.instr(0, condition.value) = -1
        else if (condition["operator"] = "startsWith")
          return condition.value = attributeValue.left(condition.value.len())
        else if (condition["operator"] = "endsWith")
          return condition.value = attributeValue.right(condition.value.len())
        else if (condition["operator"] = "semverEquals")
          return compareVersions(attributeValue, condition.value) = 0
        else if (condition["operator"] = "semverNotEquals")
          return compareVersions(attributeValue, condition.value) <> 0
        else if (condition["operator"] = "semverGreaterThan")
          return compareVersions(attributeValue, condition.value) = 1
        else if (condition["operator"] = "semverGreaterThanOrEquals")
          return compareVersions(attributeValue, condition.value) >= 0
        else if (condition["operator"] = "semverLessThan")
          return compareVersions(attributeValue, condition.value) = -1
        else if (condition["operator"] = "semverLessThanOrEquals")
          return compareVersions(attributeValue, condition.value) <= 0
        else if (condition["operator"] = "matches")
          flags = ""
          if (condition.doesExist("regexFlags") AND getType(condition.regexFlags) = "roString") then flags = condition.regexFlags
          regex = CreateObject("roRegex", condition.value, flags)

          return regex.isMatch(attributeValue)
        else if (condition["operator"] = "notMatches")
          flags = ""
          if (condition.doesExist("regexFlags") AND getType(condition.regexFlags) = "roString") then flags = condition.regexFlags
          regex = CreateObject("roRegex", condition.value, flags)

          return NOT regex.isMatch(attributeValue)
        end if
      else if (m._isNumber(attributeValue) AND m._isNumber(condition.value))
        if (condition["operator"] = "equals")
          return attributeValue = condition.value
        else if (condition["operator"] = "notEquals")
          return attributeValue <> condition.value
        else if (condition["operator"] = "greaterThan")
          return attributeValue > condition.value
        else if (condition["operator"] = "greaterThanOrEquals")
          return attributeValue >= condition.value
        else if (condition["operator"] = "lessThan")
          return attributeValue < condition.value
        else if (condition["operator"] = "lessThanOrEquals")
          return attributeValue <= condition.value
        end if
      else if (getType(attributeValue) = "roBoolean" AND getType(condition.value) = "roBoolean")
        if (condition["operator"] = "equals")
          return attributeValue = condition.value
        else if (condition["operator"] = "notEquals")
          return attributeValue <> condition.value
        end if
      else if (getType(attributeValue) = "roInvalid" AND getType(condition.value) = "roInvalid")
        if (condition["operator"] = "equals")
          return true
        else if (condition["operator"] = "notEquals")
          return false
        end if
      end if
    else if (condition.doesExist("operator") AND condition.doesExist("attribute"))
      attributeValue = getProperty(context, condition.attribute)

      if (condition["operator"] = "exists")
        return attributeValue <> Invalid
      else if (condition["operator"] = "notExists")
        return attributeValue = Invalid
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
