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
  },
  files = {
    "**.lua",
    "!test*"
  }
}
