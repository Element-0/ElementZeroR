{.push overflowChecks:off.}
proc symhash*(symbol: string): int64 =
  const fnv_prime = 1099511628211
  result = cast[int64](14695981039346656037u64)
  for ch in symbol:
    result = result * fnv_prime
    result = result xor int64(ch)
{.pop.}