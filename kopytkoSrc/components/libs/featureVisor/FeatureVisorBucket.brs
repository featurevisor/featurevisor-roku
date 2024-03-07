' @import /components/libs/MurmurHash.brs from murmurhash-roku

function featureVisorGetBucketedNumber(bucketKey as String) as Integer
  HASH_SEED = 1
  MAX_BUCKETED_NUMBER = 100000 ' 100% * 1000 to include three decimal places in the same integer value
  MAX_HASH_VALUE& = &hFFFFFFFF&

  hashValue& = MurmurHash().v3(bucketKey, 1)
  ratio# = (hashValue& * 1.0) / (MAX_HASH_VALUE& * 1.0)

  return Int(ratio# * MAX_BUCKETED_NUMBER)
end function
