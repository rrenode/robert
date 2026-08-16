# begin Nimble config (version 2)
when withDir(thisDir(), system.fileExists("nimble.paths")):
  include "nimble.paths"
# end Nimble config

task build, "Builds app.js into site dir":
  exec """nim js -o:"site/app.js" src/rob.nim"""