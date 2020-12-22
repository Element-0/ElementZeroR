import ../hookmc

proc initialize() {.hookmc: "?initialize@AppPlatform@@QEAAXXZ".} =
  echo "EXPECTED QUIT FOR TESTING"
  quit 0