type
  AgletSubmodule* = ref object of RootObj ## \
    ## base aglet submodule, do not use directly
  Aglet* = ref object  ## aglet global state
    window*: AgletSubmodule ## \
      ## loaded submodules, do not use directly

proc initAglet*(): Aglet =
  new(result)
