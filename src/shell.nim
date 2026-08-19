## Shell Commands:
## ls          list files/directories
## cd          change directory
## pwd         print current directory
## mkdir       create directory
## rmdir       remove empty directory
## echo        print text
## clear/clr   clear terminal
## whoami      displays my personal about me
## help        list available commands

import std/[parseopt, os, strutils, tables]

import fs

type
  ShellOutputKind* = enum
    sokCommand, sokStdout, sokStderr, sokInfo

  ShellOutput* = object
    kind*: ShellOutputKind
    text*: string
    pwd*: string
  
  ShellCommandProc* = proc(s: Shell, args: seq[string])

  ShellCommand* = object
    name*: string
    toCall*: ShellCommandProc
    desc*: string

  Shell* = ref object
    user*: string
    fs*: ShellFs
    outputBuffer*: seq[ShellOutput]
    prevCmdsBuffer*: seq[ShellOutput]
    cmds: Table[string, ShellCommand]
    aliases: Table[string, string]
  
  MkdirCmdArgs* = object
    dirs*: seq[string]
    createParents*: bool = false
    verbose*: bool = false

proc cwd*(s: Shell): string =
  s.fs.cwd.path

proc cwdNode(s: Shell): FsDir =
  s.fs.cwd

proc echoShell(s: Shell, args: seq[string] = @[]) =
  s.outputBuffer.add ShellOutput(kind:sokInfo, text:args[1..^1].join(" "), pwd:s.cwd)

proc secho*(s: Shell, msg: string) =
  let cmd = msg.parseCmdLine()
  s.outputBuffer.add ShellOutput(kind:sokInfo, text:msg, pwd:s.cwd)

proc helpShell(s: Shell, args:seq[string] = @[]) =
  for c in s.cmds.values:
    s.secho c.name & " -> " & c.desc

proc clrShell(s: Shell, args: seq[string] = @[]) =
  s.outputBuffer = @[]

proc lsShell(s: Shell, args: seq[string] = @[]) =
  let children = listChildren(s.cwdNode)
  if children.len == 0: 
    s.secho "Seems empty..."
    return
  var final: string = ""
  for c in children:
    final.add "\n" & c
  s.secho final
  
proc cdShell(s: Shell, args: seq[string] = @[]) =
  let pathIdx = if args.len > 0 and args[0] == "cd": 1 else: 0
  if pathIdx >= args.len: return
  let path = args[pathIdx]
  var existing: FsNode = s.fs.resolvePath(path)
  if existing.isNil:
    s.secho "Cannot find path `" & args[0] & "` because it does not exist."
    return
  s.fs.cwd = existing.FsDir

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
          s.secho "mkdir: cannot create directory '" & dir & "': No such file or directory"
          break
        
        let newDir = FsDir(name: part)
        ctx.addChild(newDir)
        ctx = newDir
      
        if parsed.verbose:
          s.secho "mkdir: created directory '" & newDir.path & "'"
      
      elif existing of FsDir:
        if isLast and not parsed.createParents:
          s.secho "mkdir: cannot create directory '" & dir & "': File exists"
          break
        ctx = FsDir(existing)
      
      else:
        s.secho "mkdir: cannot create directory '" & dir & "': Not a directory"
        break

proc registerShellCommand*(s: Shell, cmd: string, call: ShellCommandProc, description: string = "") =
  if s.cmds.hasKey(cmd):
    echo "Command with name " & cmd & " already exists. Cannot re-register!"
    return
  if s.aliases.hasKey(cmd):
    echo "Alias with name " & cmd & " already exists. Cannot re-register!"
    return
  s.cmds[cmd] = ShellCommand(name:cmd, toCall:call, desc:description)
  echo "Registered shell command: " & cmd

proc registerShellAlias*(s: Shell, alias: string, cmd: string) =
  if s.cmds.hasKey(alias):
    echo "Command with name " & cmd & " already exists. Cannot re-register!"
    return
  if s.aliases.hasKey(alias):
    echo "Alias with name " & cmd & " already exists. Cannot re-register!"
    return
  s.aliases[alias] = cmd
  echo "Registered alias: `" & alias & "` to command: `" & cmd & "`"

proc dispatchCommandShell*(s: Shell, cmd: string) =
  let args = cmd.parseCmdLine()
  s.outputBuffer.add ShellOutput(kind:sokCommand, text:args.join(" "), pwd:s.cwd)
  s.prevCmdsBuffer.add ShellOutput(kind:sokCommand, text:args.join(" "), pwd:s.cwd)
  if not s.cmds.hasKey(args[0]):
    if s.aliases.hasKey(args[0]):
      s.dispatchCommandShell(s.aliases[args[0]] & args[1..^1].join(" "))
      return
    s.secho "The command " & args[0] & " is unknown..."
    return
  s.cmds[args[0]].toCall(s, args)

proc newShell*(user: string): Shell =
  let root = FsDir(name: "/")
  result = Shell(user:user, fs: ShellFs(root:root, cwd:root))
  result.registerShellCommand("mkdir", mkdirshell, "Create directory")
  result.registerShellCommand("echo", echoShell, "Print text")
  result.registerShellCommand("cd", cdShell, "Change directory")
  result.registerShellCommand("ls", lsShell, "List files/directories")
  result.registerShellCommand("clr", clrShell, "Clear terminal")
  result.registerShellAlias("clear", "clr")
  result.registerShellCommand("help", helpShell, "Shows this help")