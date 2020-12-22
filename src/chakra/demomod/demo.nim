import ../hookmc

proc initialize() {.hookmc: "?initialize@AppPlatform@@QEAAXXZ".} =
  quit "EXPECTED QUIT FOR TESTING"