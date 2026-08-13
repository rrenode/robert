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

method `$`(o: FsNode): string {.base.} =
  if o.isNil: return "<nil>"
  result = o.name

method `$`(o: FsFile): string =
  result = "(file: " & o.name &
    ", parent: " & $o.parent &
    ", content: " & o.content & ")"

method `$`(o: FsDir): string =
  if o.parent.isNil:
    result = "(dir: " & o.name & ", children: " & listChildren(o) & ")"
  else:
    result = "(dir: " & o.name & ", parent: " & $o.parent & ", children: " & listChildren(o) & ")"

proc path*(n: FsNode): string =
  if n.parent.isNil: return "/"

  proc recurseParents(curNode: FsNode, cur: string): string =
    if curNode.parent.isNil: return cur
    if curNode.parent.name == "/": return "/" & cur
    let next = curNode.parent.name & "/" & cur
    recurseParents(curNode.parent, next)
  
  return recurseParents(n, n.name)

proc addChild*(dir: FsDir, child: FsNode) =
  if child notin dir.children:
    dir.children.add(child)
    child.parent = dir