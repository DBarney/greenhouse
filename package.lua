return {
  name = "dbarney/greenhouse",
  version = "0.0.1",
  homepage = "https://github.com/dbarney/greenhouse",
  description = "Small time series database for tracking greenhouse temps",
  author = { name = "Daniel Barney" },
  private = true,
  dependencies = {
    "luvit/require",
    "luvit/pretty-print",
    "creationix/weblit-app",
    "creationix/weblit-auto-headers",
    "luvit/json",
    "pagodabox/ffi-cache",
    "pagodabox/lmmdb",
    "luvit/tap@0.1.1"
  },
  files = {
    "**.lua",
    "**.so"
  }
}
