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
    var ctx: FsDir
    if dir.startsWith('/'):
      ctx = s.fs.root
    else:
      ctx = s.fs.cwd
    
    let pathSplit = dir.split('/')

    for i, part in pathSplit:
      if part.len == 0: continue

      let isLast = i == pathSplit.high 
      var existing: FsNode = nil
      for child in ctx.children:
        if child.name == part:
          existing = child
          break
      
      if existing.isNil:
        if not isLast and not parsed.createParents:
          echo "mkdir: cannot create directory '", dir, "': No such file or directory"
          break
        
        let newDir = FsDir(name: part)
        ctx.addChild(newDir)
        ctx = newDir
      
        if parsed.verbose:
          echo "mkdir: created directory '", newDir.path, "'"
      
      elif existing of FsDir:
        if isLast and not parsed.createParents:
          echo "mkdir: cannot create directory '", dir, "': File exists"
          break
        ctx = FsDir(existing)
      
      else:
        echo "mkdir: cannot create directory '", dir, "': Not a directory"
        break