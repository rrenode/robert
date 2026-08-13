import std/strutils

type
  FsNode* = ref object of RootObj
    parent*: FsNode
    name*: string

  FsDir* = ref object of FsNode
    children*: seq[FsNode]
  
  ExecResult* = object
    output*: string
    exitCode*: int

  ExecProc* = proc(args: seq[string]): ExecResult

  FsFile* = ref object of FsNode
    content*: string
    executable*: bool = false
    execProc*: ExecProc
  
  ShellFs* = ref object
    root*: FsDir
    cwd*: FsDir

proc listChildren(d: FsDir): string =
  if d.children.len == 0: return "()"
  result = "("
  for c in d.children:
    result.add c.name
  result.add ")"

proc `$`*(o: FsNode): string =
  if o.isNil:
    return "<nil>"

  if o of FsFile:
    let f = FsFile(o)
    result = "(file: " & f.name &
      ", parent: " & $f.parent &
      ", content: " & f.content & ")"

  elif o of FsDir:
    let d = FsDir(o)
    if d.parent.isNil:
      result = "(dir: " & d.name & ", children: " & listChildren(d) & ")"
    else:
      result = "(dir: " & d.name &
        ", parent: " & $d.parent &
        ", children: " & listChildren(d) & ")"
        
  else:
    result = o.name

proc path*(n: FsNode): string =
  if n.parent.isNil: return "/"

  proc recurseParents(curNode: FsNode, cur: string): string =
    if curNode.parent.isNil: return cur
    if curNode.parent.name == "/": return "/" & cur
    let next = curNode.parent.name & "/" & cur
    recurseParents(curNode.parent, next)
  
  return recurseParents(n, n.name)

proc resolvePath*(fs: ShellFs, path: string): FsNode =
  if path.len == 0: return nil

  var current: FsNode

  if path.startsWith("/"):
    current = fs.root
  else:
    current = fs.cwd
  
  for part in path.split('/'):
    if part.len == 0 or part == ".": continue
    if part == "..":
      if not current.parent.isNil:
        current = current.parent
      continue
    if not (current of FsDir):
      return nil
    let dir = FsDir(current)

    var found: FsNode = nil
    for child in dir.children:
      if child.name == part:
        found = child
        break
    
    if found.isNil: return nil
    current = found

  return current

proc addChild*(dir: FsDir, child: FsNode) =
  if child notin dir.children:
    dir.children.add(child)
    child.parent = dir