import std/[parseopt, os, strutils]

import fs

type
  Shell* = ref object
    user*: string
    fs*: ShellFs
    cmds*: seq[FsFile]
  
  MkdirCmdArgs* = object
    dirs*: seq[string]
    createParents*: bool = false
    verbose*: bool = false

proc cwd(s: Shell): string =
  s.fs.cwd.path

proc mkdirShell(s: Shell, args: seq[string] = @[]) =
  var parsed = MkdirCmdArgs()
  for kind, key, val in getopt(args):
    case kind
    of cmdEnd: break
    of cmdShortOption, cmdLongOption:
      if val == "":
        case key:
        of "p":
          parsed.createParents = true
        of "v":
          parsed.verbose = true
      else:
        discard
    of cmdArgument:
      if key == "mkdir": continue
      parsed.dirs.add key
  
  for dir in parsed.dirs:
    # if first c is `/` then create from root

    # else create from CWD
    let pathSplit = dir.split("/")


  echo parsed

when isMainModule:
  let root = FsDir(name: "/")
  var rootShell = Shell(
    user:"robert@renode", 
    fs: ShellFs(root:root, cwd:root)
  )
  let cmds = "mkdir -p a/b/c zz/top jj".parseCmdLine()
  rootShell.mkdirShell(cmds)
  echo rootShell.cwd